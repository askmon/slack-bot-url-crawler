# Slack URL bot

This bot is based on: https://github.com/indigotech/tqt-bot/blob/master/README.md

Bot that will read URLs posted on Slack

## Configure

This bot runs using [node-foreman](https://github.com/strongloop/node-foreman), so to set up you local environment variables, create .env file with the following values

- `SLACK_TOKEN`: Token to be used to connect to Slack. Check https://my.slack.com/services/new/bot to create/get one.

_tip:_ You can use [`.env.example`](.env.example) file as a template for the config

## Running

- Tested only on node.js `v0.12.0`

- Execute:
```
$ npm install
$ npm start
```
