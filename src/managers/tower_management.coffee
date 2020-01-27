{ defender, healer, repairer } = require 'tower_behaviours'
{ filter } = require 'lodash'

towerManagement = ->
  towers = filter(Game.structures, (s) => s.structureType is STRUCTURE_TOWER)
  for tower in towers
    defender(tower) or healer(tower) or repairer(tower)

module.exports = { towerManagement }
