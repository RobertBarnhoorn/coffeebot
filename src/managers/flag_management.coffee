{ filter, includes, map, some, values } = require 'lodash'
{ flags, flag_intents } = require 'flags'
{ rooms } = require 'rooms'
{ MYSELF } = require 'constants'

flagManagement = ->
  do placeDefensiveFlags
  do deleteOldFlags

placeDefensiveFlags = ->
  # Place defensive flags in our rooms where there are hostiles present
  for r in values(rooms) when r.controller?.my or r.controller?.reservation?.username is MYSELF
    if (filter (r.find FIND_HOSTILE_CREEPS),
               ((c) -> some([ATTACK, RANGED_ATTACK],
                           (p) -> includes(map(c.body,
                                              (b) -> b.type), p)))
        ).length or
       (filter r.find FIND_HOSTILE_STRUCTURES,
               ((s) -> s.structureType isnt STRUCTURE_CONTROLLER)
       ).length
      r.createFlag(25, 25, 'defend', flag_intents.DEFEND)

deleteOldFlags = ->
  for f in values flags
    # Remove defensive flag if hostiles have been dispensed
    if f.color is flag_intents.DEFEND and not (f.room?.find(FIND_HOSTILE_CREEPS).length or
                                               f.room?.find(FIND_HOSTILE_STRUCTURES).length)
      f.remove()

module.exports = { flagManagement }
