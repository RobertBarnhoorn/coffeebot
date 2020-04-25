_gcl = Game.gcl

# Current Global Control Level
gclLevel    = _gcl.level
# Control Points towards next level
gclProgress = _gcl.progress
# Control Points needed to reach next level
gclNeeded   = _gcl.progressTotal

module.exports = { gclLevel, gclProgress, gclNeeded }
