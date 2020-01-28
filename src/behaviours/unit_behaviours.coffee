{ upgrade, harvest, transfer,
  build, repairStructureUrgent, repairStructureNonUrgent,
  refillTower, shouldWork, moveTo,
  collect } = require 'unit_actions'

harvester = (unit) ->
  harvest unit

transporter = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    transfer unit
  else
    collect unit

upgrader = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    upgrade unit
  else
    collect unit

engineer = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    refillTower(unit) or repairStructureUrgent(unit) or build(unit) or repairStructureNonUrgent(unit)
  else
    collect unit

module.exports = { harvester, upgrader, engineer, transporter }
