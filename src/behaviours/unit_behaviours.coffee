{ countBy, filter, merge, sample, values } = require 'lodash'
{ memExists, readMem } = require 'memory'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'
{ upgrade, harvest, transfer, build,
  repair, fortify, refillTower, shouldWork,
  moveTo, resupply, collect, reserve,
  claim, invade, defend, patrol,
  attack }= require 'unit_actions'

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
    resupply unit

repairer = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    refillTower(unit) or repair(unit) or fortify(unit)
  else
    resupply unit

fortifier = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    fortify unit
  else
    resupply unit

builder = (unit) ->
  unit.memory.working = shouldWork unit
  if unit.memory.working
    refillTower(unit) or build(unit) or repair(unit) or fortify(unit)
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
    unit.memory.target = undefined
    potentialActions = []
    if filter(flags, (f) => f.color is flag_intents.DEFEND).length > 0
      potentialActions.push 'defending'
    if filter(flags, (f) => f.color is flag_intents.ATTACK).length > 0
      potentialActions.push 'attacking'
    if filter(flags, (f) => f.color is flag_intents.INVADE).length > 0
      potentialActions.push 'invading'

    if potentialActions.length
      if unit.memory.action not in potentialActions
        # We no longer have a directive for our previous action, so choose another
        unit.memory.action = sample potentialActions
    else
      unit.memory.action = 'patrolling'

  switch unit.memory.action
    when 'defending'  then defend unit
    when 'attacking'  then attack unit
    when 'invading'   then invade unit
    when 'patrolling' then patrol unit

  unit.memory.actionttl -= 1

module.exports = { harvester, upgrader, repairer, builder, fortifier, transporter, reserver, claimer, militant }
