{ garbageCollection } = require 'memory_management'
{ populationControl, failSafe } = require 'spawn_management'
{ flagManagement } = require 'flag_management'
{ unitManagement } = require 'unit_management'
{ structureManagement } = require 'structure_management'
{ cpuUsed, cpuBucket } = require 'cpu'
{ readMem, writeMem } = require 'memory'
{ emitMetrics } = require 'stats'

module.exports.loop = ->
  do garbageCollection
  do structureManagement
  do failSafe
  do flagManagement
  do populationControl
  do unitManagement
  do emitMetrics
