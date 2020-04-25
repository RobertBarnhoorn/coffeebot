{ garbageCollection } = require 'memory_management'
{ populationControl, failSafe } = require 'spawn_management'
{ flagManagement } = require 'flag_management'
{ unitManagement } = require 'unit_management'
{ towerManagement } = require 'tower_management'
{ cpuUsed, cpuBucket } = require 'cpu'
{ readMem, writeMem } = require 'memory'
{ emitMetrics } = require 'stats'

module.exports.loop = ->
  do garbageCollection
  do towerManagement
  do failSafe
  do flagManagement
  do populationControl
  do unitManagement
  do emitMetrics
