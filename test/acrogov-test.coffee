chai = require 'chai'
sinon = require 'sinon'
expect = chai.expect
helper = require 'hubot-mock-adapter-helper'
TextMessage = require('hubot/src/message').TextMessage

chai.use require 'sinon-chai'

class Helper
  constructor: (@robot, @adapter, @user)->

  sendMessage: (done, message, callback)->
    if typeof done == 'string'
      callback = message or ->
      message = done
      done = ->
    @sendMessageHubot(@user, message, callback, done, 'send')

  replyMessage: (done, message, callback)->
    if typeof done == 'string'
      callback = message
      message = done
      done = ->
    @sendMessageHubot(@user, message, callback, done, 'reply')

  sendMessageHubot: (user, message, callback, done, event) ->
    @adapter.on event, (envelop, string) ->
      try
        callback(string)
        done()
      catch e
    @adapter.receive new TextMessage(user, message)

describe 'hubot-acrogov', ->
  {robot, user, adapter} = {}
  messageHelper = null
  noop = ->

  beforeEach (done)->
    helper.setupRobot (ret) ->
      process.setMaxListeners(0)
      {robot, user, adapter} = ret
      messageHelper = new Helper(robot, adapter, user)
      process.env.HUBOT_AUTH_ADMIN = user['id']
      messageHelper.robot.auth = isAdmin: ->
        return process.env.HUBOT_AUTH_ADMIN.split(',').indexOf(user['id']) > -1
      do done

  afterEach ->
    robot.shutdown()

  beforeEach ->
    require('../src/acrogov')(robot)

  describe 'adding a definition', ->
    it "stores a single definition", (done) ->
      messageHelper.sendMessage done, 'hubot define foo as bar', (result) ->
        expect(result[0]).to.equal('I added foo.')

    it "stores multiple definitions", (done) ->
      messageHelper.sendMessage 'hubot define foo as bar'
      messageHelper.sendMessage done, 'hubot define foo as baz', (result) ->
        expect(result[0]).to.equal('I added foo.')

    it "complains if you use a lot of 'as'es", (done) ->
      messageHelper.sendMessage done, 'hubot define foo as bar as pizza', (result) ->
        expect(result[0]).to.equal('Sorry, you can\'t use \'as\' more than once in a definition. The usage for adding a definition is \'define <acronym or phrase> as <new definition>')

  describe 'removing a definition', ->
    it "removes a word when there's only one definition", (done) ->
      messageHelper.sendMessage 'hubot define foo as bar'
      messageHelper.sendMessage done, 'hubot stop defining foo', (result) ->
        expect(result[0]).to.equal('I removed FOO.')

    it "removes a word when the only definition is mentioned", (done) ->
      messageHelper.sendMessage 'hubot define foo as bar'
      messageHelper.sendMessage done, 'hubot stop defining foo as bar', (result) ->
        expect(result[0]).to.equal('Deleted FOO, as \'bar\' was its only definition')

    it "removes a single definition of a word", (done) ->
      messageHelper.sendMessage 'hubot define foo as bar'
      messageHelper.sendMessage 'hubot define foo as baz'
      messageHelper.sendMessage done, 'hubot stop defining foo as bar', (result) ->
        expect(result[0]).to.equal('Deleted \'bar\' as a definition for FOO')

    it "removes all definitions of a word", (done) ->
      messageHelper.sendMessage 'hubot define foo as bar'
      messageHelper.sendMessage 'hubot define foo as baz'
      messageHelper.sendMessage done, 'hubot stop defining foo', (result) ->
        expect(result[0]).to.equal('I removed FOO.')

    it "doesn't remove unknown words", (done) ->
      messageHelper.sendMessage done, 'hubot stop defining foo', (result) ->
        expect(result[0]).to.equal('Sorry, couldn\'t find foo')

    it "doesn't remove unknown definitions", (done) ->
      messageHelper.sendMessage 'hubot define foo as bar'
      messageHelper.sendMessage done, 'hubot stop defining foo as pizza', (result) ->
        expect(result[0]).to.equal('Sorry, couldn\'t find \'pizza\' as a definition for FOO')
