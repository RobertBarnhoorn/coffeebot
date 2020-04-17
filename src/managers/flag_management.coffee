{ any, filter, includes, map, random, some, values } = require 'lodash'
{ flags, flag_intents } = require 'flags'
{ rooms } = require 'rooms'
{ MYSELF } = require 'constants'

flagManagement = ->
  flag = flags['defend']
  if flag?.memory['ttl'] > 0
    flag.memory['ttl'] -= 1
    return

  do deleteOldFlags
  do placeDefensiveFlags

placeDefensiveFlags = ->
  for r in values(rooms) when r.controller?.my or r.controller?.reservation?.username is MYSELF
    # Place defensive flags in our rooms where there are hostiles present
    if (filter r.find(FIND_HOSTILE_CREEPS),
               ((c) -> some([ATTACK, RANGED_ATTACK],
                           (p) -> includes(map(c.body,
                                              (b) -> b.type), p)))
       ).length or r.find(FIND_HOSTILE_STRUCTURES).length
      r.createFlag(25, 25, 'defend', flag_intents.DEFEND)
      flags['defend'].memory['ttl'] = 25
      break

deleteOldFlags = ->
  # Remove defensive flag if hostiles have been dispensed
  flag = flags['defend']
  if flag? and flag.room? and not flag.room.find(FIND_HOSTILE_CREEPS).length
    flag.remove()

module.exports = { flagManagement }
