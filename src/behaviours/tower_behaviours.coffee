{ filter } = require 'lodash'

defender = (tower) ->
  target = tower.pos.findClosestByRange FIND_HOSTILE_CREEPS
  tower.attack target if target?

healer = (tower) ->
  target = filter tower.pos.findClosestByRange(FIND_MY_CREEPS), (u) => u.hits < u.hitsMax
  tower.heal target if target?

repairer = (tower) ->
  target = filter tower.pos.findClosestByRange(FIND_MY_STRUCTURES), (u) => u.hits < u.hitsMax
  tower.repair target if target?

module.exports = { defender, healer, repairer }
