{ countBy, filter, merge, values } = require 'lodash'
{ memExists, readMem } = require 'memory'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'
{ upgrade, harvest, transfer, build,
  repair, maintain, refillTower, shouldWork,
  moveTo, resupply, collect, reserve,
  claim, invade, defend, patrol } = require 'unit_actions'

harvester = (unit) ->
  harvest unit

transporter = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    transfer unit
  else
    collect(unit)

upgrader = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    upgrade unit
  else
    resupply unit

engineer = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    refillTower(unit) or repair(unit) or build(unit) or maintain(unit)
  else
    resupply unit

reserver = (unit) ->
  reserve unit

claimer = (unit) ->
  claim unit

militant = (unit) ->
  # In order of priority, try find an activity to do and remember it for a while
  if unit.memory.actionttl <= 0
    unit.memory.actionttl = 25
    defending = filter(flags, (f) => f.color is flag_intents.DEFEND).length > 0
    unit.memory.defending = defending
    return if defending
    attacking = filter(flags, (f) => f.color is flag_intents.ATTACK).length > 0
    unit.memory.attacking = attacking
    return if attacking
    invading = filter(flags, (f) => f.color is flag_intents.INVADE).length > 0
    unit.memory.invading = invading
    return if attacking
    patrolling = filter(flags, (f) => f.color is flag_intents.PATROL).length > 0
    unit.memory.patrolling = patrolling

  if unit.memory.defending
    defend unit
  else if unit.memory.attacking
    attack unit
  else if unit.memory.invading
    invade unit
  else if unit.memory.patrolling
    patrol unit

  unit.memory.actionttl -= 1

module.exports = { harvester, upgrader, engineer, transporter, reserver, claimer, militant }
