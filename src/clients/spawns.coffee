_spawns = Game.spawns

# Get all spawns
spawns = _spawns

# Get spawn by name
spawn = (s) -> _spawns[s]

module.exports = { spawns, spawn }
