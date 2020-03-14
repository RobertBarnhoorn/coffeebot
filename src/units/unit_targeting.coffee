{ any, filter, map, sample, shuffle, values } = require 'lodash'
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
    structuresFound = room.find FIND_MY_STRUCTURES,
                                filter: (s) => s.energy < s.energyCapacity and \
                                                          s.structureType in [STRUCTURE_EXTENSION, STRUCTURE_SPAWN]
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
                               filter: (r) => r.resourceType is RESOURCE_ENERGY and
                                              r.amount > 0
    containersFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType is STRUCTURE_CONTAINER and
                                               s.store[RESOURCE_ENERGY] > 0
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
                         .slice(0, Math.ceil(Math.sqrt(resources.length)))
  if prioritized.length
    return getClosest(unit, prioritized).id
  return undefined

upgradeTarget = (unit) ->
  candidates = (room for room in values rooms \
                when room.controller? and room.controller.my and not room.controller.reservation?)
  return (sample candidates).controller.id

harvestTarget = (unit) ->
  sources = []
  for room in values rooms
    sourcesFound = filter room.find(FIND_SOURCES),
                     (s) -> not any(u.memory.target is s.id for u in values units)
    sources.push(sourcesFound...) if sourcesFound?

  if sources.length
    return getClosest(unit, sources).id
  return undefined

flagTarget = (unit, flag_intent) ->
  targets = map(filter(flags, (f) => f.color is flag_intent),
               (f) => f.name)
  if targets.length
    return sample targets
  return undefined

reserveTarget = (unit) ->
  targets = map(filter(flags, ((f) -> f.color is flag_intents.RESERVE and not any (u.memory.target is f.name for u in values units))),
               (f) => f.name)

  if targets.length
    return sample targets
  return undefined

claimTarget = (unit) ->
  targets = map(filter(flags, (f) -> f.color is flag_intents.CLAIM and not any (u.memory.target is f.name for u in values units)),
               (f) => f.name)
  if targets.length
    return sample targets
  return undefined

repairTarget = (unit) ->
  structures = []
  for room in values rooms when not room.controller?.owner? or
                                room.controller?.owner?.username is MYSELF or
                                not room.controller?.reservation? or
                                room.controller?.reservation?.username is MYSELF
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
  for room in values rooms when not room.controller?.owner? or
                                room.controller?.owner?.username is MYSELF or
                                not room.controller?.reservation? or
                                room.controller?.reservation?.username is MYSELF
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.hits < s.hitsMax and \
                                               not any(u.memory.maintainTarget is s.id for u in values units)
    structures.push(structuresFound...) if structuresFound?

  prioritized = structures.sort((a, b) => a.hits - b.hits) \
                          .slice(0, Math.ceil(Math.sqrt(structures.length)))

  if prioritized.length
    return getClosest(unit, prioritized).id
  return undefined

buildTarget = (unit) ->
  sites = []
  for room in values rooms when not room.controller?.owner? or
                                room.controller?.owner?.username is MYSELF or
                                not room.controller?.reservation? or
                                room.controller?.reservation?.username is MYSELF
    sitesFound = room.find FIND_MY_CONSTRUCTION_SITES,
                           filter: (s) => not any(u.memory.buildTarget is s.id for u in values units)
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
    return getClosest(unit, resources).id
  return undefined

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
  units = unit.room.find FIND_MY_CREEPS
  injured = filter units, ((u) -> u.hits < u.hitsMax)
  if injured.length
    return injured.sort((a, b) => a.hits - b.hits)[0].id
  return undefined

module.exports = { upgradeTarget, harvestTarget, reserveTarget, repairTarget,
                   maintainTarget, buildTarget, collectTarget, transferTarget,
                   flagTarget, claimTarget, resupplyTarget, refillTarget,
                   healTarget }
