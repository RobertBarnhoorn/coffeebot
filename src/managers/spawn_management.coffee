{ any, countBy, filter, flatten, includes, keys, map, merge, shuffle, some, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ spawns } = require 'spawns'
{ flags } = require 'flags'
{ flag_intents } = require 'flags'
{ rooms } = require 'rooms'
{ generateUnit } = require 'spawn_behaviours'

priorities = [roles.HARVESTER, roles.TRANSPORTER, roles.ENGINEER, roles.UPGRADER,
              roles.RESERVER, roles.CLAIMER, roles.SOLDIER, roles.SNIPER, roles.MEDIC]

desired = (role) ->
  numRooms = (filter(rooms, (r) => r.controller? and r.controller.my)).length
  numSources = (flatten (s for s in r.find(FIND_SOURCES) for r in values rooms)).length
  flagCount = countBy flags, 'color'

  switch role
    when roles.HARVESTER        then 1 * numSources
    when roles.UPGRADER         then 1 * numSources
    when roles.ENGINEER         then 1 * numRooms
    when roles.TRANSPORTER      then 1 * numSources
    when roles.RESERVER
      flagCount[flag_intents.RESERVE]
    when roles.CLAIMER
      flagCount[flag_intents.CLAIM]
    when roles.SOLDIER
      flagCount[flag_intents.ATTACK] * 2
    when roles.SNIPER
      flagCount[flag_intents.DEFEND] * 10 or \
      flagCount[flag_intents.ATTACK] * 2
    when roles.MEDIC
      flagCount[flag_intents.ATTACK] * 4

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
        if unit.memory.role == role and unit.ticksToLive < 50 and not unit.memory.replaced?
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

failSafe =->
  parts = [ATTACK, RANGED_ATTACK]
  for r in values rooms
    if (r.find FIND_HOSTILE_CREEPS,
               filter: (c) => c.owner.username isnt 'Invader' and
                              some(parts, (p) => includes(map(c.body, (b) => b.type), p))).length
      r.controller.activateSafeMode()

module.exports = { populationControl, failSafe }
