{ upgrade, harvest, transfer,
  build, repairStructureUrgent, repairStructureNonUrgent,
  refillTower, shouldWork, moveTo } = require 'unit_actions'

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
    refillTower(unit) or repairStructureUrgent(unit) or build(unit) or repairStructureNonUrgent(unit)
  else
    source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
    harvest source, unit

module.exports = { harvester, upgrader, engineer }
