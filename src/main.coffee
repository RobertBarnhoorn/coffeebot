{ garbageCollection } = require 'memory_management'
{ populationControl, failSafe } = require 'spawn_management'
{ unitManagement } = require 'unit_management'
{ towerManagement } = require 'tower_management'
{ cpuUsed, cpuBucket } = require 'cpu'
{ readMem, writeMem } = require 'memory'

module.exports.loop = ->
  # console.log cpuBucket
  do garbageCollection
  do towerManagement
  do failSafe
  do populationControl
  do unitManagement
