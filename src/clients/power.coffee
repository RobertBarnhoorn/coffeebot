_gpl = Game.gpl

# Current Global Control Level
gplLevel    = _gpl.level
#pControl Points towards next level
gplProgress = _gpl.progress
#pControl Points needed to reach next level
gplNeeded   = _gpl.progressTotal

module.exports = { gplLevel, gplProgress, gplNeeded }
