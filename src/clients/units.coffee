_units = Game.creeps

# List of all units
units = _units

# Get specific unit by name
unit = (u) -> _units[u]

# Check the existence of a unit
unitExists = (u) -> _units[u]?

module.exports = { units, unit, unitExists }
