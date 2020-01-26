{ roles } = require 'unit_roles'
{ units } = require 'units'
{ harvester, upgrader, builder, repairer } = require 'unit_behaviours'

unitManagement = ->
  for _,unit of units
    switch unit.memory.role
      when roles.UPGRADER then upgrader unit
      when roles.HARVESTER then harvester unit
      when roles.BUILDER then builder unit
      when roles.REPAIRER then repairer unit

module.exports = { unitManagement }
