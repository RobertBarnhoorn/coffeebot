{ any, filter, includes, map, random, some, values } = require 'lodash'
{ flags, flag_intents } = require 'flags'
{ rooms } = require 'rooms'
{ MYSELF } = require 'constants'

flagManagement = ->
  do placeDefensiveFlags
  do deleteOldFlags

placeDefensiveFlags = ->
  # Place defensive flags in our rooms where there are hostiles present
  return if any (f.color is flag_intents.DEFEND for f in values flags)

  for r in values(rooms) when r.controller?.my or r.controller?.reservation?.username is MYSELF
    if r.find(FIND_HOSTILE_CREEPS).length or r.find(FIND_HOSTILE_STRUCTURES).length
      r.createFlag(25, 25, 'defend', flag_intents.DEFEND)
      break

deleteOldFlags = ->
  for f in values flags
    # Remove defensive flag if hostiles have been dispensed
    if f.color is flag_intents.DEFEND and f.room? and not f.room.find(FIND_HOSTILE_CREEPS).length
      f.remove()

module.exports = { flagManagement }
