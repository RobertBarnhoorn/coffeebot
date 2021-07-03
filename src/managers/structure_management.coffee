{ links } = require 'unit_targeting'
{ defenderTower, healerTower, transferIn, transferOut } = require 'structure_behaviours'
{ filter } = require 'lodash'

structureManagement = ->
  do towerManagement
  do linkManagement

towerManagement = ->
  towers = filter(Game.structures, (s) -> s.structureType is STRUCTURE_TOWER)
  for tower in towers
    defenderTower(tower) or healerTower(tower)

linkManagement = ->
  for link in links
    if link.memory.taking
      transferIn link
    else if link.memory.giving
      transferOut link

module.exports = { structureManagement }
