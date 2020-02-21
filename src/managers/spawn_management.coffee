{ countBy, filter, flatten, keys, merge, shuffle, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ spawns } = require 'spawns'
{ rooms } = require 'rooms'
{ generateUnit } = require 'spawn_behaviours'

priorities = [roles.HARVESTER, roles.TRANSPORTER, roles.ENGINEER, roles.UPGRADER,
              roles.RESERVER, roles.CLAIMER, roles.SOLDIER, roles.SNIPER, roles.MEDIC]

desired = (role) ->
  myRooms = filter(rooms, (r) => r.controller? and r.controller.my)
  numRooms = myRooms.length
  numSources = (flatten (s for s in r.find(FIND_SOURCES) for r in values rooms)).length
  switch role
    when roles.HARVESTER        then 1 * numSources
    when roles.UPGRADER         then 1 * numRooms
    when roles.ENGINEER         then 1 * numRooms
    when roles.TRANSPORTER      then 1 * numSources
    when roles.RESERVER
      if Game.flags['reserve']? then 1 else 0
    when roles.CLAIMER
      if Game.flags['claim']?   then 1 else 0
    when roles.SOLDIER
      if Game.flags['invade']?  then 2 else 0
    when roles.SNIPER
      if Game.flags['invade']?  then 2 else 0
    when roles.MEDIC
      if Game.flags['invade']?  then 4 else 0

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
