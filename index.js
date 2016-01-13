require('coffee-script/register');
require('rootpath')()

module.exports = require('src/bot')(function() {console.info('bot is ready!')})
