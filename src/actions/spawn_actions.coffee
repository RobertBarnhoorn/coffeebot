{ readMem, writeMem } = require 'memory'
{ spawnUnit } = require 'spawns'
{ roles } = require 'unit_roles'

LAST_SPAWNED = 'lastSpawned'
SPAWN = 'Spawn1'

populationControl = ->
  candidate = switch readMem LAST_SPAWNED
                when roles.UPGRADER then roles.HARVESTER
                when roles.HARVESTER then roles.BUILDER
                when roles.BUILDER then roles.REPAIRER
                when roles.REPAIRER then roles.UPGRADER

  if spawnUnit(SPAWN, candidate) is OK then writeMem(LAST_SPAWNED, candidate)

module.exports = { populationControl }
