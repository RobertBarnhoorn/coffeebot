{ roles } = require 'unit_roles'
{ spawn } = require 'spawns'
{ spawnUnit } = require 'spawn_actions'

spawnBalancedUnit = (s, role) ->
  energy = (spawn s).room.energyAvailable
  body = []
  loop
    energy = putBodyPart(body, MOVE, energy)
    break if energy < 0
    energy = putBodyPart(body, WORK, energy)
    break if energy < 0
    energy = putBodyPart(body, CARRY, energy)
    break if energy < 0

  spawnUnit s, role, body if body.length >= 3

putBodyPart = (body, part, energy) ->
  energy -= BODYPART_COST[part]
  body.push part unless energy < 0
  return energy

module.exports = { spawnBalancedUnit }
