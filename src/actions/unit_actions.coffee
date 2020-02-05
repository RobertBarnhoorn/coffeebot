{ filter, reduce } = require 'lodash'

upgrade = (unit) ->
  controller = unit.room.controller
  if unit.upgradeController(controller) == ERR_NOT_IN_RANGE
    moveTo controller, unit

harvest = (unit) ->
  source = unit.pos.findClosestByPath FIND_SOURCES_ACTIVE
  if unit.harvest(source) == ERR_NOT_IN_RANGE
    moveTo source, unit

transfer = (unit) ->
  structure = findStructure unit, [STRUCTURE_EXTENSION, STRUCTURE_SPAWN]
  if not structure?
    structure = unit.room.storage
  if structure?
    if unit.transfer(structure, RESOURCE_ENERGY) == ERR_NOT_IN_RANGE
      moveTo structure, unit

build = (unit) ->
  site = unit.pos.findClosestByPath FIND_MY_CONSTRUCTION_SITES
  if site?
    if unit.build(site) == ERR_NOT_IN_RANGE
      moveTo site, unit
    return true
  return false

distribute = (unit) ->
  dropped = unit.room.find FIND_DROPPED_RESOURCES,
                           filter: (r) => r.amount >= 25 and \
                                          r.resourceType is RESOURCE_ENERGY
  if dropped.length
    target = unit.pos.findClosestByPath dropped
    if unit.pickup(target) == ERR_NOT_IN_RANGE
      moveTo target, unit
  else
    containers = unit.room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType is STRUCTURE_CONTAINER and \
                                s.store[RESOURCE_ENERGY] >= 25
    if containers.length
      target = unit.pos.findClosestByPath containers
      if unit.withdraw(target, RESOURCE_ENERGY) == ERR_NOT_IN_RANGE
        moveTo target, unit


collect = (unit) ->
  stores = unit.room.find FIND_STRUCTURES,
                          filter: (s) => (s.structureType is STRUCTURE_CONTAINER or
                                          s.structureType is STRUCTURE_STORAGE) and \
                                          s.store[RESOURCE_ENERGY] >= unit.store.getCapacity(RESOURCE_ENERGY)

  if stores.length
    target = unit.pos.findClosestByPath stores
    if unit.withdraw(target, RESOURCE_ENERGY) == ERR_NOT_IN_RANGE
      moveTo target, unit

repairStructureUrgent = (unit) ->
  structures = unit.room.find FIND_STRUCTURES,
                              filter: (s) => s.hits < s.hitsMax and s.hits < 2000 and \
                                             s.structureType isnt STRUCTURE_WALL
  target = unit.pos.findClosestByPath structures.sort((a, b) => a.hits - b.hits) \
                                                .slice(0, 3)
  if target?
    if unit.repair(target) == ERR_NOT_IN_RANGE
      moveTo target, unit
    return true
  return false

repairStructureNonUrgent = (unit) ->
  structures = unit.room.find FIND_STRUCTURES,
                              filter: (s) => s.hits < s.hitsMax

  target = unit.pos.findClosestByPath structures.sort((a, b) => a.hits - b.hits) \
                                                .slice(0, 3)
  if target?
    if unit.repair(target) == ERR_NOT_IN_RANGE
      moveTo target, unit
    return true
  return false

refillTower = (unit) ->
  tower = unit.pos.findClosestByPath FIND_MY_STRUCTURES,
                                     filter: (s) => s.structureType is STRUCTURE_TOWER and \
                                                    s.store[RESOURCE_ENERGY] < s.store.getCapacity(RESOURCE_ENERGY)
  if tower?
    if unit.transfer(tower, RESOURCE_ENERGY) == ERR_NOT_IN_RANGE
      moveTo tower, unit
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
                   refillTower, shouldWork, moveTo, collect, distribute }
