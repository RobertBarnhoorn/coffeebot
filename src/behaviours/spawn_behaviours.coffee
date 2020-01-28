{ roles } = require 'unit_roles'
{ spawn } = require 'spawns'
{ spawnUnit } = require 'spawn_actions'

generateUnit = (s, role) ->
  switch role
    when roles.HARVESTER then spawnHarvester s
    when roles.TRANSPORTER then spawnTransporter s
    else spawnBalancedUnit s, role

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

  spawnUnit(s, role, body) if body.length >= 3

spawnHarvester = (s) ->
  role = roles.HARVESTER
  energy = (spawn s).room.energyAvailable
  body = []
  energy = putBodyPart(body, MOVE, energy)
  loop
    energy = putBodyPart(body, WORK, energy)
    break if energy < 0 or body.length > 5

  spawnUnit(s, role, body) if body.length >= 2

spawnTransporter = (s) ->
  role = roles.TRANSPORTER
  energy = (spawn s).room.energyAvailable
  body = []
  loop
    energy = putBodyPart(body, MOVE, energy)
    break if energy < 0
    energy = putBodyPart(body, CARRY, energy)
    break if energy < 0

  spawnUnit(s, role, body) if body.length >= 2

putBodyPart = (body, part, energy) ->
  energy -= BODYPART_COST[part]
  body.push part unless energy < 0
  return energy

module.exports = { generateUnit }
