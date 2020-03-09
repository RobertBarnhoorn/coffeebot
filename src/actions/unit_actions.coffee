{ countBy, filter, map, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath, moveTo, moveBy, goTo } = require 'paths'
{ upgradeTarget, harvestTarget, reserveTarget, repairTarget,
  maintainTarget, buildTarget, collectTarget, transferTarget,
  flagTarget, claimTarget, resupplyTarget, refillTarget } = require 'unit_targeting'
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
    return false
  if unit.harvest(target) == ERR_NOT_IN_RANGE
    container = target.pos.findInRange(FIND_STRUCTURES, 1,
                                       filter: (s) -> s.structureType is STRUCTURE_CONTAINER)
    if container.length
      location = pos: container[0].pos, range: 0
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
  if target.hits >= target.hitsMax or target.hits >= unit.memory.repairInitialHits + 50000
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
  unit.memory.refillTarget or= refillTarget unit
  target = Game.getObjectById(unit.memory.refillTarget)
  if not target? or not target.room?
    unit.memory.refillTarget = refillTarget unit
    target = Game.getObjectById(unit.memory.refillTarget)
    if not target?
      unit.memory.refillTarget = undefined
      return false
  if unit.transfer(target, RESOURCE_ENERGY) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: 1
    goTo location, unit
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
  switch unit.memory.role
    when roles.MEDIC
      return if heal unit
    else
      return if attackUnit(unit) or attackStructure(unit)

  unit.memory.shouldInvade or= shouldInvade()
  if unit.memory.shouldInvade
    unit.memory.target or= flagTarget unit, flag_intents.INVADE
  else
    unit.memory.target or= flagTarget unit, flag_intents.GARRISON

  target = flags[unit.memory.target]
  if not target?
    unit.memory.target = flagTarget unit, flag_intents.INVADE
    target = flags[unit.memory.target]
  return if not target?

  location = pos: target.pos, range: 1
  goTo location, unit

attack = (unit) ->
  switch unit.memory.role
    when roles.MEDIC
      return if heal unit
    else
      return if attackUnit(unit) or attackStructure(unit)

  unit.memory.target or= flagTarget unit, flag_intents.ATTACK
  target = flags[unit.memory.target]
  if not target?
    unit.memory.target = flagTarget unit, flag_intents.ATTACK
    target = flags[unit.memory.target]
  return if not target?

  location = pos: target.pos, range: 2
  goTo location, unit

defend = (unit) ->
  switch unit.memory.role
    when roles.MEDIC
      return if heal unit
    else
      return if attackUnit unit

  unit.memory.target or= flagTarget unit, flag_intents.DEFEND
  target = flags[unit.memory.target]
  if not target?
    unit.memory.target = flagTarget unit, flag_intents.DEFEND
    target = flags[unit.memory.target]
  return if not target?

  location = pos: target.pos, range: 1
  goTo location, unit

patrol = (unit) ->
  switch unit.memory.role
    when roles.MEDIC
      return if heal unit
    else
      return if attackUnit unit

  unit.memory.target or= flagTarget unit, flag_intents.PATROL
  target = flags[unit.memory.target]
  if not target?
    unit.memory.target = flagTarget unit, flag_intents.PATROL
    target = flags[unit.memory.target]
  return if not target?

  if unit.pos.inRangeTo(target.pos, 1)
    unit.memory.target = flagTarget unit, flag_intents.PATROL
    target = flags[unit.memory.target]
  else
    location = pos: target.pos, range: 1
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

shouldInvade = ->
  actual = {}
  actual[v] = 0 for v in values roles
  merge actual, countBy(filter(units, (u) => not u.spawning), 'memory.role')
  actual[roles.MEDIC] >= 3 and actual[roles.SOLDIER] >= 2 and actual[roles.SNIPER] >= 2

module.exports = { upgrade, harvest, transfer, build,
                   repair, maintain, refillTower, shouldWork,
                   moveTo, resupply, collect, claim,
                   reserve, patrol, attack, invade,
                   defend }
