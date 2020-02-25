{ any, filter, map, shuffle, values } = require 'lodash'
{ minBy } = require 'algorithms'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath } = require 'paths'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'

upgradeTarget = (unit) ->
  candidates = (room for room in values rooms \
                when room.controller? and room.controller.my and not room.controller.reservation?)
  for room in candidates
    closestUnit = undefined
    minCost = 100000
    controllerLocation = pos: room.controller.pos, range: 1
    for u in values(units) when u.memory.role is roles.UPGRADER
      cost = (getPath u.pos, controllerLocation).cost
      if cost < minCost
        minCost = cost
        closestUnit = u
    if unit is closestUnit
      return room.controller.id
  return (shuffle candidates)[0].controller.id

harvestTarget = (unit) ->
  mines = []
  sources = []
  for room in values rooms
    minesFound = room.find FIND_STRUCTURES,
                           filter: (s) => s.structureType is STRUCTURE_CONTAINER and \
                                          not any(s.pos.isEqualTo(u.pos) \
                                          for u in values(units) when u isnt unit)
    mines.push(minesFound...) if minesFound?

    sourcesFound = room.find FIND_SOURCES,
                             filter: (s) => not any(s.pos.inRangeTo(m.pos, 1) for m in minesFound)
    for s in sourcesFound
      miners = filter s.pos.findInRange(FIND_CREEPS, 1), (u) => u.memory.role is roles.HARVESTER
      if miners.length is 0 or (miners.length is 1 and unit in miners)
        sources.push s
  resources = mines.concat sources
  if resources.length
    return (shuffle resources)[0].id
  else
    expiringHarvester = minBy filter(units, (u) => u.memory.role is roles.HARVESTER and u.name isnt unit.name), 'ticksToLive'
    return expiringHarvester.id if expiringHarvester?
  return undefined

reserveTarget = (unit) ->
  targets = map filter(flags, (f) => f.color is flag_intents.RESERVE and
                                     not any (u.memory.target is f.name for u in values(units) when u isnt unit)),
                (f) => f.name

  if targets.length
    return targets[0]
  else
    expiringReserver = minBy filter(units, (u) => u.memory.role is roles.RESERVER and u.name isnt unit.name), 'ticksToLive'
    return expiringReserver.memory.target if expiringReserver?
  return undefined

module.exports = { upgradeTarget, harvestTarget, reserveTarget }
