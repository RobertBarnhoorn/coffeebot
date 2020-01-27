{ roles } = require 'unit_roles'
{ units } = require 'units'
{ harvester, upgrader, engineer } = require 'unit_behaviours'

unitManagement = ->
  for _,unit of units
    switch unit.memory.role
      when roles.UPGRADER then upgrader unit
      when roles.HARVESTER then harvester unit
      when roles.ENGINEER then engineer unit

module.exports = { unitManagement }
