{ upgrade, harvest, transfer, build, repair, refillTower, shouldWork, moveTo } = require 'unit_actions'

harvester = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    transfer unit
  else
    source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
    harvest source, unit

upgrader = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    upgrade unit
  else
    source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
    harvest source, unit

engineer = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    refillTower(unit) or build(unit) or repair(unit)
  else
    source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
    harvest source, unit

module.exports = { harvester, upgrader, engineer }
