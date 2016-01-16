Slack   = require('slack-client')
htmltojson = require('html-to-json')
request = require('request')
swiftypeapi = require('swiftype')
mongojs = require('mongojs')

# Config helpers
configHelper = require('tq1-helpers').config_helper

# DEPS
async   = require('async')
config  = require('../src/config')(configHelper)
childProcess = require('child_process')

# crawler
module_crawler = require './crawler'
crawler = module_crawler async, config, childProcess

#db
module_db = require './db'
db = module_db mongojs, config

removeFromSwiftype = (url, channel, callback) ->
  console.log encodeURIComponent(url)
  swiftypeKey = config.swiftypeKey
  urldel = "https://api.swiftype.com/api/v1/engines/knowledgebase/document_types/links/documents/" + encodeURIComponent(url) + "?auth_token=" + swiftypeKey
  request.del urldel, (error, response, body) ->
    console.log error
  # swiftype = new swiftypeapi(apiKey: swiftypeKey)
  # swiftype.documents.create {
  #   engine: 'knowledgebase'
  #   documentType: 'links'
  #   document:
  #     external_id: url
  #   fields: [
  #     {
  #       name: 'title'
  #       value: 'titleS'
  #       type: 'string'
  #     }
  #     {
  #       name: 'description'
  #       value: 'descriptionS'
  #       type: 'string'
  #     }
  #     {
  #       name: 'keywords'
  #       value: 'tagsS'
  #       type: 'string'
  #     }
  #     {
  #       name: 'url'
  #       value: 'url'
  #       type: 'string'
  #     }
  #   ]
  # }, (err, res) ->


module.exports = (callback) ->

  config.validate()

  token = config.slackToken
  swiftypeKey = config.swiftypeKey
  autoReconnect = true
  autoMark = true

  console.log token

  slack = new Slack(token, autoReconnect, autoMark)

  slack.on 'open', ->
    channels = []
    groups = []
    unreads = slack.getUnreadCount()

    # Get all the channels that bot is a member of
    channels = ("##{channel.name}" for id, channel of slack.channels when channel.is_member)

    # Get all groups that are open and not archived
    groups = (group.name for id, group of slack.groups when group.is_open and not group.is_archived)

    console.log "Welcome to Slack. You are @#{slack.self.name} of #{slack.team.name}"
    console.log 'You are in: ' + channels.join(', ')
    console.log 'As well as: ' + groups.join(', ')
    console.log db
    removeFromSwiftype "http://globo.com", "lalala", (res) ->
    # db.add "drive.google.com",(err, filters) ->
    #   console.log err
    #   console.log filters

    # messages = if unreads is 1 then 'message' else 'messages'
    #
    # console.log "You have #{unreads} unread #{messages}"


  slack.on 'message', (message) ->
    channel = slack.getChannelGroupOrDMByID(message.channel)
    user = slack.getUserByID(message.user)
    response = ''

    {type, ts, text} = message

    channelName = if channel?.is_channel then '#' else ''
    channelName = channelName + if channel then channel.name else 'UNKNOWN_CHANNEL'

    userName = if user?.name? then "@#{user.name}" else "UNKNOWN_USER"

    # console.log """
    #   Received: #{type} #{channelName} #{userName} #{ts} "#{text}"
    # """

    if type is 'message' and channel?

      #channel.send "Ok, I am working ..."

      #OK, I know the code from now on is terrible, but it is relatively easy to make the modules if you have time
      crawler.execute text, (err, result) ->
        if err
          channel.send "Error executing crawler command `$ #{text}`: ```#{err}```"
        else
          urls = ""
          urlsArray = []
          for string in result
            if string.substring(0, 4) is "http"
              urls = urls + "\n" + string
              urlsArray.push string
          if urls isnt ""
            for url in urlsArray
              request url, (error, response, body) ->
                if error?
                  console.log error
                if !error and response.statusCode == 200
                  title = body.match(/<title.*>\n?(.*?)<\/title>/)
                  console.log JSON.stringify title
                  if title? and title[1]?
                    titleS = title[1]
                  else
                    titleS = "untitled"
                  description = body.match('<meta name=\"description\" content=\"(.*)\"')
                  if description? and description[1]?
                    descriptionS = description[1]
                    descriptionS = descriptionS.split("\"")[0]
                  else
                    descriptionS = ""
                  tags = body.match('<meta name=\"keywords\" content=\"(.*)\"')
                  if tags? and tags[1]?
                    tagsS = tags[1].replace(/,/g," ")
                    tagsS = tagsS.split("\"")[0]
                    tagsS = tagsS.split("/")[0]
                  if not tagsS?
                    tagsS = ""
                  console.log "going to send this to swiftype: " + url
                  console.log titleS
                  console.log descriptionS
                  console.log tagsS
                  swiftype = new swiftypeapi(apiKey: swiftypeKey)
                  swiftype.documents.create {
                    engine: 'knowledgebase'
                    documentType: 'links'
                    document:
                      external_id: url
                      fields: [
                        {
                          name: 'title'
                          value: titleS
                          type: 'string'
                        }
                        {
                          name: 'description'
                          value: descriptionS
                          type: 'string'
                        }
                        {
                          name: 'keywords'
                          value: tagsS
                          type: 'string'
                        }
                        {
                          name: 'url'
                          value: url
                          type: 'string'
                        }
                      ]
                  }, (err, res) ->
                    console.log res
            response = "Will add the following URLs to the super link system: \n" + urls
            console.log response
            channel.send response

  slack.on 'error', (error) ->
    console.error "Error: #{error}"


  slack.login()

  return callback()
