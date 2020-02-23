{ garbageCollection } = require 'memory_management'
{ populationControl, failSafe } = require 'spawn_management'
{ unitManagement } = require 'unit_management'
{ towerManagement } = require 'tower_management'
{ cpuBucket } = require 'cpu'

module.exports.loop = ->
# console.log cpuBucket
  do garbageCollection
  do populationControl
  do unitManagement
  do towerManagement
  do failSafe
