{ any, filter, forEach, map, reduce, values } = require 'lodash'
{ minBy } = require 'algorithms'
{ roles } = require 'unit_roles'
{ rooms } = require 'rooms'
{ units } = require 'units'

upgrade = (unit) ->
  controllers = []
  controllerLocation = undefined
  for room in values rooms
    if not room.controller? or not room.controller.my
      continue
    closest = undefined
    minCost = 10000
    controllerLocation = pos: room.controller.pos, range: 1
    for u in values(units) when u.memory.role is roles.UPGRADER
      cost = getPathCost u.pos, controllerLocation
      if cost < minCost
        minCost = cost
        closest = u
    if unit is closest
      controllers.push(room.controller)

  if not controllers.length
    controllers = [unit.room.controller]
  controllerLocations = map controllers, (c) => pos: c.pos, range: 3
  path = getPath unit.pos, controllerLocations
  if path.length
    moveBy path, unit
  else
    unit.upgradeController unit.room.controller

harvest = (unit) ->
  mines = []
  sources = []
  for room in values rooms
    minesFound = room.find FIND_STRUCTURES,
                           filter: (s) => s.structureType is STRUCTURE_CONTAINER and \
                                          not any(s.pos.isEqualTo(u.pos) \
                                          for u in values(units) when u isnt unit)
    mines.push(minesFound...) if minesFound?

    sourcesFound = room.find FIND_SOURCES,
                             filter: (s) => not any(s.pos.inRangeTo(m.pos, 1) for m in minesFound)
    for s in sourcesFound
      miners = filter s.pos.findInRange(FIND_CREEPS, 1), (u) => u.memory.role is roles.HARVESTER
      if miners.length is 0 or (miners.length is 1 and unit in miners)
        sources.push s

  mineLocations = map mines, (m) => pos: m.pos, range: 0
  sourceLocations = map sources, (s) => pos: s.pos, range: 1
  resourceLocations = mineLocations.concat sourceLocations
  if resourceLocations.length
    path = getPath unit.pos, resourceLocations
    if path.length
      moveBy path, unit
    else
      unit.harvest unit.pos.findClosestByRange FIND_SOURCES_ACTIVE
  else
    expiringHarvester = minBy filter(units, (u) => u.memory.role is roles.HARVESTER), 'ticksToLive'
    moveTo expiringHarvester, unit if expiringHarvester?

transfer = (unit) ->
  structures = []
  for room in values rooms
    structuresFound = room.find FIND_MY_STRUCTURES,
                                filter: (s) => s.energy < s.energyCapacity and \
                                                          s.structureType in [STRUCTURE_EXTENSION, STRUCTURE_SPAWN]
    if room.storage? and not structuresFound.length
      structuresFound = [room.storage]
    structures.push(structuresFound...) if structuresFound?
  structureLocations = map structures, (s) => pos: s.pos, range: 1
  path = getPath unit.pos, structureLocations
  if path.length
    moveBy path, unit
  else
    unit.transfer unit.pos.findClosestByRange(structures), RESOURCE_ENERGY

collect = (unit) ->
  resources = []
  for room in values rooms
    resourcesFound = room.find FIND_DROPPED_RESOURCES,
                               filter: (r) => r.resourceType is RESOURCE_ENERGY
    containersFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType is STRUCTURE_CONTAINER
    resources.push(resourcesFound...) if resourcesFound?
    resources.push(containersFound...) if containersFound?
  prioritized = resources.sort((a, b) => (if b.amount? then b.amount else b.store[RESOURCE_ENERGY]) - \
                                         (if a.amount? then a.amount else a.store[RESOURCE_ENERGY])) \
                         .slice(0, Math.floor(Math.sqrt(resources.length)))
  prioritizedLocations = map prioritized, (p) => pos: p.pos, range: 1
  path = getPath unit.pos, prioritizedLocations
  if path.length > 0
    moveBy path, unit
  else
    target = unit.pos.findClosestByRange(prioritized)
    if unit.pickup(target) is OK or unit.withdraw(target, RESOURCE_ENERGY) is OK
      unit.memory.working = true

build = (unit) ->
  sites = []
  for room in values rooms
    sitesFound = room.find FIND_MY_CONSTRUCTION_SITES
    sites.push(sitesFound...) if sitesFound?
  return false if not sites.length
  siteLocations = map sites, (s) => pos: s.pos, range: 3
  path = getPath unit.pos, siteLocations
  if path.length
    moveBy path, unit
  else
    unit.build unit.pos.findClosestByRange sites
  return true

resupply = (unit) ->
  resources = []
  for room in values rooms
    droppedFound = room.find FIND_DROPPED_RESOURCES,
                             filter: (r) => r.amount >= unit.store.getCapacity(RESOURCE_ENERGY) and \
                                            r.resourceType is RESOURCE_ENERGY
    storesFound = room.find FIND_STRUCTURES,
                            filter: (s) => (s.structureType is STRUCTURE_CONTAINER or
                                            s.structureType is STRUCTURE_STORAGE) and \
                                            s.store[RESOURCE_ENERGY] >= unit.store.getCapacity(RESOURCE_ENERGY)
    resources.push(droppedFound...) if droppedFound?
    resources.push(storesFound...) if storesFound?

  resourceLocations = map resources, (r) => pos: r.pos, range: 1
  path = getPath unit.pos, resourceLocations
  if path.length
    moveBy path, unit
  else
    target = unit.pos.findClosestByRange resources, RESOURCE_ENERGY
    if unit.pickup(target) is OK or unit.withdraw(target, RESOURCE_ENERGY) is OK
      unit.memory.working = true

repairStructureUrgent = (unit) ->
  structures = []
  for room in values rooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.structureType isnt STRUCTURE_WALL and \
                                             ((s.hits < s.hitsMax and s.hits < 1500) or
                                              (s.structureType is STRUCTURE_CONTAINER and s.hits < 50000))
    structures.push(structuresFound...) if structuresFound?
  return false if not structures.length
  structureLocations = map structures, ((s) => pos: s.pos, range: 3)
  path = getPath unit.pos, structureLocations
  if path.length
    moveBy path, unit
  else
    if prioritized.length
      unit.repair unit.pos.findInRange(prioritized, 3)[0]
    else
      prioritizedLocations = map prioritized, (p) => pos: p.pos, range: 1
      path = getPath unit.pos, prioritizedLocations
      moveBy path, unit
  return true

repairStructureNonUrgent = (unit) ->
  structures = []
  for room in values rooms
    structuresFound = room.find FIND_STRUCTURES,
                                filter: (s) => s.hits < s.hitsMax
    structures.push(structuresFound...) if structuresFound?

  return false if not structures.length
  prioritized = structures.sort((a, b) => a.hits - b.hits) \
                         .slice(0, Math.floor(Math.sqrt(structures.length)))
  prioritizedLocations = map prioritized, (p) => pos: p.pos, range: 3
  path = getPath unit.pos, prioritizedLocations
  if path.length
    moveBy path, unit
  else
    if prioritized.length
      unit.repair unit.pos.findInRange(prioritized, 3)[0]
    else
      prioritizedLocations = map prioritized, (p) => pos: p.pos, range: 1
      path = getPath unit.pos, prioritizedLocations
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
  if path.length
    moveBy path, unit
  else
    unit.transfer unit.pos.findClosestByRange(towers), RESOURCE_ENERGY
  return true

reserve = (unit) ->
  targetRoom = Game.flags['reserve'].pos.roomName
  if unit.room.name isnt targetRoom
    exit = unit.pos.findClosestByPath unit.room.findExitTo(targetRoom)
    moveTo exit, unit
  else
    controller = Game.rooms[targetRoom].controller
    if unit.reserveController(controller) == ERR_NOT_IN_RANGE
      moveTo controller, unit

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

moveTo = (location, unit) ->
  unit.moveTo location, reusePath: 5, maxRooms: 1, visualizePathStyle:
                                                     fill: 'transparent',
                                                     stroke: '#ffaa00',
                                                     lineStyle: 'dashed',
                                                     strokeWidth: .15,
                                                     opacity: .1

moveBy = (path, unit) ->
  unit.moveByPath path

getPath = (pos, loc) ->
  PathFinder.search(pos, loc, plainCost: 2, swampCost: 10, roomCallback: generateCostMatrix).path

getPathCost = (pos, loc) ->
  PathFinder.search(pos, loc, plainCost: 2, swampCost: 10, roomCallback: generateCostMatrix).cost

generateCostMatrix = (roomName) ->
  room = Game.rooms[roomName]
  return if not room?
  costs = new PathFinder.CostMatrix

  forEach room.find(FIND_STRUCTURES), (s) ->
    if s.structureType is STRUCTURE_ROAD
      costs.set s.pos.x, s.pos.y, 1
    else if s.structureType isnt STRUCTURE_CONTAINER and
           (s.structureType isnt STRUCTURE_RAMPART or not s.my)
      costs.set s.pos.x, s.pos.y, 0xff

  forEach room.find(FIND_CONSTRUCTION_SITES), (s) ->
    if s.structureType isnt STRUCTURE_ROAD and \
       s.structureType isnt STRUCTURE_CONTAINER and \
      (s.structureType isnt STRUCTURE_RAMPART or not s.my)
      costs.set s.pos.x, s.pos.y, 0xff

  forEach room.find(FIND_CREEPS), (c) ->
    costs.set c.pos.x, c.pos.y, 0xff

  return costs

module.exports = { upgrade, harvest, transfer, build,
                   repairStructureUrgent, repairStructureNonUrgent,
                   refillTower, shouldWork, moveTo, resupply,
                   collect, claim, reserve, invade }
