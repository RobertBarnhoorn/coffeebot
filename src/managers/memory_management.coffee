{ clearDeadUnitMemory } = require 'memory_actions'
{ cacheCostMatrices } = require 'paths'

garbageCollection = ->
  do clearDeadUnitMemory

module.exports = { garbageCollection }
