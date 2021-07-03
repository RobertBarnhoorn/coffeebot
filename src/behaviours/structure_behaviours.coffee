defenderTower = (tower) ->
  target = tower.pos.findClosestByRange FIND_HOSTILE_CREEPS
  if target?
    tower.attack target
    return true
  return false

healerTower = (tower) ->
  target = tower.pos.findClosestByRange FIND_MY_CREEPS, filter: (u) -> u.hits < u.hitsMax
  if target?
    tower.heal target
    return true
  return false

transferIn = (link) ->
  return false

transferOut = (link) ->
  return true

module.exports = { defenderTower, healerTower, transferIn, transferOut }
