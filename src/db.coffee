module.exports = (mongo, config) ->

  mongodb = mongo(config.mongoUri)

  addFilter = (url, callback) ->
    filterCol = mongodb.collection('filters')
    filterCol.update { }, { $addToSet: filters: url }, { multi: true }, ->
      callback()

  getFilter = (test, callback) ->
    filterCol = mongodb.collection('filters')
    filterCol.findOne {}, (err, filters) ->
      console.log filters
      callback err, filters

  get: getFilter,
  add: addFilter,
