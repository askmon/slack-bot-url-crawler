Slack   = require('slack-client')

# Config helpers
configHelper = require('tq1-helpers').config_helper

# DEPS
async   = require('async')
config  = require('../src/config')(configHelper)
childProcess = require('child_process')

# crawler
module_crawler = require './crawler'
crawler = module_crawler async, config, childProcess


module.exports = (callback) ->

  config.validate()

  token = config.slackToken
  autoReconnect = true
  autoMark = true

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

    # Respond to messages with the reverse of the text received.
    if type is 'message' and channel?

      channel.send "Ok, I am working ..."

      crawler.execute text, (err, result) ->
        if err
          channel.send "Error executing crawler command `$ #{text}`: ```#{err}```"
        else
          urls = ""
          for string in result
            if string.charAt(0) is 'h'
              urls = urls + "\n" + string
          response = "Added the following URLs to the super link system: \n" + urls
          console.log response
          channel.send response

  slack.on 'error', (error) ->
    console.error "Error: #{error}"


  slack.login()

  return callback()
