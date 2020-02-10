{ countBy, merge, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ generateUnit } = require 'spawn_behaviours'

SPAWN = 'Spawn1'
priorities = [roles.HARVESTER, roles.TRANSPORTER, roles.ENGINEER, roles.UPGRADER,
              roles.CLAIMER, roles.SOLDIER, roles.MEDIC]

desired = (role) ->
  switch role
    when roles.HARVESTER then 2
    when roles.UPGRADER then 1
    when roles.ENGINEER then 2
    when roles.TRANSPORTER then 2
    when roles.CLAIMER
      if Game.flags['claim']? then 1 else 0
    when roles.SOLDIER
      if Game.flags['invade']? then 3 else 0
    when roles.MEDIC
      if Game.flags['invade']? then 3 else 0

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
        if unit.memory.role == role and unit.ticksToLive < 100 and not unit.memory.replaced?
         candidates.push role
         unit.memory.replaced = true

  choice = undefined
  for role in priorities
    if role in candidates
      choice = role
      break

  generateUnit(SPAWN, choice) if choice?

module.exports = { populationControl }
