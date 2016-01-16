# Config helpers
configHelper = require('tq1-helpers').config_helper

# DEPS
async   = require('async')
config  = require('../src/config')(configHelper)
cp      = require('child_process')

module_tqt = require '../src/tqt'

tqt = null;

# Chai
chai = require('chai')
assert = chai.assert


describe 'tqt module', () ->

  describe 'command validation', () ->

    before (done) ->

      tqt = module_tqt async, config,
        execFile: (path, args, cb) ->
          cb(null, null, null) # error, stdout, stderr
      done()

    after () ->
      tqt = null

    it 'should error if missing argument', (done) ->

      tqt.execute 'tqt', (err, result) ->
        assert.isTrue(!!err)
        assert.match err, /Missing arguments/
        done()

    it 'should error for invalid commands', (done) ->
      tqt.execute 'tqt invalid argument', (err, result) ->
        assert.isTrue(!!err)
        assert.match err, /not allowed/
        done()

    it 'should error if does not start with tqt', (done) ->
      tqt.execute 'github changelog', (err, result) ->
        assert.isTrue(!!err)
        assert.match err, /First argument/
        done()

    it 'should return ok for allowed commands', (done) ->
      tqt.execute 'tqt help', (err, result) ->
        assert.isFalse(!!err)
        done()

  describe 'command execution', () ->

    it 'should error if code execution fails on machine', (done) ->

      tqt = module_tqt async, config,
        execFile: (path, args, cb) ->
          cb('error on machine') # error, stdout, stderr

      tqt.execute 'tqt help', (err, result) ->
        assert.isTrue(!!err)
        assert.match err, /error on machine/
        done()

    it 'should return stdout from unix command execution if succeeded', (done) ->

      tqt = module_tqt async, config,
        execFile: (path, args, cb) ->
          cb(null, 'command success result', null) # error, stdout, stderr

      tqt.execute 'tqt help', (err, result) ->
        assert.isFalse(!!err)
        assert.match result, /command success result/
        done()
