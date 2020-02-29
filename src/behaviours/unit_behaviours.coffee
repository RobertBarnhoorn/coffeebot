{ countBy, filter, merge, values } = require 'lodash'
{ memExists, readMem } = require 'memory'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'
{ upgrade, harvest, transfer, build,
  repair, maintain, refillTower, shouldWork,
  moveTo, resupply, collect, reserve,
  claim, invade, defend } = require 'unit_actions'

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

soldier = (unit) ->
  if unit.memory.defending
    defend unit
  else if unit.memory.attacking
    invade unit
  else
    unit.memory.defending = filter(flags, (f) => f.color is flag_intents.DEFEND)?
    unit.memory.attacking = shouldInvade()

sniper = (unit) ->
  if unit.memory.defending
    defend unit
  else if unit.memory.attacking
    invade unit
  else
    unit.memory.defending = filter(flags, (f) => f.color is flag_intents.DEFEND)?
    unit.memory.attacking = shouldInvade()

medic = (unit) ->
  if unit.memory.defending
    defend unit
  else if unit.memory.attacking
    invade unit
  else
    unit.memory.defending = filter(flags, (f) => f.color is flag_intents.DEFEND)?
    unit.memory.attacking = shouldInvade()

shouldInvade =->
  actual = {}
  actual[v] = 0 for v in values roles
  merge actual, countBy(filter(units, (u) => not u.spawning), 'memory.role')
  actual[roles.MEDIC] >= 3 and actual[roles.SOLDIER] >= 2 and actual[roles.SNIPER] >= 2

module.exports = { harvester, upgrader, engineer, transporter, reserver, claimer, soldier, sniper, medic }
