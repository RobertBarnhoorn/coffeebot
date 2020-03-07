{ filter, map, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath, moveTo, moveBy, goTo } = require 'paths'
{ upgradeTarget, harvestTarget, reserveTarget, repairTarget,
  maintainTarget, buildTarget, collectTarget, transferTarget,
  defendTarget, claimTarget, resupplyTarget } = require 'unit_targeting'
{ flags, flag_intents } = require 'flags'

upgrade = (unit) ->
  unit.memory.target or= upgradeTarget unit
  controller = Game.getObjectById(unit.memory.target)
  if unit.upgradeController(controller) == ERR_NOT_IN_RANGE
    location = pos: controller.pos, range: 3
    goTo location, unit

harvest = (unit) ->
  unit.memory.target or= harvestTarget unit
  target = Game.getObjectById unit.memory.target
  if not target?
    unit.memory.target = harvestTarget unit
    target = Game.getObjectById unit.memory.target
  if not target?
    unit.memory.target = undefined
    return
  if unit.harvest(target) == ERR_NOT_IN_RANGE
    container = target.pos.findClosestByRange STRUCTURE_CONTAINER
    if container?
      location = pos: container.pos, range: 0
      goTo location, unit
    else
      location = pos: target.pos, range: 1
      goTo location, unit

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
    goTo location, unit
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
    goTo location, unit
  return true

resupply = (unit) ->
  unit.memory.resupplyTarget or= resupplyTarget unit
  target = Game.getObjectById(unit.memory.resupplyTarget)
  if not target? or not target.room?
    unit.memory.resupplyTarget = resupplyTarget unit
    target = Game.getObjectById(unit.memory.resupplyTarget)
    if not target?
      unit.memory.resupplyTarget = undefined
      return false
  if unit.pickup(target) is OK or unit.withdraw(target, RESOURCE_ENERGY) is OK
    unit.memory.resupplyTarget = undefined
    unit.memory.working = true
  else
    location = pos: target.pos, range: 1
    goTo location, unit

build = (unit) ->
  unit.memory.buildTarget or= buildTarget unit
  target = Game.getObjectById(unit.memory.buildTarget)
  if not target? or not target.room or not target.progress?
    unit.memory.buildTarget = buildTarget unit
    target = Game.getObjectById(unit.memory.buildTarget)
    if not target?
      unit.memory.buildTarget = undefined
      return false
  if unit.build(target) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: (if unit.room.name isnt target.room.name then 1 else 3)
    goTo location, unit
  return true

repair = (unit) ->
  unit.memory.repairTarget or= repairTarget unit
  target = Game.getObjectById(unit.memory.repairTarget)
  if not target? or not target.room?
    unit.memory.repairTarget = undefined
    unit.memory.repairInitialHits = undefined
    return false
  unit.memory.repairInitialHits or= target.hits
  if target.hits == target.hitsMax or target.hits >= unit.memory.repairInitialHits + 25000
    unit.memory.repairTarget = repairTarget unit
    target = Game.getObjectById(unit.memory.repairTarget)
    if not target?
      unit.memory.repairTarget = undefined
      unit.memory.repairInitialHits = undefined
      return false
    unit.memory.repairInitialHits = target.hits
  if unit.repair(target) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: (if unit.room.name isnt target.room.name then 1 else 3)
    goTo location, unit
  return true

maintain = (unit) ->
  unit.memory.maintainTarget or= maintainTarget unit
  target = Game.getObjectById(unit.memory.maintainTarget)
  if not target? or not target.room?
    unit.memory.maintainTarget = undefined
    unit.memory.maintainInitialHits = undefined
    return false
  unit.memory.maintainInitialHits or= target.hits
  if target.hits == target.hitsMax or target.hits >= unit.memory.maintainInitialHits + 25000
    unit.memory.maintainTarget = maintainTarget unit
    target = Game.getObjectById(unit.memory.maintainTarget)
    if not target?
      unit.memory.maintainTarget = undefined
      unit.memory.maintainInitialHits = undefined
      return false
    unit.memory.maintainInitialHits = target.hits
  if unit.repair(target) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: (if unit.room.name isnt target.room.name then 1 else 3)
    goTo location, unit
  return true

refillTower = (unit) ->
  towers = []
  for room in values rooms
    towersFound = room.find FIND_MY_STRUCTURES,
                            filter: (s) => s.structureType is STRUCTURE_TOWER and \
                                           s.store[RESOURCE_ENERGY] < s.store.getCapacity(RESOURCE_ENERGY)
    towers.push(towersFound...) if towersFound?

  return false if not towers.length
  locations = map towers, (t) => pos: t.pos, range: 1
  path = getPath unit.pos, locations
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
    location = pos: target.pos, range: 1
    goTo location, unit
  else if unit.reserveController(room.controller) == ERR_NOT_IN_RANGE
    location = pos: room.controller.pos, range: 1
    goTo location, unit

claim = (unit) ->
  unit.memory.target or= claimTarget unit
  target = flags[unit.memory.target]
  room = rooms[target.pos.roomName]
  if not room?
    location = pos: target.pos, range: 1
    goTo location, unit
  else
    controller = room.controller
    if controller.owner? and not controller.my
      if unit.attackController(controller) == ERR_NOT_IN_RANGE
        location = pos: room.controller.pos, range: 1
        goTo location, unit
    else
      if unit.claimController(controller) == ERR_NOT_IN_RANGE
        location = pos: room.controller.pos, range: 1
        goTo location, unit

invade = (unit) ->
  targetRoom = Game.flags['invade'].pos.roomName
  if unit.room.name isnt targetRoom
    exit = unit.pos.findClosestByPath unit.room.findExitTo(targetRoom)
    moveTo exit, unit
  else
    switch unit.memory.role
      when roles.MEDIC then heal unit
      else attackUnit(unit) or attackStructure(unit)

defend = (unit) ->
  unit.memory.target or= defendTarget unit
  target = flags[unit.memory.target]
  if not target?
    unit.memory.target = defendTarget unit
    target = flags[unit.memory.target]
  if not target?
    return

  switch unit.memory.role
    when roles.MEDIC
      if not heal unit
        location = pos: target.pos, range: 5
        goTo location, unit
    else
      if not attackUnit unit
        location = pos: target.pos, range: 5
        goTo location, unit

attackUnit = (unit) ->
  target = unit.pos.findClosestByPath FIND_HOSTILE_CREEPS
  if target?
    switch unit.memory.role
      when roles.SNIPER
        if unit.rangedAttack(target) == ERR_NOT_IN_RANGE
          moveTo target, unit
      else
        if unit.attack(target) == ERR_NOT_IN_RANGE
          moveTo target, unit
    return true
  return false

attackStructure = (unit) ->
  target = unit.pos.findClosestByPath FIND_HOSTILE_STRUCTURES,
                                      filter: (s) => s.structureType isnt STRUCTURE_CONTROLLER
  if target?
    if unit.attack(target) == ERR_NOT_IN_RANGE
      moveTo target, unit
    return true
  return false

heal = (unit) ->
  injured = unit.room.find FIND_MY_CREEPS,
                           filter: (u) => u.hits < u.hitsMax
  if injured.length
    target = injured.sort((a, b) => a.hits - b.hits)[0]
    if unit.heal(target) == ERR_NOT_IN_RANGE
      unit.rangedHeal(target)
      moveTo target, unit
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
                   reserve, invade, defend }
