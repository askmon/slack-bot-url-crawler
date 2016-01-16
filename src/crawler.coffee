module.exports = (mongojs, config) ->

  URI = require 'urijs'

  expression = /[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?/gi
  regex = new RegExp(expression)

  validate = (text, callback) ->
    if text? and text.match(regex)
      urls = text.match(regex)
      console.log urls
      return callback(null,urls)
    else
      return callback(null,"Not an URL :(")

  executeCommand = (text, callback) ->
    validate(text,callback)

  execute: executeCommand,
