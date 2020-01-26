{ clearDeadUnitMemory } = require 'memory_actions'

garbageCollection = ->
  do clearDeadUnitMemory

module.exports = { garbageCollection }
