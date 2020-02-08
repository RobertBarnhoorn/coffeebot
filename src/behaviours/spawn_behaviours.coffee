{ roles } = require 'unit_roles'
{ spawn } = require 'spawns'
{ spawnUnit } = require 'spawn_actions'

maxEnergy = (s) -> (spawn s).room.energyAvailable

minEnergy = (s) -> (spawn s).room.energyAvailable * 0.3

generateUnit = (s, role) ->
  switch role
    when roles.HARVESTER then spawnHarvester s
    when roles.TRANSPORTER then spawnTransporter s
    when roles.UPGRADER then spawnUpgrader s
    when roles.ENGINEER then spawnEngineer s
    when roles.SOLDIER then spawnSoldier s
    when roles.HEALER then spawnHealer s

spawnEngineer = (s) ->
  role = roles.ENGINEER
  energy = maxEnergy(s)
  body = []
  loop
    energy = putBodyPart(s, body, MOVE, energy)
    break if energy < minEnergy(s)
    energy = putBodyPart(s, body, WORK, energy)
    break if energy < minEnergy(s)
    energy = putBodyPart(s, body, CARRY, energy)
    break if energy < minEnergy(s)

  memory =
    role: role
    working: false
  spawnUnit(s, role, body, memory) if body.length >= 3

spawnHarvester = (s) ->
  role = roles.HARVESTER
  energy = maxEnergy(s)
  body = []
  energy = putBodyPart(s, body, MOVE, energy)
  loop
    energy = putBodyPart(s, body, WORK, energy)
    break if energy < minEnergy(s) or body.length > 5

  memory =
    role: role
    working: false
  spawnUnit(s, role, body, memory) if body.length >= 2

spawnTransporter = (s) ->
  role = roles.TRANSPORTER
  energy = maxEnergy(s)
  body = []
  loop
    energy = putBodyPart(s, body, MOVE, energy)
    break if energy < minEnergy(s)
    energy = putBodyPart(s, body, CARRY, energy)
    break if energy < minEnergy(s)
    energy = putBodyPart(s, body, CARRY, energy)
    break if energy < minEnergy(s)

  memory =
    role: role
    working: false
  spawnUnit(s, role, body, memory) if body.length >= 2

spawnUpgrader = (s) ->
  role = roles.UPGRADER
  energy = maxEnergy(s)
  body = []
  energy = putBodyPart(s, body, MOVE, energy)
  energy = putBodyPart(s, body, CARRY, energy)
  loop
    energy = putBodyPart(s, body, WORK, energy)
    break if energy < minEnergy(s) or body.length >= 12

  memory =
    role: role
    working: false
  spawnUnit(s, role, body, memory) if body.length >= 3

spawnSoldier = (s) ->
  role = roles.SOLDIER
  energy = maxEnergy(s)
  body = [TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH,
          TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH,
          TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH,
          TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH,
          MOVE, MOVE, MOVE, MOVE, MOVE, ATTACK, ATTACK, ATTACK, ATTACK, ATTACK]

  memory =
    role: role
    working: false

  spawnUnit(s, role, body, memory)

spawnHealer = (s) ->
  role = roles.HEALER
  energy = maxEnergy(s)
  body = [TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH,
          TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH,
          TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH,
          TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH, TOUGH,
          MOVE, MOVE, MOVE, MOVE, MOVE, HEAL, HEAL, HEAL, HEAL, HEAL]

  memory =
    role: role
    working: false

  spawnUnit(s, role, body, memory)

putBodyPart = (s, body, part, energy) ->
  energy -= BODYPART_COST[part]
  body.push part unless energy < minEnergy(s)
  return energy

module.exports = { generateUnit }
