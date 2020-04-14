{ any, filter, keys, map, random, sample, shuffle, values } = require 'lodash'
{ minBy } = require 'algorithms'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath, getClosest } = require 'paths'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'
{ MYSELF } = require 'constants'

transferTarget = (unit) ->
  # Prioritise transferring to either the nearest extension/spawn or the nearest storage, depending on how
  # energy-starved the spawning economy is. If we need energy for spawning it will be prioritized, otherwise
  # the energy may be put into storage for later use
  structures = []
  storage = []
  for room in values rooms
    if unit.store[RESOURCE_ENERGY] > 0
      structuresFound = room.find FIND_MY_STRUCTURES,
                                  filter: (s) -> s.structureType in [STRUCTURE_EXTENSION, STRUCTURE_SPAWN] and
                                                 s.store.getFreeCapacity(RESOURCE_ENERGY) > 0 and
                                                 s.id != unit.memory.target
      structures.push(structuresFound...) if structuresFound?
    storage.push(room.storage) if room.storage? and room.storage.store.getFreeCapacity()

  if not structures.length
    if not storage.length
      return undefined
    return getClosest(unit, storage).id

  normalisedDemand = structures.length / storage.length
  closestStructure = getClosest unit, structures
  closestStorage = getClosest unit, storage
  closestStructure.cost = 1 if closestStructure.cost == 0
  closestStorage.cost = 1 if closestStorage.cost == 0
  normalisedCost = closestStructure.cost / closestStorage.cost
  priority = normalisedDemand / normalisedCost
  # Arbitrary threshold chosen by trial-and-error
  if priority > 5
    return closestStructure.id
  else
    return closestStorage.id

collectTarget = (unit) ->
  resources = []
  for room in values rooms
    resourcesFound = room.find FIND_DROPPED_RESOURCES,
                               filter: (r) -> r.amount >= unit.store.getCapacity()
    containersFound = room.find FIND_STRUCTURES,
                                filter: (s) -> s.structureType is STRUCTURE_CONTAINER and
                                               s.store.getUsedCapacity >= unit.store.getCapacity()
    tombsFound = room.find FIND_TOMBSTONES,
                           filter: (t) -> t.store.getUsedCapacity() >= unit.store.getCapacity()
    ruinsFound = room.find FIND_RUINS,
                           filter: (r) -> r.store.getUsedCapacity() >= unit.store.getCapacity()
    resources.push(resourcesFound...) if resourcesFound?
    resources.push(containersFound...) if containersFound?
    resources.push(tombsFound...) if tombsFound?
    resources.push(ruinsFound...) if ruinsFound?

  uniques = filter resources, (r) -> not any (r.id is u.memory.target for u in values units)
  if uniques.length
    closest = getClosest(unit, uniques)
  else if resources.length
    closest = getClosest(unit, resources)
  return closest?.id

upgradeTarget = (unit) ->
  candidates = (r for r in values rooms \
                when r.controller? and r.controller.my and not r.controller.reservation?)
  return (sample candidates).controller.id

harvestTarget = (unit) ->
  sources = []
  for r in values rooms when r.controller?.my or r.controller?.reservation?.username is MYSELF
    sourcesFound = filter r.find(FIND_SOURCES),
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
                                filter: (s) => s.structureType not in [STRUCTURE_WALL, STRUCTURE_RAMPART] and
                                               (if s.my? then s.my else (s.structureType is STRUCTURE_ROAD)) and
                                               s.hits < s.hitsMax
    structures.push(structuresFound...) if structuresFound?
  if structures.length
    return getClosest(unit, structures).id
  return undefined

fortifyTarget = (unit) ->
  structures = []
  myRooms = filter values(rooms), ((r) -> r.controller?.my)
  for room in myRooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.hits < s.hitsMax and
                                               s.structureType in [STRUCTURE_WALL, STRUCTURE_RAMPART]
    structures.push(structuresFound...) if structuresFound?

  prioritized = structures.sort((a, b) => (a.hits - b.hits)) \
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
                   fortifyTarget, buildTarget, collectTarget, transferTarget,
                   flagTarget, claimTarget, resupplyTarget, refillTarget,
                   healTarget }
