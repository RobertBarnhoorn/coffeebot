{ countBy, merge, values } = require 'lodash'
{ memExists, readMem } = require 'memory'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ upgrade, harvest, transfer,
  build, repairStructureUrgent, repairStructureNonUrgent,
  refillTower, shouldWork, moveTo,
  resupply, collect, invade } = require 'unit_actions'

harvester = (unit) ->
  harvest unit

transporter = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    transfer unit
  else if not collect(unit)
      transfer(unit)
      unit.memory.working = not unit.memory.working

upgrader = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    upgrade unit
  else
    resupply unit

engineer = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    refillTower(unit) or repairStructureUrgent(unit) or build(unit) or repairStructureNonUrgent(unit)
  else
    resupply unit

soldier = (unit) ->
  if unit.memory.attacking
    invade unit
  else
    actual = {}
    actual[v] = 0 for v in values roles
    merge actual, countBy(units, 'memory.role')
    if actual[roles.SOLDIER] >= 5
      unit.memory.attacking = true

module.exports = { harvester, upgrader, engineer, transporter, soldier }
