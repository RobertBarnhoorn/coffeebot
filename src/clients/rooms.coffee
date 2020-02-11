_rooms = Game.rooms

# List of all visible rooms
rooms = _rooms

# Get specific room oy name
room = (r) -> _rooms[r]

# Check the visibility of a room
roomVisible = (r) -> _rooms[u]?

module.exports = { rooms, room, roomVisible }
