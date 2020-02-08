{ roles } = require 'unit_roles'
{ units } = require 'units'
{ harvester, upgrader, engineer, transporter, soldier } = require 'unit_behaviours'

unitManagement = ->
  for _,unit of units
    switch unit.memory.role
      when roles.UPGRADER then upgrader unit
      when roles.HARVESTER then harvester unit
      when roles.ENGINEER then engineer unit
      when roles.TRANSPORTER then transporter unit
      when roles.SOLDIER then soldier unit

module.exports = { unitManagement }
