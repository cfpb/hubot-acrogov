# Description:
#   checks an acronym against a set of acronyms used at CFPB and provides its meaning
#
# Dependencies:
#   json file "acro.json"
#   optional private json file "acro.priv.json"
#
# Commands:
#   hubot define <term> - returns an acronym's meaning if it's in our brain cache
#   hubot define <term> as <definition> - stores acronym definition in hubot's brain
#   hubot stop defining <term> - removes an acronym definition from hubot's brain
#     deletions of locally defined acronyms are permanent
#     deletions of acronyms defined in json files will be restored when the bot restarts
#
# Author:
#   higs4281

fs = require 'fs'

class AcroBot
  constructor: (@robot) ->
    @cache = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.acrogov
        @cache = @robot.brain.data.acrogov
        @loadAcronyms()
      else
        @loadAcronyms()
  loadPublicAcronyms: () ->
    # read the acro.json file
    acroPath = __dirname + '/json/acro.json'
    publicAcronyms = JSON.parse(fs.readFileSync(acroPath, 'utf8'))
    Object.assign @cache, publicAcronyms
  loadAcronyms: () ->
    # first try an optional private acro.json file
    acroPrivPath = __dirname + '/json/acro.priv.json'
    fs.access acroPrivPath, fs.F_OK, (err) =>
      if err
        @loadPublicAcronyms()
        console.log("loaded public acronyms")
      else
        privateAcronyms = JSON.parse(fs.readFileSync(acroPrivPath, 'utf8'))
        Object.assign @cache, privateAcronyms
        console.log("loaded private acronyms from" + acroPrivPath)
  addAcronym: (term, definition) ->
    @cache[term.toUpperCase()] = {
      name: definition
    }
    @robot.brain.data.acrogov = @cache
  removeAcronym: (term) ->
    delete @cache[term.toUpperCase()]
    @robot.brain.data.acrogov = @cache

  getAll: -> @cache
  buildAnswer: (term) ->
    terms = @cache
    acroObj = terms[term]
    answer = "#{term} stands for #{acroObj.name}"
    if acroObj.note
      answer = answer + " — " + acroObj.note
    if acroObj.link
      answer = answer + " – " + acroObj.link
    return answer

module.exports = (robot) ->
  acroBot = new AcroBot robot

  # either get an acronym from the brain or define a new one
  robot.respond /define (.*)$/i, (res) ->
    rawTerm = res.match[1]
    if rawTerm.split(' ')[1] == 'as'
      terms = rawTerm.split(' as ')
      term = terms[0].toUpperCase()
      if term of acroBot.getAll()
        res.send "Sorry, #{term} is already a defined acronym"
      else
        acroBot.addAcronym(terms[0], terms[1])
        res.send "I added #{terms[0]}."
    else
      term = rawTerm.toUpperCase()
      if term of acroBot.getAll()
        res.send acroBot.buildAnswer(term) 
      else
        res.send "Sorry, can't find #{rawTerm}"

  # delete an acronym from the brain
  robot.respond /stop defining (.*)$/i, (res) ->
    rawTerm = res.match[1]
    term = rawTerm.toUpperCase()
    if term of acroBot.getAll()
      acroBot.removeAcronym(res.match[1])
      res.send "I removed #{rawTerm}."
    else
      res.send "Sorry, couldn't find #{rawTerm}"
