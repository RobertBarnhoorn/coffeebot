_flags = Game.flags

# List of all flags
flags = _flags

flag_intents =
  INVADE:  COLOR_RED
  ATTACK:  COLOR_ORANGE
  PATROL:  COLOR_YELLOW
  DEFEND:  COLOR_GREEN
  RESERVE: COLOR_BLUE
  CLAIM:   COLOR_PURPLE
  GARRISON: COLOR_CYAN

module.exports = { flags, flag_intents }
