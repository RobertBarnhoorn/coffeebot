{ unitsMem, deleteUnitMem } = require 'memory'
{ unitExists } = require 'units'

garbageCollection = ->
  do clearDeadUnitMemory

clearDeadUnitMemory = ->
  deleteUnitMem u for u of unitsMem when not unitExists u

module.exports = { garbageCollection }
