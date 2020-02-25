{ forEach } = require 'lodash'
{ rooms } = require 'rooms'

moveTo = (location, unit) ->
  unit.moveTo location, reusePath: 5, maxRooms: 1, visualizePathStyle:
                                                     fill: 'transparent',
                                                     stroke: '#ffaa00',
                                                     lineStyle: 'dashed',
                                                     strokeWidth: .15,
                                                     opacity: .1

moveBy = (path, unit) ->
  unit.room.visual.poly (p for p in path.path when p.roomName is unit.room.name)
  unit.moveByPath path.path

getPath = (pos, loc) ->
  PathFinder.search pos, loc, plainCost: 2, swampCost: 10, roomCallback: generateCostMatrix, maxOps: 2000

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

module.exports = { moveTo, moveBy, getPath }
