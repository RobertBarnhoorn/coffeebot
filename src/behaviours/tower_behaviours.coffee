defender = (tower) ->
  target = tower.pos.findClosestByRange FIND_HOSTILE_CREEPS
  if target?
    tower.attack target
    return true
  return false

healer = (tower) ->
  target = tower.pos.findClosestByRange FIND_MY_CREEPS, filter: (u) => u.hits < u.hitsMax
  if target?
    tower.heal target
    return true
  return false

repairer = (tower) ->
  target = tower.pos.findClosestByRange FIND_MY_STRUCTURES, filter: (s) => s.hits < s.hitsMax
  if target?
    tower.repair target
    return true
  return false

module.exports = { defender, healer, repairer }
