# Description:
#   Checks an acronym against a set of acronyms used at CFPB and provides its meaning
#
# Commands:
#   hubot define <term> - returns the definition of the term
#   hubot define <term> as <definition> - save the definition of a term
#   hubot stop defining <term> - removes a term and all of its definitions
#   hubot stop defining <term> as <definition> - removes the specified definition of the term
#
# Notes:
#   - Definitions found in "src/json/acro.json" are loaded at start-up.
#   - Definitions with sensitive information can be stored in "src/json/acro.priv.json".
#   - If a term is already defined, the new definition will be added.
#   - Definition deletions are permanent unless they're in.
#   - Deletions of acronyms defined in json files will be restored when the bot restarts.
#
# Author:
#   higs4281

fs = require 'fs'

class AcroBot
  constructor: (@robot) ->
    @cache = {}
    @private = {}
    @loadAcronyms()
  loadPublicAcronyms: () ->
    # read the acro.json file
    acroPath = __dirname + '/json/acro.json'
    publicAcronyms = JSON.parse(fs.readFileSync(acroPath, 'utf8'))
    @cache = publicAcronyms
  loadAcronyms: () ->
    # first try an optional private acro.priv.json file
    acroPrivPath = __dirname + '/json/acro.priv.json'
    fs.access acroPrivPath, fs.F_OK, (err) =>
      if err
        @loadPublicAcronyms()
      else
        @private = JSON.parse(fs.readFileSync(acroPrivPath, 'utf8'))
        Object.assign @cache, @private
        @loadBrainAcronyms()
  loadBrainAcronyms: () ->
    # add brain acronyms to the party
    brainAcronyms = @robot.brain.get 'data.acrogov'
    Object.assign @cache, brainAcronyms
  addAcronym: (term, definition) ->
    @cache[term.toUpperCase()] = {
      name: definition
    }
    @robot.brain.set 'data.acrogov', @cache
  appendAcronym: (term, definition) ->
    oldTerm = @cache[term.toUpperCase()].name
    @cache[term.toUpperCase()] = {
      name: oldTerm + ' OR ' + definition
    }
    @robot.brain.set 'data.acrogov', @cache
  removeAcronym: (term) ->
    delete @cache[term.toUpperCase()]
    @robot.brain.set 'data.acrogov', @cache
  removeAcronymDefinition: (term, definition) ->
    terms = @cache[term].name.split(' OR ')
    index = terms.indexOf(definition)
    terms.splice(index, 1)
    @cache[term].name = terms.join(' OR ')
    @robot.brain.set 'data.acrogov', @cache
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
    definerTokens = rawTerm.split(' as ')
    if definerTokens.length > 2
      res.send "Sorry, you can't use 'as' more than once in a definition. The usage for adding a definition is 'define <acronym or phrase> as <new definition>"
    else if definerTokens.length == 1
      term = rawTerm.toUpperCase()
      if term of acroBot.getAll()
        res.send acroBot.buildAnswer(term)
      else
        res.send "Sorry, can't find #{rawTerm}"
    else if definerTokens.length == 2
      term = definerTokens[0].toUpperCase()
      if term of acroBot.getAll()
        brainTokens = acroBot.getAll()[term].name.split(' OR ')
        if definerTokens[1] in brainTokens
          res.send "Sorry, #{definerTokens[1]} is already a definition for #{term}"
        else
          acroBot.appendAcronym(definerTokens[0], definerTokens[1])
          res.send "Added #{definerTokens[1]} as a definition for #{term}"
      else
        acroBot.addAcronym(definerTokens[0], definerTokens[1])
        res.send "I added #{definerTokens[0]}."

  # delete an acronym from the brain or, if there are multiple definitions, deletes the one specified
  robot.respond /stop defining (.*)$/i, (res) ->
    rawTerm = res.match[1]
    definerTokens = rawTerm.split(' as ')
    if definerTokens.length > 2
        res.send "Sorry, you can't use keyword 'as' more than once in a definition. The usage for deleting a single definition is 'stop defining <acronym or phrase> as <new definition>"
    else if definerTokens.length == 1
      term = rawTerm.toUpperCase()
      if term of acroBot.getAll()
        acroBot.removeAcronym(res.match[1])
        if term of acroBot.private
          res.send "I removed #{term}, but since it's in our master list, it will return with the next restart."
        else
          res.send "I removed #{term}."
      else
        res.send "Sorry, couldn't find #{rawTerm}"
    else if definerTokens.length == 2
      term = definerTokens[0].toUpperCase()
      if term of acroBot.getAll()
        brainTokens = acroBot.getAll()[term].name.split(' OR ')
        if brainTokens.indexOf(definerTokens[1]) >= 0
          if brainTokens.length == 1
            acroBot.removeAcronym(term)
            res.send "Deleted #{term}, as '#{definerTokens[1]}' was its only definition"
          else
            acroBot.removeAcronymDefinition(term, definerTokens[1])
            res.send "Deleted '#{definerTokens[1]}' as a definition for #{term}"
        else
          res.send "Sorry, couldn't find '#{definerTokens[1]}' as a definition for #{term}"
      else
        res.send "Sorry, couldn't find #{term}"
