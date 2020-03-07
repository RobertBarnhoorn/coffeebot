{ forEach } = require 'lodash'
{ rooms } = require 'rooms'
{ cpuUsed } = require 'cpu'

costMatrices = {}

moveTo = (location, unit) ->
  unit.moveTo location, reusePath: 5, maxRooms: 1, visualizePathStyle:
                                                     fill: 'transparent',
                                                     stroke: '#ffaa00',
                                                     lineStyle: 'dashed',
                                                     strokeWidth: .15,
                                                     opacity: .1

goTo = (location, unit) ->
  cachedPrevPrevLoc = if unit.memory.prevLoc then unit.memory.prevLoc else unit.pos
  prevPrevLoc = new RoomPosition(cachedPrevPrevLoc.x, cachedPrevPrevLoc.y, cachedPrevPrevLoc.roomName)
  cachedPrevLoc = if unit.memory.loc? then unit.memory.loc else unit.pos
  prevLoc = new RoomPosition(cachedPrevLoc.x, cachedPrevLoc.y, cachedPrevLoc.roomName)
  currLoc = unit.pos
  # Resolve stuck units
  if unit.fatigue is 0 and (currLoc.isEqualTo(prevLoc) or currLoc.isEqualTo(prevPrevLoc))
    if unit.memory.stuck
      path = getPath unit.pos, location, withUnits=true
    else
      unit.memory.stuck = true
  else
    unit.memory.stuck = false

  path or= getPath unit.pos, location
  moveBy path, unit
  unit.memory.prevLoc = prevLoc
  unit.memory.loc = currLoc

moveBy = (path, unit) ->
  unit.room.visual.poly (p for p in path.path when p.roomName is unit.room.name)
  unit.moveByPath path.path

getPath = (pos, loc, withUnits=false) ->
  if withUnits
    PathFinder.search pos, loc, plainCost: 2, swampCost: 10, roomCallback: generateCostMatrixWithUnits, maxOps: 5000
  else
    PathFinder.search pos, loc, plainCost: 2, swampCost: 10, roomCallback: getCostMatrix, maxOps: 5000

getCostMatrix = (roomName) ->
  costMatrix = costMatrices[roomName]
  return costMatrix if costMatrix?

  room = Game.rooms[roomName]
  return if not room?

  if room.memory.ttl > 0
    room.memory.ttl -= 1
    costMatrix = PathFinder.CostMatrix.deserialize(room.memory.costMatrix)
    costMatrices[room.name] = costMatrix
    return costMatrix

  room.memory.ttl = 25
  costMatrix = generateCostMatrix roomName
  room.memory.costMatrix = costMatrix.serialize()
  costMatrices[room.name] = costMatrix
  return costMatrix

generateCostMatrixWithUnits = (roomName) -> generateCostMatrix(roomName, withUnits=true)

generateCostMatrix = (roomName, withUnits=false) ->
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

  if withUnits
    forEach room.find(FIND_CREEPS), (c) ->
      costs.set c.pos.x, c.pos.y, 0xff

  return costs

module.exports = { moveTo, moveBy, goTo, getPath }
