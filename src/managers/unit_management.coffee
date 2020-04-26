{ forEach, shuffle, values } = require 'lodash'
{ roles } = require 'unit_roles'
{ units } = require 'units'
{ harvester, upgrader, repairer, fortifier, builder, transporter, miner, reserver, claimer, militant } = require 'unit_behaviours'

roleUsage = {}

unitManagement = ->
  roleCount = {}
  roleSum = {}

  for u in shuffle values units
    role = u.memory.role
    if role not in roleCount
      roleCount[role] = 1
      roleSum[role] = 0

    cpuBefore = Game.cpu.getUsed()

    switch role
        when roles.UPGRADER    then upgrader u
        when roles.HARVESTER   then harvester u
        when roles.REPAIRER    then repairer u
        when roles.FORTIFIER   then fortifier u
        when roles.BUILDER     then builder u
        when roles.MINER       then miner u
        when roles.TRANSPORTER then transporter u
        when roles.RESERVER    then reserver u
        when roles.CLAIMER     then claimer u
        when roles.SOLDIER     then militant u
        when roles.SNIPER      then militant u
        when roles.MEDIC       then militant u

    cpuAfter = Game.cpu.getUsed()
    cpuUsed = cpuAfter - cpuBefore
    roleCount[role] += 1
    roleSum[role] += cpuUsed

  forEach roles, (r) -> roleUsage[r] = roleSum[r] / roleCount[r]

module.exports = { unitManagement, roleUsage }
