{ filter, map, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath, moveTo, moveBy } = require 'paths'
{ upgradeTarget, harvestTarget, reserveTarget, repairTarget,
  maintainTarget, buildTarget, collectTarget, transferTarget } = require 'unit_targeting'
{ flags } = require 'flags'

upgrade = (unit) ->
  unit.memory.target or= upgradeTarget unit
  controller = Game.getObjectById(unit.memory.target)
  if unit.upgradeController(controller) == ERR_NOT_IN_RANGE
    targetLocation = pos: controller.pos, range: 3
    path = getPath unit.pos, targetLocation
    moveBy path, unit

harvest = (unit) ->
  unit.memory.target or= harvestTarget unit
  target = Game.getObjectById unit.memory.target
  if not target?
    unit.memory.target = harvestTarget unit
    target = Game.getObjectById unit.memory.target
  if target.structureType?  # Container present to sit on
    if unit.pos.isEqualTo target.pos
      unit.harvest unit.pos.findClosestByRange(FIND_SOURCES)
    else
      targetLocation = pos: target.pos, range: 0
      path = getPath unit.pos, targetLocation
      if path.incomplete
        unit.memory.target = harvestTarget unit
        target = Game.getObjectById unit.memory.target
      else
        moveBy path, unit
  else if target.energy?  # No container built yet so just mine the source
    if unit.harvest(target) == ERR_NOT_IN_RANGE
      targetLocation = pos: target.pos, range: 1
      path = getPath unit.pos, targetLocation
      if path.incomplete
        unit.memory.target = harvestTarget unit
        target = Game.getObjectById unit.memory.target
      else
        moveBy path, unit
  else if target.name?  # All sources currently occupied so get ready to replace dying unit
    targetLocation = pos: target.pos, range: 1
    path = getPath unit.pos, targetLocation
    if path.incomplete
      unit.memory.target = harvestTarget unit
      target = Game.getObjectById unit.memory.target
    else
      moveBy path, unit

transfer = (unit) ->
  unit.memory.target or= transferTarget unit
  target = Game.getObjectById(unit.memory.target)
  if not target? or not target.room?
    unit.memory.target = transferTarget unit
    target = Game.getObjectById(unit.memory.target)
    if not target?
      unit.memory.target = undefined
      return false
  if unit.transfer(target, RESOURCE_ENERGY) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: 1
    path = getPath unit.pos, location
    moveBy path, unit
  else
    unit.memory.target = undefined

collect = (unit) ->
  unit.memory.target or= collectTarget unit
  target = Game.getObjectById(unit.memory.target)
  if not target? or not target.room?
    unit.memory.target = collectTarget unit
    target = Game.getObjectById(unit.memory.target)
    if not target?
      unit.memory.target = undefined
      return false
  if unit.pickup(target) is OK or unit.withdraw(target,RESOURCE_ENERGY) is OK
    unit.memory.working = true
    unit.memory.target = undefined
  else
    location = pos: target.pos, range: 1
    path = getPath unit.pos, location
    moveBy path, unit
  return true

build = (unit) ->
  unit.memory.buildTarget or= buildTarget unit
  target = Game.getObjectById(unit.memory.buildTarget)
  if not target? or not target.room?
    unit.memory.buildTarget = buildTarget unit
    target = Game.getObjectById(unit.memory.buildTarget)
    if not target?
      unit.memory.buildTarget = undefined
      return false
  if unit.build(target) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: (if unit.room.name isnt target.room.name then 1 else 3)
    path = getPath unit.pos, location
    moveBy path, unit
  return true

resupply = (unit) ->
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

  resourceLocations = map resources, (r) => pos: r.pos, range: 1
  path = getPath unit.pos, resourceLocations
  if path.path.length
    moveBy path, unit
  else
    target = unit.pos.findClosestByRange resources, RESOURCE_ENERGY
    if unit.pickup(target) is OK or unit.withdraw(target, RESOURCE_ENERGY) is OK
      unit.memory.working = true

repair = (unit) ->
  unit.memory.repairTarget or= repairTarget unit
  target = Game.getObjectById(unit.memory.repairTarget)
  if not target? or not target.room?
    unit.memory.repairTarget = undefined
    unit.memory.repairInitialHits = undefined
    return false
  unit.memory.repairInitialHits or= target.hits
  if target.hits == target.hitsMax or target.hits >= unit.memory.repairInitialHits + 50000
    unit.memory.repairTarget = repairTarget unit
    target = Game.getObjectById(unit.memory.repairTarget)
    if not target?
      unit.memory.repairTarget = undefined
      unit.memory.repairInitialHits = undefined
      return false
    unit.memory.repairInitialHits = target.hits
  if unit.repair(target) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: (if unit.room.name isnt target.room.name then 1 else 3)
    path = getPath unit.pos, location
    moveBy path, unit
  return true

maintain = (unit) ->
  unit.memory.maintainTarget or= maintainTarget unit
  target = Game.getObjectById(unit.memory.maintainTarget)
  if not target? or not target.room?
    unit.memory.maintainTarget = undefined
    unit.memory.maintainInitialHits = undefined
    return false
  unit.memory.maintainInitialHits or= target.hits
  if target.hits == target.hitsMax or target.hits >= unit.memory.maintainInitialHits + 50000
    unit.memory.maintainTarget = maintainTarget unit
    target = Game.getObjectById(unit.memory.maintainTarget)
    if not target?
      unit.memory.maintainTarget = undefined
      unit.memory.maintainInitialHits = undefined
      return false
    unit.memory.maintainInitialHits = target.hits
  if unit.repair(target) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: (if unit.room.name isnt target.room.name then 1 else 3)
    path = getPath unit.pos, location
    moveBy path, unit
  return true

refillTower = (unit) ->
  towers = []
  for room in values rooms
    towersFound = room.find FIND_MY_STRUCTURES,
                            filter: (s) => s.structureType is STRUCTURE_TOWER and \
                                           s.store[RESOURCE_ENERGY] < s.store.getCapacity(RESOURCE_ENERGY)
    towers.push(towersFound...) if towersFound?

  return false if not towers.length
  towerLocations = map towers, (t) => pos: t.pos, range: 1
  path = getPath unit.pos, towerLocations
  if path.path.length
    moveBy path, unit
  else
    unit.transfer unit.pos.findClosestByRange(towers), RESOURCE_ENERGY
  return true

reserve = (unit) ->
  unit.memory.target or= reserveTarget unit
  target = flags[unit.memory.target]
  room = rooms[target.pos.roomName]
  if not room?
    targetLocation = pos: target.pos, range: 1
    path = getPath unit.pos, targetLocation
    moveBy path, unit
  else if unit.reserveController(room.controller) == ERR_NOT_IN_RANGE
    targetLocation = pos: room.controller.pos, range: 1
    path = getPath unit.pos, targetLocation
    moveBy path, unit

claim = (unit) ->
  targetRoom = Game.flags['claim'].pos.roomName
  if unit.room.name isnt targetRoom
    exit = unit.pos.findClosestByPath unit.room.findExitTo(targetRoom)
    moveTo exit, unit
  else
    controller = Game.rooms[targetRoom].controller
    if controller.owner? and not controller.my
      if unit.attackController(controller) == ERR_NOT_IN_RANGE
        moveTo controller, unit
    else
      if unit.claimController(controller) == ERR_NOT_IN_RANGE
        moveTo controller, unit

invade = (unit) ->
  targetRoom = Game.flags['invade'].pos.roomName
  if unit.room.name isnt targetRoom
    exit = unit.pos.findClosestByPath unit.room.findExitTo(targetRoom)
    moveTo exit, unit
  else
    switch unit.memory.role
      when roles.MEDIC then heal unit
      else attackUnit(unit) or attackStructure(unit)

attackUnit = (unit) ->
  target = unit.pos.findClosestByPath FIND_HOSTILE_CREEPS
  if target?
    moveTo target, unit
    switch unit.memory.role
      when roles.SNIPER then unit.rangedAttack target
      else unit.attack target
    return true
  return false

attackStructure = (unit) ->
  target = unit.pos.findClosestByPath FIND_HOSTILE_STRUCTURES,
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

module.exports = { upgrade, harvest, transfer, build,
                   repair, maintain, refillTower, shouldWork,
                   moveTo, resupply, collect, claim,
                   reserve, invade }
