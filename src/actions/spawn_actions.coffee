{ spawn } = require 'spawns'

spawnUnit = (s, role, body, memory) ->
  name = role + '_' + Game.time
  canSpawn = (spawn s).spawnCreep(body, name, dryRun: true)
  if canSpawn is OK
    return (spawn s).spawnCreep(body, name, memory: memory)
  return canSpawn

module.exports = { spawnUnit }
