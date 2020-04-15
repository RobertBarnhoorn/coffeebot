{ find, filter, forEach, last, map } = require 'lodash'
{ rooms } = require 'rooms'
{ roomsMem} = require 'memory'

moveTo = (location, unit) ->
  unit.moveTo location, reusePath: 5, maxRooms: 1, visualizePathStyle:
                                                     fill: 'transparent',
                                                     stroke: '#ffaa00',
                                                     lineStyle: 'dashed',
                                                     strokeWidth: .15,
                                                     opacity: .1

goTo = (location, unit) ->
  # Initialise the paths object if a global reset has occurred
  if not global.paths?
    global.paths = {}

  prevLoc = unit.memory.prevLoc ? {x: unit.pos.x, y: unit.pos.y}
  prevPrevLoc = unit.memory.prevPrevLoc ? {x: unit.pos.x, y: unit.pos.y}

  pathChanged = false

  # If the target destination has changed we need to recalculate the path
  prevDest = unit.memory.prevDest ? {x: location.pos.x, y: location.pos.y, range: location.range}
  if prevDest.x isnt location.pos.x or prevDest.y isnt location.pos.y or prevDest.range isnt location.range
    path = getPath(unit.pos, location).path
    pathChanged = true
  # If the unit is stuck we need to help it dodge the obstacle
  else if unit.pos.isEqualTo prevPrevLoc.x, prevPrevLoc.y
    avoid = filter unit.pos.findInRange(FIND_CREEPS, 1), ((u) -> u != unit)
    path = getPath(unit.pos, location, avoid=avoid).path
    pathChanged = true

  # See if the path is cached in the global object
  path or= global.paths[unit.name]
  # See if the path is cached in memory and deserialize it
  path or= deserializePath unit.memory.path

  # The path is not cached at all so calculate it and cache it
  if not path?
    path = getPath(unit.pos, location).path
    pathChanged = true

  moveBy path, unit

  # Cache the new path
  if pathChanged
    global.paths[unit.name] = path
    unit.memory.path = serializePath path

  # Store relevant coordinates for next tick
  unit.memory.prevPrevLoc = x: prevLoc.x, y: prevLoc.y
  unit.memory.prevLoc = x: unit.pos.x, y: unit.pos.y
  unit.memory.prevDest = x: location.pos.x, y: location.pos.y, range: location.range

moveBy = (path, unit) ->
  unit.moveByPath(path)

# Find the closest of a list of targets by path
getClosest = (entity, targets) ->
  closest = undefined
  locations = map targets, ((t) -> pos: t.pos, range: 1)
  path = PathFinder.search entity.pos, locations, plainCost: 2, swampCost: 10, roomCallback: getCostMatrix, maxOps: 100000
  if path.path.length
    # Our destination is the last position of the path
    destination = last(path.path)
  else
    # We are already at the destination
    destination = entity.pos

  target = find targets, ((t) -> t.pos.inRangeTo(destination, 1))
  if not target?
    return undefined

  closest = id: target.id, cost: path.cost
  return closest

# Find the optimal path from pos to loc, potentially across multiple rooms
# If loc is an array of locations find the path to closest loc
getPath = (pos, loc, avoid=null) ->
  PathFinder.search pos, loc, plainCost: 2, swampCost: 10, roomCallback: ((roomName) -> getCostMatrix(roomName, avoid)), maxOps: 100000

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

getCostMatrix = (roomName, avoid=null) ->
  # Initialise the matrices object if a global reset has occurred
  if not global.matrices?
    global.matrices = {}

  # Make sure memory space has been assigned for the room
  if not roomsMem[roomName]?
    roomsMem[roomName] = {}

  # Generate a new costMatrix if the Matrix isn't in cache or the cache entry is stale 
  if not roomsMem[roomName]['ttl']? or roomsMem[roomName]['ttl'] <= 0
    costs = generateCostMatrix roomName, avoid
    return null if not costs?
    global.matrices[roomName] = costs
    roomsMem[roomName]['costs'] = costs.serialize()
    roomsMem[roomName]['ttl'] = 200
  else
    roomsMem[roomName]['ttl'] -= 1

  costs = global.matrices[roomName]

  # Global cache miss so take from memory
  if not costs?
    costs = PathFinder.CostMatrix.deserialize roomsMem[roomName]['costs']
    global.matrices[roomName] = costs

  # Pathfind around anything in this list (usually other units)
  if avoid?
    clone = costs.clone()
    forEach avoid, ((a) -> clone.set a.pos.x, a.pos.y, 0xff)
    return clone

  return costs

generateCostMatrix = (roomName) ->
  room = Game.rooms[roomName]
  return null if not room?

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

  return costs

module.exports = { moveTo, moveBy, goTo, getPath, getClosest }
