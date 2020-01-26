{ filter } = require('lodash')

upgrade = (unit) ->
  controller = unit.room.controller
  if unit.upgradeController(controller) == ERR_NOT_IN_RANGE
    moveTo controller, unit

harvest = (source, unit) ->
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

repair = (unit) ->
  candidates = unit.room.find FIND_STRUCTURES,
                              filter: (s) => s.structureType isnt STRUCTURE_WALL and
                                             s.hits < s.hitsMax
  if candidates.length
    target = unit.pos.findClosestByPath candidates.sort((a, b) => a.hits - b.hits) \
                                                  .slice(0, Math.floor(Math.sqrt(candidates.length)))
    if unit.repair(target) == ERR_NOT_IN_RANGE
      moveTo target, unit

shouldWork = (unit) ->
  if unit.carry.energy is 0 and unit.memory.working
    false
  else if unit.carry.energy is unit.carryCapacity and not unit.memory.working
    true
  else
    unit.memory.working

moveTo = (location, unit) ->
  result = unit.moveTo location, maxRooms: 1, visualizePathStyle:
                                       fill: 'transparent',
                                       stroke: '#ffaa00',
                                       lineStyle: 'dashed',
                                       strokeWidth: .15,
                                       opacity: .1

module.exports = { upgrade, harvest, transfer,
                   build, repair, shouldWork,
                   moveTo }
