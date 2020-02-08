{ spawn } = require 'spawns'

spawnUnit = (s, role, body, memory) ->
  name = role + '_' + Game.time
  return (spawn s) .spawnCreep body,
                               name,
                               memory: memory
module.exports = { spawnUnit }
