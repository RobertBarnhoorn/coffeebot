{ defender, healer, repairer } = require 'tower_behaviours'
{ filter } = require 'lodash'

towerManagement = ->
  towers = filter Game.structures, (s) => s.structureType is STRUCTURE_TOWER
  for tower of towers
    defender tower is OK or healer tower is OK or repairer tower is OK

module.exports = { towerManagement }
