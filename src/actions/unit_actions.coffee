{ countBy, filter, keys, merge, sample, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ getPath, moveTo, moveBy, goTo } = require 'paths'
{ upgradeTarget, harvestTarget, reserveTarget, repairTarget,
  maintainTarget, buildTarget, collectTarget, transferTarget,
  flagTarget, claimTarget, resupplyTarget, refillTarget,
  healTarget } = require 'unit_targeting'
{ flags, flag_intents } = require 'flags'
{ units } = require 'units'

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

  if unit.memory.inPosition
    unit.harvest target
  else
    containers = filter target.pos.findInRange(FIND_STRUCTURES, 1),
                        (s) -> s.structureType is STRUCTURE_CONTAINER

    # If there is a container by the source, sit on top of it, else sit next to the source
    if containers.length
      location = pos: containers[0].pos, range: 0
    else
      location = pos: target.pos, range: 1

    # Once we reach the target location we only have to harvest
    if unit.pos.inRangeTo(location.pos, location.range)
      unit.memory.inPosition = true
    else
      goTo location, unit

transfer = (unit) ->
  unit.memory.target or= transferTarget unit
  target = Game.getObjectById(unit.memory.target)
  if not target? or target.structureType == STRUCTURE_STORAGE or target.store.getFreeCapacity(RESOURCE_ENERGY) == 0
    unit.memory.target = transferTarget unit
    target = Game.getObjectById(unit.memory.target)
    if not target?
      unit.memory.target = undefined
      return

  if unit.pos.inRangeTo(target, 1)
    if unit.transfer(target, RESOURCE_ENERGY) is OK
      # Successfully transferred resources so start heading towards the next target
      unit.memory.target = if unit.store.getUsedCapacity() then transferTarget(unit) else collectTarget(unit)
      target = Game.getObjectById(unit.memory.target)
      if not target?
        unit.memory.target = undefined
        return

  location = pos: target.pos, range: 1
  goTo location, unit

collect = (unit) ->
  unit.memory.target or= collectTarget unit
  target = Game.getObjectById(unit.memory.target)
  if not target? or
        (target.amount? and target.amount < unit.store.getCapacity()) or
        (target.store? and target.store.getUsedCapacity() < unit.store.getCapacity())
    unit.memory.target = collectTarget unit
    target = Game.getObjectById(unit.memory.target)
    if not target?
      unit.memory.target = undefined
      return

  if unit.pos.inRangeTo(target, 1)
    result = unit.pickup(target)
    if result isnt OK
      resourceTypes = (k for k in keys unit.store)
      for type in resourceTypes
        result = unit.withdraw(target, type)
        break if result is OK
    if result is OK
      # Successfully collected resources so start heading towards the target we want to transfer them to
      unit.memory.target = transferTarget unit
      target = Game.getObjectById(unit.memory.target)
      if not target?
        unit.memory.target = undefined
        return

  location = pos: target.pos, range: 1
  goTo location, unit

build = (unit) ->
  unit.memory.buildTarget or= buildTarget unit
  target = Game.getObjectById(unit.memory.buildTarget)
  if not target? or not target.room? or not target.progress?
    unit.memory.buildTarget = buildTarget unit
    target = Game.getObjectById(unit.memory.buildTarget)
    if not target?
      unit.memory.buildTarget = undefined
      return false
  if unit.build(target) == ERR_NOT_IN_RANGE
    location = pos: target.pos, range: (if unit.room.name isnt target.room.name then 1 else 3)
    goTo location, unit
  return true

resupply = (unit) ->
  # If we have an existing target we should go there
  # If the target no longer exists, find a new one
  # If we've already finished resupplying, choose another target
  unit.memory.resupplyTarget or= resupplyTarget unit
  unitCapacity = unit.store.getCapacity(RESOURCE_ENERGY)
  target = Game.getObjectById(unit.memory.resupplyTarget)
  if not target? or (target.store? and target.store[RESOURCE_ENERGY] < unitCapacity) or \
                    (target.amount? and target.amount < unitCapacity)
    unit.memory.resupplyTarget = resupplyTarget unit
    target = Game.getObjectById(unit.memory.resupplyTarget)
    # Couldn't find a target
    if not target?
      unit.memory.resupplyTarget = undefined
      return false
  # Move to target resources and use them to resupply
  if unit.pickup(target) is OK or unit.withdraw(target, RESOURCE_ENERGY) is OK
    # We've successfully resupplied, so get back to work
    unit.memory.resupplyTarget = undefined
  else
    location = pos: target.pos, range: 1
    goTo location, unit

repair = (unit) ->
  # If we have an existing target we should try to repair it
  # If the target no longer exists, find a new one
  # If we've already finished repairing it, choose another target
  unit.memory.repairTarget or= repairTarget unit
  target = Game.getObjectById(unit.memory.repairTarget)
  if not target? or not target.room? or target.hits >= target.hitsMax or target.hits >= unit.memory.repairInitialHits + 10000
    unit.memory.repairTarget = repairTarget unit
    target = Game.getObjectById(unit.memory.repairTarget)
    # Couldn't find a visible target
    if not target? or not target.room?
      unit.memory.repairTarget = undefined
      unit.memory.repairInitialHits = undefined
      return false
    unit.memory.repairInitialHits = target.hits
  unit.memory.repairInitialHits or= target.hits
  # Move to and repair the target
  if unit.repair(target) == ERR_NOT_IN_RANGE
    # Don't get stuck in current room if target is on the edge of next room
    range = if unit.room.name isnt target.room.name then 1 else 3
    location = pos: target.pos, range: range
    goTo location, unit
  return true

maintain = (unit) ->
  # If we have an existing target we should try to maintain it
  # If the target no longer exists, find a new one
  # If we've already finished maintaining it, choose another target
  unit.memory.maintainTarget or= maintainTarget unit
  target = Game.getObjectById(unit.memory.maintainTarget)
  if not target? or not target.room? or target.hits >= target.hitsMax or target.hits >= unit.memory.maintainInitialHits + 10000
    unit.memory.maintainTarget = maintainTarget unit
    target = Game.getObjectById(unit.memory.maintainTarget)
    # Couldn't find a visible target
    if not target? or not target.room?
      unit.memory.maintainTarget = undefined
      unit.memory.maintainInitialHits = undefined
      return false
    unit.memory.maintainInitialHits = target.hits
  unit.memory.maintainInitialHits or= target.hits
  # Move to and maintain the target
  if unit.repair(target) == ERR_NOT_IN_RANGE
    # Don't get stuck in current room if target is on the edge of next room
    range = if unit.room.name isnt target.room.name then 1 else 3
    location = pos: target.pos, range: range
    goTo location, unit
  return true

refillTower = (unit) ->
  unit.memory.refillTarget or= refillTarget unit
  target = Game.getObjectById(unit.memory.refillTarget)
  if not target? or target.store[RESOURCE_ENERGY] >= target.store.getCapacity(RESOURCE_ENERGY)
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
  if not target?
    unit.memory.target = reserveTarget unit
    target = flags[unit.memory.target]
  return if not target?
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
  if not target?
    unit.memory.target = claimTarget unit
    target = flags[unit.memory.target]
  return if not target?
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
    if unit.memory.shouldInvade
      unit.memory.target = flagTarget unit, flag_intents.INVADE
    else
      unit.memory.target = flagTarget unit, flag_intents.GARRISON
    target = flags[unit.memory.target]
  return if not target?

  location = pos: target.pos, range: 3
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

  location = pos: target.pos, range: 3
  goTo location, unit

defend = (unit) ->
  switch unit.memory.role
    when roles.MEDIC
      return if heal unit
    else
      return if attackUnit(unit) or attackStructure(unit)

  unit.memory.target or= flagTarget unit, flag_intents.DEFEND
  target = flags[unit.memory.target]
  if not target?
    unit.memory.target = flagTarget unit, flag_intents.DEFEND
    target = flags[unit.memory.target]
  return if not target?

  location = pos: target.pos, range: 3
  goTo location, unit

patrol = (unit) ->
  switch unit.memory.role
    when roles.MEDIC
      return if heal unit
    else
      return if attackUnit(unit) or attackStructure(unit)

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
  if not unit.room.controller?.my and unit.room.controller?.safeMode?
    return false
  if unit.memory.unitTarget?
    target = Game.getObjectById unit.memory.unitTarget
  if not target?
    target = unit.pos.findClosestByRange FIND_HOSTILE_CREEPS
  return false if not target?
  unit.memory.unitTarget = target.id
  switch unit.memory.role
    when roles.SNIPER
      # Kite enemies by staying *just* within range, and moving away if they get closer
      if unit.pos.getRangeTo(target.pos) < 3
        deltaX = unit.pos.x - target.pos.x
        deltaY = unit.pos.y - target.pos.y
        xPos = Math.max(Math.min(unit.pos.x + deltaX, 49), 1)
        yPos = Math.max(Math.min(unit.pos.y + deltaY, 49), 1)
        location = pos: new RoomPosition(xPos, yPos, unit.room.name), range: 0
      else
        location = pos: target.pos, range: 3
      goTo location, unit
      unit.rangedAttack(target)
    else
      if unit.attack(target) == ERR_NOT_IN_RANGE
        location = pos: target.pos, range: 1
        goTo location, unit
  return true

attackStructure = (unit) ->
  # Don't try attack if we're in an enemy room which has safemode active
  if not unit.room.controller?.my and unit.room.controller?.safeMode?
    return false
  target = unit.pos.findClosestByPath FIND_HOSTILE_STRUCTURES,
                                      filter: (s) => s.structureType isnt STRUCTURE_CONTROLLER
  if target?
    if unit.attack(target) == ERR_NOT_IN_RANGE
      moveTo target, unit
    return true
  return false

heal = (unit) ->
  if not unit.room.controller?.my and unit.room.controller?.safeMode
    return false
  unit.memory.target or= healTarget unit
  target = Game.getObjectById unit.memory.target
  if not target? or target.hits == target.hitsMax
    unit.memory.target = healTarget unit
    target = Game.getObjectById unit.memory.target
  if not target?
    unit.memory.target = undefined
    target = unit.pos.findClosestByRange FIND_MY_CREEPS,
                                         filter: (c) -> c.name isnt unit.name
    if unit.heal(target) == ERR_NOT_IN_RANGE
      unit.rangedHeal target
    return false
  if unit.heal(target) == ERR_NOT_IN_RANGE
    unit.rangedHeal target
    moveTo target, unit
  return true

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
