{ filter, reduce } = require 'lodash'
{ readMem } = require 'memory'

upgrade = (unit) ->
  controller = unit.room.controller
  moveTo controller, unit
  unit.upgradeController controller

harvest = (unit) ->
  source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
  moveTo source, unit
  unit.harvest source

transfer = (unit) ->
  structure = findStructure unit, [STRUCTURE_EXTENSION, STRUCTURE_SPAWN]
  if not structure?
    structure = unit.room.storage
  if structure?
    moveTo structure, unit
    unit.transfer structure, RESOURCE_ENERGY

build = (unit) ->
  site = unit.pos.findClosestByPath FIND_MY_CONSTRUCTION_SITES
  if site?
    moveTo site, unit
    unit.build site
    return true
  return false

collect = (unit) ->
  dropped = unit.room.find FIND_DROPPED_RESOURCES,
                           filter: (r) => r.amount >= 100 and \
                                          r.resourceType is RESOURCE_ENERGY
  if dropped.length
    target = unit.pos.findClosestByPath dropped
    moveTo target, unit
    unit.pickup target
    return true
  else
    containers = unit.room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType is STRUCTURE_CONTAINER and \
                                s.store[RESOURCE_ENERGY] >= 100
    if containers.length
      target = unit.pos.findClosestByPath containers
      moveTo target, unit
      unit.withdraw target, RESOURCE_ENERGY
      return true
    return false

resupply = (unit) ->
  stores = unit.room.find FIND_STRUCTURES,
                          filter: (s) => (s.structureType is STRUCTURE_CONTAINER or
                                          s.structureType is STRUCTURE_STORAGE) and \
                                          s.store[RESOURCE_ENERGY] >= 100

  if stores.length
    target = unit.pos.findClosestByPath stores
    moveTo target, unit
    unit.withdraw target, RESOURCE_ENERGY

repairStructureUrgent = (unit) ->
  structures = unit.room.find FIND_STRUCTURES,
                              filter: (s) => s.structureType not in [STRUCTURE_WALL, STRUCTURE_RAMPART] and \
                                             s.hits < s.hitsMax

  target = unit.pos.findClosestByPath structures.sort((a, b) => (b.hitsMax - b.hits) - (a.hitsMax - a.hits)) \
                                                .slice(0, Math.floor(Math.sqrt(structures.length)))
  if target?
    moveTo target, unit
    unit.repair target
    return true
  return false

repairStructureNonUrgent = (unit) ->
  structures = unit.room.find FIND_STRUCTURES,
                              filter: (s) => s.hits < s.hitsMax

  target = unit.pos.findClosestByPath structures.sort((a, b) => a.hits - b.hits) \
                                                .slice(0, Math.floor(Math.sqrt(structures.length)))
  if target?
    moveTo target, unit
    unit.repair target
    return true
  return false

refillTower = (unit) ->
  tower = unit.pos.findClosestByPath FIND_MY_STRUCTURES,
                                     filter: (s) => s.structureType is STRUCTURE_TOWER and \
                                                    s.store[RESOURCE_ENERGY] < s.store.getCapacity(RESOURCE_ENERGY)
  if tower?
    moveTo tower, unit
    unit.transfer tower, RESOURCE_ENERGY
    return true
  return false

claim = (unit) ->
  targetRoom = readMem 'claimRoom'
  if unit.room.name isnt targetRoom
    exit = unit.pos.findClosestByPath unit.room.findExitTo(targetRoom)
    moveTo exit, unit
  else
    controller = Game.rooms[targetRoom].controller
    if controller.owner.username? and controller.owner.username isnt 'MrFluffy'
      moveTo controller, unit
      unit.attackController controller
    else
      moveTo controller, unit
      unit.claimController controller

soldierInvade = (unit) ->
  targetRoom = readMem 'enemyRoom'
  if unit.room.name isnt targetRoom
    exit = unit.pos.findClosestByPath unit.room.findExitTo(targetRoom)
    moveTo exit, unit
  else
    attackUnit(unit) or attackStructure(unit)

healerInvade = (unit) ->
  targetRoom = readMem 'enemyRoom'
  if unit.room.name isnt targetRoom
    exit = unit.pos.findClosestByPath unit.room.findExitTo(targetRoom)
    moveTo exit, unit
  else
    heal unit

attackUnit = (unit) ->
  target = unit.pos.findClosestByPath FIND_HOSTILE_CREEPS
  if target?
    moveTo target, unit
    unit.attack target
    return true
  return false

attackStructure = (unit) ->
  target = unit.pos.findClosestByPath FIND_HOSTILE_STRUCTURES
                                      filter: (s) => s.structureType isnt STRUCTURE_CONTROLLER
  if target?
    moveTo target, unit
    unit.attack target
    return true
  return false

heal = (unit) ->
  injured = unit.room.find FIND_MY_CREEPS,
                           filter: (u) => u.hits < u.hitsMax
  if injured.length
    target = injured.sort((a, b) => a.hits - b.hits)[0]
    moveTo target, unit
    unit.heal target
    return true
  return false

shouldWork = (unit) ->
  if unit.store.getFreeCapacity() is 0
    true
  else if unit.store.getFreeCapacity() is unit.store.getCapacity()
    false
  else
    unit.memory.working

findStructure = (unit, structureTypes) ->
  unit.pos.findClosestByPath FIND_MY_STRUCTURES,
                             filter: (s) => s.energy < s.energyCapacity and \
                                            s.structureType in structureTypes

moveTo = (location, unit) ->
  result = unit.moveTo location, reusePath: 0, maxRooms: 1, visualizePathStyle:
                                       fill: 'transparent',
                                       stroke: '#ffaa00',
                                       lineStyle: 'dashed',
                                       strokeWidth: .15,
                                       opacity: .1

module.exports = { upgrade, harvest, transfer, build,
                   repairStructureUrgent, repairStructureNonUrgent,
                   refillTower, shouldWork, moveTo, resupply,
                   collect, claim, soldierInvade, healerInvade }
