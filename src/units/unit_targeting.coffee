{ any, filter, map, shuffle, values } = require 'lodash'
{ minBy } = require 'algorithms'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath } = require 'paths'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'

transferTarget = (unit) ->
  structures = []
  for room in values rooms
    structuresFound = room.find FIND_MY_STRUCTURES,
                                filter: (s) => s.energy < s.energyCapacity and \
                                                          s.structureType in [STRUCTURE_EXTENSION, STRUCTURE_SPAWN]
    if room.storage? and not structuresFound.length
      structuresFound =  (room.storage for room in rooms)
    structures.push(structuresFound...) if structuresFound?

  return undefined if not structures.length
  closest = unit.pos.findClosestByPath structures
  if closest?
    return closest.id
  return (shuffle structures)[0].id

collectTarget = (unit) ->
  resources = []
  for room in values rooms
    resourcesFound = room.find FIND_DROPPED_RESOURCES,
                               filter: (r) => r.resourceType is RESOURCE_ENERGY
    containersFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType is STRUCTURE_CONTAINER
    tombsFound = room.find FIND_TOMBSTONES,
                           filter: (t) => t.store[RESOURCE_ENERGY] > 0
    ruinsFound = room.find FIND_RUINS,
                           filter: (r) => r.store[RESOURCE_ENERGY] > 0
    resources.push(resourcesFound...) if resourcesFound?
    resources.push(containersFound...) if containersFound?
    resources.push(tombsFound...) if tombsFound?
    resources.push(ruinsFound...) if ruinsFound?

  prioritized = resources.sort((a, b) => (if b.amount? then b.amount else b.store[RESOURCE_ENERGY]) - \
                                         (if a.amount? then a.amount else a.store[RESOURCE_ENERGY])) \
                         .slice(0, Math.floor(Math.sqrt(resources.length)))

  return undefined if not prioritized.length
  closest = unit.pos.findClosestByPath prioritized
  if closest?
    return closest.id
  return (shuffle prioritized)[0].id

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

repairTarget = (unit) ->
  structures = []
  for room in values rooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType isnt STRUCTURE_WALL and \
                                             ((s.hits < s.hitsMax and s.hits < 2000) or
                                              (s.structureType is STRUCTURE_CONTAINER and s.hits < 200000)) and \
                                              not any(u.memory.repairTarget is s.id for u in values(units) when u isnt unit)
    structures.push(structuresFound...) if structuresFound?
  return undefined if not structures.length
  closest = unit.pos.findClosestByPath structures
  if closest?
    return closest.id
  return (shuffle structures)[0].id

maintainTarget = (unit) ->
  structures = []
  for room in values rooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.hits < s.hitsMax and \
                                               not any(u.memory.maintainTarget is s.id for u in values(units) when u isnt unit)
    structures.push(structuresFound...) if structuresFound?

  prioritized = structures.sort((a, b) => a.hits - b.hits) \
                          .slice(0, Math.ceil(Math.sqrt(structures.length)))

  return undefined if not prioritized.length
  closest = unit.pos.findClosestByPath prioritized
  if closest?
    return closest.id
  return (shuffle prioritized)[0].id

buildTarget = (unit) ->
  sites = []
  for room in values rooms
    sitesFound = room.find FIND_MY_CONSTRUCTION_SITES,
                           filter: (s) => not any(u.memory.buildTarget is s.id for u in values(units) when u isnt unit)
    sites.push(sitesFound...) if sitesFound?
  return undefined if not sites.length
  closest = unit.pos.findClosestByPath sites
  if closest?
    return closest.id
  return (shuffle sites)[0].id

module.exports = { upgradeTarget, harvestTarget, reserveTarget, repairTarget,
                   maintainTarget, buildTarget, collectTarget, transferTarget }
