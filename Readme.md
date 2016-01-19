# Slack URL bot

This bot is based on: https://github.com/indigotech/tqt-bot/blob/master/README.md

Bot that will read URLs posted on Slack and add them to a [Swiftype](https://swiftype.com) engine

## Configure

This bot runs using [node-foreman](https://github.com/strongloop/node-foreman), so to set up you local environment variables, create .env file with the following values

- `SLACK_TOKEN`: Token to be used to connect to Slack. Check https://my.slack.com/services/new/bot to create/get one.
- `MONGOLAB_URI`: The MongoDB url. It will be used to store the filters
- `SWIFTYPE_TOKEN`: Swiftype API token that will be used to store/delete documents on Swiftype. (Check your )

_tip:_ You can use [`.env.example`](.env.example) file as a template for the config

## Running

- Tested only on node.js `v0.12.0`

- Execute:
```
$ npm install
$ npm start
```

## Need to know

- The bot will assume that your engine document structure will be like:

```javascript
{
  name: 'title'
  value: title
  type: 'string'
}
{
  name: 'description'
  value: description
  type: 'string'
}
{
  name: 'keywords'
  value: tags
  type: 'string'
}
{
  name: 'url'
  value: url
  type: 'string'
}
```

## Needs to be done

- Search engine and document name are currently hard coded, they should be environment variables
- Change engine name and document type to match your account

## Would be nice to do

- Refactor all the code
- Add URL information to Mongo database, like who posted it and date
  - Having all the info on Mongo, the bot can check if the URL was already posted
- Improve the help messages and bot commands
- Add proper tests

## Future

- Check [Amazon CloudSearch](https://aws.amazon.com/pt/cloudsearch/getting-started/) to replace Swiftype
- Create isolated modules so we can use on other bots projects
