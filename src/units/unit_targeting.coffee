{ any, filter, map, sample, shuffle, values } = require 'lodash'
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
    structures.push(structuresFound...) if structuresFound?

  if structures.length
    closest = unit.pos.findClosestByPath structures
    if closest?
      return closest.id
    return (sample structures).id

  return (sample rooms).storage.id

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
  return (sample prioritized).id

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
  return (sample candidates).controller.id

harvestTarget = (unit) ->
  # See if there is an available container to sit on
  mines = []
  for room in shuffle values rooms
    mines.push filter(room.find(FIND_STRUCTURES),
                     (m) -> m.structureType is STRUCTURE_CONTAINER)
    availableMines = filter mines,
                            (m) -> not any (u.memory.target is m.id for u in values units)
    if availableMines.length
      return (sample availableMines).id

  # See if there is any other available energy source
  for room in shuffle values rooms
    sources = filter room.find(FIND_SOURCES),
                     (s) => not s.pos.inRangeTo(m, 1) for m in mines and \
                            not any (u.memory.target is s.id for u in values units)
    if sources.length
      return (sample sources).id

  # Replace the harvester that is closest to death
  expiringHarvester = minBy filter(units,
                                   (u) => u.memory.role is roles.HARVESTER and
                                          not any (u.memory.target is u.id for u in values units)),
                            'ticksToLive'
  if expiringHarvester?
    return expiringHarvester.id

  return undefined

defendTarget = (unit) ->
  targets = map filter(flags, (f) => f.color is flag_intents.DEFEND),
                (f) => f.name
  if targets.length
    # Go to the defensive flag which has fewest defensive units
    return minBy targets, ((t) -> (u for u in units when u.memory.target is t).length)
  return undefined

reserveTarget = (unit) ->
  targets = map filter(flags, (f) => f.color is flag_intents.RESERVE),
                (f) => f.name

  if targets.length
    return sample targets
  else
    expiringReserver = minBy filter units,
                                    (u) => u.memory.role is roles.RESERVER,
                             'ticksToLive'
    return expiringReserver.memory.target if expiringReserver?
  return undefined

repairTarget = (unit) ->
  structures = []
  for room in values rooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType isnt STRUCTURE_WALL and \
                                             ((s.hits < s.hitsMax and s.hits < 2000) or
                                              (s.structureType is STRUCTURE_CONTAINER and s.hits < 200000)) and \
                                              not any (u.memory.repairTarget is s.id for u in values units)
    structures.push(structuresFound...) if structuresFound?
  return undefined if not structures.length
  closest = unit.pos.findClosestByPath structures
  if closest?
    return closest.id
  return (sample structures).id

maintainTarget = (unit) ->
  structures = []
  for room in values rooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.hits < s.hitsMax and \
                                               not any(u.memory.maintainTarget is s.id for u in values units)
    structures.push(structuresFound...) if structuresFound?

  prioritized = structures.sort((a, b) => a.hits - b.hits) \
                          .slice(0, Math.ceil(Math.sqrt(structures.length)))

  return undefined if not prioritized.length
  closest = unit.pos.findClosestByPath prioritized
  if closest?
    return closest.id
  return (sample prioritized).id

buildTarget = (unit) ->
  sites = []
  for room in values rooms
    sitesFound = room.find FIND_MY_CONSTRUCTION_SITES,
                           filter: (s) => not any(u.memory.buildTarget is s.id for u in values units)
    sites.push(sitesFound...) if sitesFound?
  return undefined if not sites.length
  closest = unit.pos.findClosestByPath sites
  if closest?
    return closest.id
  return (sample sites).id

module.exports = { upgradeTarget, harvestTarget, reserveTarget, repairTarget,
                   maintainTarget, buildTarget, collectTarget, transferTarget,
                   defendTarget }
