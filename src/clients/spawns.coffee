_spawns = Game.spawns

# Get spawn by name
spawn = (s) -> _spawns[s]

spawnUnit = (s, role) ->
  body = [WORK, WORK, WORK, WORK, CARRY, CARRY, CARRY, MOVE, MOVE, MOVE]
  name = role + '_' + Game.time
  return (spawn s) .spawnCreep body,
                               name,
                               memory:
                                 role: role,
                                 working: false

module.exports = { spawn, spawnUnit }
