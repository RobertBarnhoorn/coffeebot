{ unitsMem, deleteUnitMem } = require 'memory'
{ unitExists } = require 'units'

clearDeadUnitMemory = ->
  deleteUnitMem u for u of unitsMem when not unitExists u

module.exports = { clearDeadUnitMemory }
