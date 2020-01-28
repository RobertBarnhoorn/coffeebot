{ defender, healer } = require 'tower_behaviours'
{ filter } = require 'lodash'

towerManagement = ->
  towers = filter(Game.structures, (s) => s.structureType is STRUCTURE_TOWER)
  for tower in towers
    defender(tower) or healer(tower)

module.exports = { towerManagement }
