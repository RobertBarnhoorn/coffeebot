{ shuffle, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ harvester, upgrader, repairer, fortifier, builder, transporter, reserver, claimer, militant } = require 'unit_behaviours'

unitManagement = ->
  for u in shuffle values units
    switch u.memory.role
        when roles.UPGRADER then upgrader u
        when roles.HARVESTER then harvester u
        when roles.REPAIRER then repairer u
        when roles.FORTIFIER then fortifier u
        when roles.BUILDER then builder u
        when roles.TRANSPORTER then transporter u
        when roles.RESERVER then reserver u
        when roles.CLAIMER then claimer u
        when roles.SOLDIER then militant u
        when roles.SNIPER then militant u
        when roles.MEDIC then militant u

module.exports = { unitManagement }
