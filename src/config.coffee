module.exports = (configHelper) ->

  result =
    slackToken: process.env.SLACK_TOKEN # Add a bot at https://my.slack.com/services/new/bot and copy the token here.
    tqtPath: process.env.TQT_PATH || '/bin/local/tqt'

    validate: () ->
      configHelper.outputConfigValue result, "tqtPath", true
      configHelper.outputConfigValue result, "slackToken", if process.env.NODE_ENV is 'development' then true else false

  return result
