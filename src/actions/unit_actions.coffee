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
  if unit.room.energyAvailable < unit.room.energyCapacityAvailable
    structure = unit.pos.findClosestByPath \
                  FIND_MY_STRUCTURES,
                  filter: (s) => (s.energy < s.energyCapacity and
                                 (s.structureType is STRUCTURE_SPAWN or
                                  s.structureType is STRUCTURE_EXTENSION))
                                  
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

collect = (unit) ->
  dropped = unit.room.find FIND_DROPPED_RESOURCES
  if dropped?
    target = unit.pos.findClosestByPath dropped
    if unit.pickup(target) == ERR_NOT_IN_RANGE
      moveTo target, unit
  else
    containers = unit.room.find FIND_MY_STRUCTURES,
                                filter: (s) => s.structureType is STRUCTURE_CONTAINER
    target = reduce containers, (max, c) => if max > c then max else c
    if target?
      if unit.withdraw(target, RESOURCE_ENERGY) == ERR_NOT_IN_RANGE
        moveTo target, unit

repairStructureUrgent = (unit) ->
  structures = unit.room.find FIND_STRUCTURES,
                              filter: (s) => s.hits < s.hitsMax and s.hits < 5000 and \
                                             s.structureType isnt STRUCTURE_WALL
  target = unit.pos.findClosestByPath structures.sort((a, b) => a.hits - b.hits) \
                                                .slice(0, Math.floor(Math.sqrt(structures.length)))
  if target?
    if unit.repair(target) == ERR_NOT_IN_RANGE
      moveTo target, unit
    return true
  return false

repairStructureNonUrgent = (unit) ->
  structures = unit.room.find FIND_STRUCTURES,
                              filter: (s) => s.hits < s.hitsMax

  target = unit.pos.findClosestByPath structures.sort((a, b) => a.hits - b.hits) \
                                                .slice(0, Math.floor(Math.sqrt(structures.length)))
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
  if unit.carry.energy is 0 and unit.memory.working
    false
  else if unit.carry.energy is unit.carryCapacity and not unit.memory.working
    true
  else
    unit.memory.working

moveTo = (location, unit) ->
  result = unit.moveTo location, reusePath: 0, maxRooms: 1, visualizePathStyle:
                                       fill: 'transparent',
                                       stroke: '#ffaa00',
                                       lineStyle: 'dashed',
                                       strokeWidth: .15,
                                       opacity: .1

module.exports = { upgrade, harvest, transfer, build,
                   repairStructureUrgent, repairStructureNonUrgent,
                   refillTower, shouldWork, moveTo, collect }
