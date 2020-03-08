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
  prevLoc = unit.memory.prevLoc ? {x: unit.pos.x, y: unit.pos.y}
  prevPrevLoc = unit.memory.prevPrevLoc ? {x: unit.pos.x, y: unit.pos.y}
  if unit.pos.isEqualTo(prevLoc.x, prevLoc.y) or unit.pos.isEqualTo(prevPrevLoc.x, prevPrevLoc.y)
    unit.memory.ttl -= 1
  else
    unit.memory.ttl = 3
  if unit.memory.ttl <= 0
    path = getPath(unit.pos, location, withUnits=true).path

  path or= deserializePath unit.memory.path
  if not path?
    path = getPath(unit.pos, location).path

  unit.memory.prevPrevLoc = x: prevLoc.x, y: prevLoc.y
  unit.memory.prevLoc = x: unit.pos.x, y: unit.pos.y
  moveBy path, unit
  unit.memory.path = serializePath path

moveBy = (path, unit) ->
  unit.room.visual.poly (p for p in path when p.roomName is unit.room.name)
  if unit.moveByPath(path) is OK
    path.shift()

getPath = (pos, loc, withUnits=false) ->
  if withUnits
    PathFinder.search pos, loc, plainCost: 2, swampCost: 10, roomCallback: generateCostMatrixWithUnits, maxOps: 5000
  else
    PathFinder.search pos, loc, plainCost: 2, swampCost: 10, roomCallback: getCostMatrix, maxOps: 5000

serializePath = (path) ->
  serializeRoomPos = (pos) -> pos.x + ',' + pos.y + ',' + pos.roomName
  serialized = ''
  forEach path, (p) ->
    serialized += (serializeRoomPos(p) + ' ')
  return serialized

deserializePath = (pathStr) ->
  return [] if not pathStr? or not pathStr.length
  deserialized = []
  x = ''
  y = ''
  roomName = ''
  index = 0
  forEach pathStr, (c) ->
    switch c
      when ' '
        deserialized.push(new RoomPosition(parseInt(x), parseInt(y), roomName))
        index = 0
        x = ''
        y = ''
        roomName = ''
      when ','
        index++
      else
        switch index
          when 0 then x += c
          when 1 then y += c
          when 2 then roomName += c

  return deserialized

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

  room.memory.ttl = 100
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
