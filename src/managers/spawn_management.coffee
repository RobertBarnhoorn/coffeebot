{ countBy, merge, values } = require 'lodash'
{ readMem, writeMem } = require 'memory'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ spawnBalancedUnit } = require 'spawn_behaviours'

SPAWN = 'Spawn1'
desired = (role) ->
  switch role
    when roles.HARVESTER then 2
    when roles.UPGRADER then 2
    when roles.BUILDER then 2
    when roles.REPAIRER then 1
    else 1

populationControl = ->
  # Count the actual populations by role
  actual = {}
  actual[v] = 0 for v in values roles
  merge actual, countBy(units, 'memory.role')
  # Filter out roles that are at desired capacity
  candidates = (role for role,count of actual when count < desired role)
  spawnBalancedUnit SPAWN, candidates[0] if candidates.length

module.exports = { populationControl }
