Slack   = require('slack-client')
htmltojson = require('html-to-json')
request = require('request')
swiftypeapi = require('swiftype')
mongojs = require('mongojs')
URI = require('urijs')

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

expression = /[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?/gi
regex = new RegExp(expression)

validate = (text) ->
  if text? and text.match(regex)
    urls = text.match(regex)
    console.log urls
    return urls
  else
    return undefined

removeFromSwiftype = (url, callback) ->
  console.log encodeURIComponent(url)
  swiftypeKey = config.swiftypeKey
  urldel = "https://api.swiftype.com/api/v1/engines/knowledgebase/document_types/links/documents/" + encodeURIComponent(url) + "?auth_token=" + swiftypeKey
  request.del urldel, (error, response, body) ->
    callback error


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
    # db.add "drive.google.com",(err, filters) ->
    #   console.log err
    #   console.log filters

    # messages = if unreads is 1 then 'message' else 'messages'
    #
    # console.log "You have #{unreads} unread #{messages}"


  slack.on 'message', (message) ->
    willadd = true
    channel = slack.getChannelGroupOrDMByID(message.channel)
    user = slack.getUserByID(message.user)
    response = ''

    userBotUser = "<@" + message._client.self.id + ">"
    allowedArgs = ['help', 'remove', 'filter']

    {type, ts, text} = message

    channelName = if channel?.is_channel then '#' else ''
    channelName = channelName + if channel then channel.name else 'UNKNOWN_CHANNEL'

    userName = if user?.name? then "@#{user.name}" else "UNKNOWN_USER"

    # console.log """
    #   Received: #{type} #{channelName} #{userName} #{ts} "#{text}"
    # """

    if type is 'message' and channel?

      callCommand = (text, callback) ->
        async.waterfall [
          async.apply(parseCmd, text)
          checkCmd
        ], callback

      parseCmd = (text, callback) ->
        return callback null, text.split(' ').slice(1).toString()

      checkCmd = (arg, callback) ->
        console.log arg.split(',')[0]
        option = allowedArgs.indexOf(arg.split(',')[0])
        if option == 0
          console.log 'help'
          return callback null, "BOT current supports the following arguments: `#{allowedArgs.join('`, `')}`\nUse filter to never add URLs from the domain of the URL\n Use remove to remove an url from the search base."
        else if option == 1
          console.log arg
          if arg.split(',')[1]?
            link = validate(arg.split(',')[1])
            if link and link[0]
              link = link[0]
            console.log link
          else
            return callback null, "I won't know what to remove if you don't tell me\nhttp://imgur.com/download/fWxYWhV/"
          if link?
            removeFromSwiftype link, (err) ->
              if not err?
                return callback null, 'Removed ' + link
              else
                return callback null, 'Could not remove ' + arg.split(',')
          else
            return callback null, 'This is not a valid URL, at least for me...: ' + arg.split(',')[1]
        #filter
        else if option == 2
          if arg.split(',')[1]?
            link = validate(arg.split(',')[1])
            if link and link[0]
              link = link[0]
              urii = new URI link
              link = urii.host()
            console.log link
          else
            return callback null, "I won't know what to filter if you don't tell me\nhttp://imgur.com/download/fWxYWhV/"
          if link?
            db.add link, (err) ->
              if not err?
                return callback null, 'Added filter for ' + link
              else
                return callback null, 'Could not remove ' + arg.split(',')
          else
            return callback null, 'This is not a valid URL, at least for me...: ' + arg.split(',')[1]
        else
          console.log arg
          return callback "Argument not allowed. BOT current only supports the following arguments: `#{allowedArgs.join('`, `')}`"

      if text?.indexOf(userBotUser) > -1
        willadd = false
        callCommand text, (err, result) ->
          if err
            channel.send err
          else
            channel.send result
      #channel.send "Ok, I am working ..."

      #OK, I know the code from now on is terrible, but it is relatively easy to make the modules if you have time
      if willadd
        crawler.execute text, (err, result) ->
          if err
            channel.send "Error executing crawler command `$ #{text}`: ```#{err}```"
          else
            urls = ""
            urlsArray = []
            db.get "test", (err, filters) ->
              console.log JSON.stringify filters.filters + "filt"
              for string in result
                if string.substring(0, 4) is "http"
                  uriii = new URI string
                  host = uriii.host()
                  if filters?.filters?
                    i = true
                    for f in filters.filters
                      if f is host
                        i = false
                      else
                        console.log "filtered"
                    if i
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
                      tagsS = tagsS + " " + channelName
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
                console.log "response"
                channel.send response

  slack.on 'error', (error) ->
    console.error "Error: #{error}"


  slack.login()

  return callback()
