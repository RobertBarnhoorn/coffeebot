{ any, filter, keys, map, random, sample, shuffle, values } = require 'lodash'
{ minBy } = require 'algorithms'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath, getClosest } = require 'paths'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'
{ MYSELF } = require 'constants'

transferTarget = (unit, exclude=null) ->
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
                                                 s.id != exclude
      structures.push(structuresFound...) if structuresFound?

    if room.storage? and
       room.storage.store.getUsedCapacity() < room.storage.store.getCapacity() and
       room.storage.id != exclude
      storage.push(room.storage)

  if not structures.length
    if not storage.length
      return undefined
    closest = getClosest(unit, storage)
    if closest?
      return closest.id

  closestStructure = getClosest unit, structures
  closestStorage = getClosest unit, storage
  if not closestStructure?
    if not closestStorage?
      return undefined
    return closestStorage.id

  closestStructure.cost = 1 if closestStructure.cost == 0
  closestStorage.cost = 1 if closestStorage.cost == 0

  normalisedDemand = structures.length / storage.length
  normalisedCost = closestStructure.cost / closestStorage.cost
  priority = normalisedDemand / normalisedCost
  # Arbitrary threshold chosen by trial-and-error
  if priority > 5
    return closestStructure.id
  else
    return closestStorage.id

collectTarget = (unit) ->
  resources = []
  threshold = 0.7 * unit.store.getCapacity()
  for room in values rooms
    resourcesFound = room.find FIND_DROPPED_RESOURCES,
                               filter: (r) -> r.amount >= threshold
    containersFound = room.find FIND_STRUCTURES,
                                filter: (s) -> s.structureType is STRUCTURE_CONTAINER and
                                               s.store.getUsedCapacity() >= threshold
    tombsFound = room.find FIND_TOMBSTONES,
                           filter: (t) -> t.store.getUsedCapacity() >= threshold
    ruinsFound = room.find FIND_RUINS,
                           filter: (r) -> r.store.getUsedCapacity() >= threshold
    resources.push(resourcesFound...) if resourcesFound?
    resources.push(containersFound...) if containersFound?
    resources.push(tombsFound...) if tombsFound?
    resources.push(ruinsFound...) if ruinsFound?

  closest = getClosest unit, resources
  if closest?
    return closest.id
  return (sample resources).id

upgradeTarget = (unit) ->
  rooms = (r for r in values rooms when r.controller?.my and not r.controller.reservation?)
  controllers = map rooms, ((r) -> r.controller)
  numUpgraders = (c) -> (u for u in values units when u.memory.target is c.id ).length
  undersaturated = controllers.sort((c1, c2) -> (numUpgraders c1) - (numUpgraders c2)) \
                              .slice(0, Math.ceil(Math.sqrt(controllers.length)))
  closest = getClosest unit, undersaturated
  if closest?
    return closest.id
  return (sample undersaturated).controller.id

harvestTarget = (unit) ->
  sources = []
  for r in values rooms when r.controller?.my or r.controller?.reservation?.username is MYSELF
    sourcesFound = filter r.find(FIND_SOURCES),
                          (s) -> not any (s.id is u.memory.target for u in values units)
    sources.push(sourcesFound...) if sourcesFound?

  if not sources.length
    return undefined

  closest = getClosest(unit, sources)
  if closest?
    return closest.id
  return (sample sources).id

mineTarget = (unit) ->
  mines = []
  for r in values rooms when r.controller?.my
    minesFound = filter r.find(FIND_MINERALS),
                        ((m) -> m.amount > 0 and
                                (filter m.pos.findInRange(FIND_STRUCTURES, 0),
                                        ((s) -> s.structureType is STRUCTURE_EXTRACTOR)).length > 0 and
                                not any (m.id is u.memory.target for u in values units))
    mines.push(minesFound...) if minesFound?

  if not mines.length
    return undefined

  closest = getClosest(unit, mines)
  if closest?
    return closest.id
  return (sample mines).id

flagTarget = (unit, flag_intent, exclude=null) ->
  targets = filter flags, ((f) => f.color is flag_intent and f.name != exclude)

  if not targets.length
    return undefined

  closest = getClosest unit, targets
  if closest?
    return closest.name
  return (sample targets).name

reserveTarget = (unit) ->
  targets = filter flags, ((f) -> f.color is flag_intents.RESERVE and
                                  not any (f.name is u.memory.target for u in values units))

  if not targets.length
    return undefined

  closest = getClosest unit, targets
  if closest?
    return closest.name
  return (sample targets).name

claimTarget = (unit) ->
  targets = filter flags, ((f) -> f.color is flag_intents.CLAIM and
                                  not any (f.name is u.memory.target for u in values units))
  if not targets.length
    return undefined

  closest = getClosest unit, targets
  if closest?
    return closest.name
  return (sample targets).name

repairTarget = (unit) ->
  structures = []
  myRooms = filter values(rooms), ((r) -> r.controller?.my or r.controller?.reservation?.username is MYSELF)
  for room in myRooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) -> s.structureType not in [STRUCTURE_WALL, STRUCTURE_RAMPART] and
                                               (s.my or s.structureType in [STRUCTURE_ROAD, STRUCTURE_CONTAINER]) and
                                               s.hits < s.hitsMax
    structures.push(structuresFound...) if structuresFound?

  if not structures.length
    return undefined

  closest = getClosest(unit, structures)
  if closest?
    return closest.id
  return (sample structures).d

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

  if not prioritized.length
    return undefined

  closet = getClosest(unit, prioritized)
  if closest?
    return closest.id
  return (sample prioritized).id

buildTarget = (unit) ->
  structures = []
  sites = []
  myRooms = filter values(rooms), ((r) -> r.controller?.my or r.controller?.reservation?.username is MYSELF)
  for room in myRooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) -> s.hits < s.hitsMax and s.hits < 10000 and
                                               s.structureType in [STRUCTURE_WALL, STRUCTURE_RAMPART] and
                                               not any(s.id is u.memory.buildTarget for u in values units)

    structures.push(structuresFound...) if structuresFound?

    sitesFound = room.find FIND_MY_CONSTRUCTION_SITES,
                           filter: (s) -> not any(s.id is u.memory.buildTarget for u in values units)
    sites.push(sitesFound...) if sitesFound?

  if not structures.length
    if not sites.length
      return undefined
    closest = getClosest(unit, sites)
    if closest?
      return closest.id
    return (sample sites).id

  closest = getClosest(unit, structures)
  if closest?
    return closest.id
  return (sample structures).id

resupplyTarget = (unit) ->
  resources = []
  for room in values rooms
    droppedFound = room.find FIND_DROPPED_RESOURCES,
                             filter: (r) => r.amount >= unit.store.getCapacity(RESOURCE_ENERGY) and \
                                            r.resourceType is RESOURCE_ENERGY
    tombsFound = room.find FIND_TOMBSTONES,
                           filter: (t) => t.store[RESOURCE_ENERGY] > unit.store.getCapacity(RESOURCE_ENERGY)
    storesFound = room.find FIND_STRUCTURES,
                            filter: (s) -> (s.structureType is STRUCTURE_CONTAINER or
                                            s.structureType is STRUCTURE_STORAGE) and \
                                            s.store[RESOURCE_ENERGY] >= unit.store.getCapacity(RESOURCE_ENERGY)
    resources.push(droppedFound...) if droppedFound?
    resources.push(storesFound...) if storesFound?
    resources.push(tombsFound...) if tombsFound?

  if not resources.length
    return undefined

  closest = getClosest(unit, resources)
  if closest?
    return closest.id
  return (sample resources).id

refillTarget = (unit) ->
  towers = []
  for room in values rooms
    towersFound = room.find FIND_MY_STRUCTURES,
                            filter: (s) -> s.structureType is STRUCTURE_TOWER and \
                                           s.store[RESOURCE_ENERGY] < s.store.getCapacity(RESOURCE_ENERGY)
    towers.push(towersFound...) if towersFound?

  if not towers.length
    return undefined
  closest = getClosest(unit, towers)
  if closest?
    return closest.id
  return (sample towers).id

healTarget = (unit) ->
  targets = unit.room.find FIND_MY_CREEPS
  injured = filter targets, ((u) -> u.hits < u.hitsMax)
  if injured.length
    return injured.sort((a, b) => a.hits - b.hits)[0].id
  return undefined

module.exports = { upgradeTarget, harvestTarget, reserveTarget, repairTarget,
                   fortifyTarget, buildTarget, collectTarget, transferTarget,
                   flagTarget, claimTarget, resupplyTarget, refillTarget,
                   healTarget, mineTarget }
