{ includes, map, some, values } = require 'lodash'
{ flags, flag_intents } = require 'flags'
{ rooms } = require 'rooms'
{ MYSELF } = require 'constants'

flagManagement = ->
  do placeDefensiveFlags
  do deleteOldFlags

placeDefensiveFlags = ->
  parts = [ATTACK, RANGED_ATTACK]
  for r in values(rooms) when r.controller?.my or r.controller?.reservation?.username is MYSELF
    if (r.find FIND_HOSTILE_CREEPS,
               filter: (c) => some(parts, (p) => includes(map(c.body, (b) => b.type), p))).length
      r.createFlag(25, 25, 'defend', flag_intents.DEFEND)

deleteOldFlags = ->
  for f in values flags
    if f.color is flag_intents.DEFEND and not f.room.find(FIND_HOSTILE_CREEPS).length
      f.remove()

module.exports = { flagManagement }
