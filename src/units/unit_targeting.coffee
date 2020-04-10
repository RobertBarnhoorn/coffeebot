{ any, filter, keys, map, sample, shuffle, values } = require 'lodash'
{ minBy } = require 'algorithms'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath, getClosest } = require 'paths'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'
{ MYSELF } = require 'constants'

transferTarget = (unit) ->
  structures = []
  storage = []
  for room in values rooms
    if unit.store[RESOURCE_ENERGY] > 0
      structuresFound = room.find FIND_MY_STRUCTURES,
                                  filter: (s) -> s.structureType in [STRUCTURE_EXTENSION, STRUCTURE_SPAWN] and
                                                 s.store.getFreeCapacity(RESOURCE_ENERGY) > 0 and
                                                 not any (s.id is u.memory.target for u in values units)
      structures.push(structuresFound...) if structuresFound?
    storage.push(room.storage) if room.storage?

  if structures.length
    return getClosest(unit, structures).id
  if storage.length
    return getClosest(unit, storage).id
  return undefined

collectTarget = (unit) ->
  resources = []
  for room in values rooms
    resourcesFound = room.find FIND_DROPPED_RESOURCES,
                               filter: (r) -> r.amount >= unit.store.getCapacity() and
                               not any (r.id is u.memory.target for u in values units)
    containersFound = room.find FIND_STRUCTURES,
                                filter: (s) -> s.structureType is STRUCTURE_CONTAINER and
                                               s.store.getUsedCapacity >= unit.store.getCapacity() and
                                               not any (s.id is u.memory.target for u in values units)
    tombsFound = room.find FIND_TOMBSTONES,
                           filter: (t) -> t.store.getUsedCapacity() >= unit.store.getCapacity() and
                                          not any (t.id is u.memory.target for u in values units)
    ruinsFound = room.find FIND_RUINS,
                           filter: (r) -> r.store.getUsedCapacity() >= unit.store.getCapacity() and
                                          not any (r.id is u.memory.target for u in values units)
    resources.push(resourcesFound...) if resourcesFound?
    resources.push(containersFound...) if containersFound?
    resources.push(tombsFound...) if tombsFound?
    resources.push(ruinsFound...) if ruinsFound?


  uniques = filter resources, (r) -> not any (r.id is u.memory.target for u in values units)
  if uniques.length
    closest = getClosest(unit, uniques)
  else if resources.length
    closest = getClosest(unit, resources)
  return if closest? then closest.id else undefined

upgradeTarget = (unit) ->
  candidates = (room for room in values rooms \
                when room.controller? and room.controller.my and not room.controller.reservation?)
  return (sample candidates).controller.id

harvestTarget = (unit) ->
  sources = []
  for room in values rooms
    sourcesFound = filter room.find(FIND_SOURCES),
                          (s) -> not any (s.id == u.memory.target for u in values units)
    sources.push(sourcesFound...) if sourcesFound?

  if sources.length
    closest = getClosest(unit, sources)
    return closest.id if closest?
  return undefined

flagTarget = (unit, flag_intent) ->
  targets = map(filter(flags, (f) => f.color is flag_intent),
               (f) => f.name)
  if targets.length
    return sample targets
  return undefined

reserveTarget = (unit) ->
  targets = map(filter(flags, ((f) -> f.color is flag_intents.RESERVE and
                                      not any (f.name is u.memory.target for u in values units))),
               (f) => f.name)

  if targets.length
    return sample targets
  return undefined

claimTarget = (unit) ->
  targets = map(filter(flags, ((f) -> f.color is flag_intents.CLAIM and
                                     not any (f.name is u.memory.target for u in values units))),
               (f) => f.name)
  if targets.length
    return sample targets
  return undefined

repairTarget = (unit) ->
  structures = []
  myRooms = filter values(rooms), ((r) -> r.controller?.my or r.controller?.reservation?.username is MYSELF)
  for room in myRooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType isnt STRUCTURE_WALL and \
                                               (if s.my? then s.my else (s.structureType in [STRUCTURE_ROAD, STRUCTURE_CONTAINER])) and \
                                               ((s.hits < s.hitsMax and s.hits <= 2000) or
                                               (s.structureType is STRUCTURE_CONTAINER and s.hits < 100000) or
                                               (s.structureType is STRUCTURE_RAMPART and s.hits < 50000)) and \
                                               not any (u.memory.repairTarget is s.id for u in values units)
    structures.push(structuresFound...) if structuresFound?
  if structures.length
    return getClosest(unit, structures).id
  return undefined

maintainTarget = (unit) ->
  structures = []
  myRooms = filter values(rooms), ((r) -> r.controller?.my or r.controller?.reservation?.username is MYSELF)
  for room in myRooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.hits < s.hitsMax and
                                               not any (s.id is u.memory.maintainTarget for u in values units)
    structures.push(structuresFound...) if structuresFound?

  prioritized = structures.sort((a, b) => (a.hitsMax - a.hits) - (b.hitsMax - b.hits)) \
                          .slice(0, Math.ceil(Math.sqrt(structures.length)))

  if prioritized.length
    return getClosest(unit, prioritized).id
  return undefined

buildTarget = (unit) ->
  sites = []
  myRooms = filter values(rooms), ((r) -> r.controller?.my or r.controller?.reservation?.username is MYSELF)
  for room in myRooms
    sitesFound = room.find FIND_MY_CONSTRUCTION_SITES,
                           filter: (s) => not any(s.id is u.memory.buildTarget for u in values units)
    sites.push(sitesFound...) if sitesFound?
  if sites.length
    return getClosest(unit, sites).id
  return undefined

resupplyTarget = (unit) ->
  resources = []
  for room in values rooms
    droppedFound = room.find FIND_DROPPED_RESOURCES,
                             filter: (r) => r.amount >= unit.store.getCapacity(RESOURCE_ENERGY) and \
                                            r.resourceType is RESOURCE_ENERGY
    tombsFound = room.find FIND_TOMBSTONES,
                           filter: (t) => t.store[RESOURCE_ENERGY] > unit.store.getCapacity(RESOURCE_ENERGY)
    storesFound = room.find FIND_STRUCTURES,
                            filter: (s) => (s.structureType is STRUCTURE_CONTAINER or
                                            s.structureType is STRUCTURE_STORAGE) and \
                                            s.store[RESOURCE_ENERGY] >= unit.store.getCapacity(RESOURCE_ENERGY)
    resources.push(droppedFound...) if droppedFound?
    resources.push(storesFound...) if storesFound?
    resources.push(tombsFound...) if tombsFound?

  if resources.length
    closest = getClosest(unit, resources)
  return if closest? then closest.id else undefined

refillTarget = (unit) ->
  towers = []
  for room in values rooms
    towersFound = room.find FIND_MY_STRUCTURES,
                            filter: (s) => s.structureType is STRUCTURE_TOWER and \
                                           s.store[RESOURCE_ENERGY] < s.store.getCapacity(RESOURCE_ENERGY)
    towers.push(towersFound...) if towersFound?

  if towers.length
    return getClosest(unit, towers).id
  return undefined

healTarget = (unit) ->
  targets = unit.room.find FIND_MY_CREEPS
  injured = filter targets, ((u) -> u.hits < u.hitsMax)
  if injured.length
    return injured.sort((a, b) => a.hits - b.hits)[0].id
  return undefined

module.exports = { upgradeTarget, harvestTarget, reserveTarget, repairTarget,
                   maintainTarget, buildTarget, collectTarget, transferTarget,
                   flagTarget, claimTarget, resupplyTarget, refillTarget,
                   healTarget }
