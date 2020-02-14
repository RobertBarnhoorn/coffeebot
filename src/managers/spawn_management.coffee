{ countBy, keys, merge, shuffle, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ spawns } = require 'spawns'
{ generateUnit } = require 'spawn_behaviours'

priorities = [roles.HARVESTER, roles.TRANSPORTER, roles.ENGINEER, roles.UPGRADER,
              roles.RESERVER, roles.CLAIMER, roles.SOLDIER, roles.SNIPER, roles.MEDIC]

desired = (role) ->
  switch role
    when roles.HARVESTER        then 4
    when roles.UPGRADER         then 2
    when roles.ENGINEER         then 4
    when roles.TRANSPORTER      then 4
    when roles.RESERVER
      if Game.flags['reserve']? then 1 else 0
    when roles.CLAIMER
      if Game.flags['claim']?   then 1 else 0
    when roles.SOLDIER
      if Game.flags['invade']?  then 3 else 0
    when roles.SNIPER
      if Game.flags['invade']?  then 3 else 0
    when roles.MEDIC
      if Game.flags['invade']?  then 3 else 0

populationControl = ->
  # Count the actual populations by role
  actual = {}
  actual[v] = 0 for v in values roles
  merge actual, countBy(units, 'memory.role')
  # Filter out roles that are at desired capacity
  candidates = []
  for role,count of actual
    if count < desired role
      candidates.push role
    else
      for _,unit of units
        if unit.memory.role == role and unit.ticksToLive < 25 and not unit.memory.replaced?
         candidates.push role
         unit.memory.replaced = true

  choice = undefined
  for role in priorities
    if role in candidates
      choice = role
      break

  if choice?
    for spawn in shuffle keys(spawns)
      if generateUnit(spawn, choice) == OK
        break


module.exports = { populationControl }
