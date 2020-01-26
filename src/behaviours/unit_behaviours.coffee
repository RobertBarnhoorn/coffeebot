{ upgrade, harvest, transfer, build, repair, shouldWork, moveTo } = require 'unit_actions'

upgrader = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    upgrade unit
  else
    source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
    harvest source, unit

builder = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    build unit
  else
    source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
    harvest source, unit

harvester = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    transfer unit
  else
    source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
    harvest source, unit

repairer = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    repair unit
  else
    source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
    harvest source, unit

module.exports = { harvester, upgrader, builder, repairer }
