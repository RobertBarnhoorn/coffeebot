{ spawn } = require 'spawns'

spawnUnit = (s, role, body) ->
  name = role + '_' + Game.time
  return (spawn s) .spawnCreep body,
                               name,
                               memory:
                                 role: role,
                                 working: false

module.exports = { spawnUnit }
