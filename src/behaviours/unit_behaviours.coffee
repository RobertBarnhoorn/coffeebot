{ upgrade, harvest, transfer,
  build, repairStructureUrgent, repairStructureNonUrgent,
  refillTower, shouldWork, moveTo,
  resupply, collect } = require 'unit_actions'

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

module.exports = { harvester, upgrader, engineer, transporter }
