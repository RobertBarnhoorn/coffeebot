{ any, filter, flatten, forEach, keys, map, random, sample, shuffle, slice, sortBy, sum, values } = require 'lodash'
{ minBy } = require 'algorithms'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath, getClosest } = require 'paths'
{ units } = require 'units'
{ flags, flag_intents } = require 'flags'
{ MYSELF } = require 'constants'

myRooms = filter rooms, (r) -> r.controller?.my or r.controller?.reservation?.username is MYSELF

myControlledRooms = filter rooms, (r) -> r.controller?.my

myStructures = flatten map rooms, (r) -> r.find(FIND_MY_STRUCTURES)

energyStructures = filter myStructures, (s) -> s.structureType in [STRUCTURE_EXTENSION, STRUCTURE_SPAWN]

storage = filter myStructures, (s) -> s.structureType is STRUCTURE_STORAGE

links = filter myStructures, (s) -> s.structureType is STRUCTURE_LINK

mines = filter flatten(map(myControlledRooms, ((r) -> r.find(FIND_MINERALS)))),
               (m) -> m.mineralAmount > 0 and (filter m.pos.findInRange(FIND_STRUCTURES, 0),
                                                      ((s) -> s.structureType is STRUCTURE_EXTRACTOR)).length > 0

damagedStructures = filter flatten(map(myRooms, ((r) -> r.find FIND_STRUCTURES))),
                           (s) -> (s.hits < s.hitsMax and
                                   s.structureType not in [STRUCTURE_WALL, STRUCTURE_RAMPART] and
                                  (s.my or s.structureType in [STRUCTURE_ROAD, STRUCTURE_CONTAINER])) or
                                  (s.hits < 5000 and s.structureType is STRUCTURE_RAMPART)
  
constructionSites = flatten map myRooms, (r) -> r.find FIND_MY_CONSTRUCTION_SITES

damagedDefences = filter flatten(map(myControlledRooms, ((r) -> r.find FIND_STRUCTURES))),
                         (s) -> s.hits < s.hitsMax and
                                s.structureType in [STRUCTURE_WALL, STRUCTURE_RAMPART]

lowestDefences = damagedDefences.sort((a, b) -> (a.hits - b.hits)).slice(0, Math.ceil(Math.sqrt(damagedDefences.length)))

resources = flatten map rooms, (r) -> r.find(FIND_DROPPED_RESOURCES)

tombs = flatten map myRooms, (r) -> r.find FIND_TOMBSTONES

ruins = flatten map myRooms, (r) -> r.find FIND_RUINS

containers = filter flatten(map(myRooms, ((r) -> r.find(FIND_STRUCTURES)))),
                    (s) -> s.structureType is STRUCTURE_CONTAINER

nonFullTowers = filter myStructures, (s) -> s.structureType is STRUCTURE_TOWER and
                                            s.store[RESOURCE_ENERGY] < s.store.getCapacity(RESOURCE_ENERGY)

collectables = [resources..., tombs..., ruins..., containers..., links...]

resupplyPoints = [collectables..., storage...]

transferTarget = (unit) ->
  # Prioritise transferring to either the nearest extension/spawn or the nearest storage, depending on how
  # energy-starved the spawning economy is. If we need energy for spawning it will be prioritized, otherwise
  # the energy may be put into storage for later use
  candidateStructures = []

  if unit.store[RESOURCE_ENERGY] > 0
    candidateStructures = filter energyStructures, (s) -> s.store.getFreeCapacity(RESOURCE_ENERGY) > 0

  candidateStorage = filter storage, (s) -> s.store.getUsedCapacity() < s.store.getCapacity()
  candidateLinks = links

  candidates = [candidateStructures..., candidateStorage..., candidateLinks...]

  if not candidates.length
    return undefined

  closest = getClosest unit, candidates
  if closest?
    return closest.id
  return (sample candidates).id

collectTarget = (unit) ->
  collectAmount = unit.store.getCapacity() - unit.store.getUsedCapacity()
  candidates = filter collectables, (c) -> (if c.amount? then c.amount > collectAmount \
                                            else c.store.getUsedCapacity() > collectAmount)

  if not candidates.length
    return undefined

  closest = getClosest unit, candidates
  if closest?
    return closest.id
  return (sample candidates).id

upgradeTarget = (unit) ->
  controllers = map myControlledRooms, (r) -> r.controller
  numUpgraders = (c) -> (u for u in values(units) when u.memory.target is c.id).length
  undersaturated = controllers.sort((c1, c2) -> (numUpgraders c1) - (numUpgraders c2)) \
                              .slice(0, Math.ceil(Math.sqrt(controllers.length)))

  if not undersaturated.length
    return undefined

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
  candidates = filter mines, (m) -> not any (m.id is u.memory.target for u in values(units) when u.memory.role is roles.MINER)

  if not candidates.length
    return undefined

  closest = getClosest(unit, candidates)
  if closest?
    return closest.id
  return (sample candidates).id

flagTarget = (unit, flag_intent, exclude=null) ->
  targets = filter flags, ((f) -> f.color is flag_intent and f.name != exclude)

  if not targets.length
    return undefined

  closest = getClosest unit, targets
  if closest?
    return closest.name
  return (sample targets).name

reserveTarget = (unit) ->
  targets = filter flags, ((f) -> f.color is flag_intents.RESERVE and
                                  not any (f.name is u.memory.target for u in values(units) when u.memory.role is roles.RESERVER))

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
  candidates = damagedStructures

  if not candidates.length
    return undefined

  closest = getClosest(unit, candidates)
  if closest?
    return closest.id
  return (sample candidates).d

fortifyTarget = (unit) ->
  candidates = lowestDefences

  if not candidates.length
    return undefined

  closet = getClosest(unit, candidates)
  if closest?
    return closest.id
  return (sample candidates).id

buildTarget = (unit) ->
  if not constructionSites.length
    return undefined
  closest = getClosest(unit, constructionSites)
  if closest?
    return closest.id
  return (sample constructionSites).id

resupplyTarget = (unit) ->
  resupplyAmount = unit.store.getCapacity() - unit.store.getUsedCapacity()
  if resupplyPoints.length == 0
    return undefined

  candidates = filter resupplyPoints, ((r) -> (if r.amount? then (r.amount > resupplyAmount and r.resourceType is RESOURCE_ENERGY) \
                                              else r.store[RESOURCE_ENERGY] > resupplyAmount))

  if not candidates.length
    return undefined

  closest = getClosest(unit, candidates)
  if closest?
    return closest.id
  return (sample candidates).id

refillTarget = (unit) ->
  candidates = filter nonFullTowers

  if not candidates.length
    return undefined

  closest = getClosest(unit, candidates)
  if closest?
    return closest.id
  return (sample candidates).id

healTarget = (unit) ->
  targets = unit.room.find FIND_MY_CREEPS
  injured = filter targets, ((u) -> u.hits < u.hitsMax)
  if injured.length
    return injured.sort((a, b) -> a.hits - b.hits)[0].id
  return undefined

module.exports = { upgradeTarget, harvestTarget, reserveTarget, repairTarget,
                   fortifyTarget, buildTarget, collectTarget, transferTarget,
                   flagTarget, claimTarget, resupplyTarget, refillTarget,
                   healTarget, mineTarget, constructionSites, damagedStructures,
                   damagedDefences, mines, links }
