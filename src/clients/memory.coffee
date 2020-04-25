# Persist arbitrary data across game ticks
# Memory can hold a maximum of 2MB stored as JSON
# Encoding: JSON.stringify
# Decoding: JSON.parse
_memory    = Memory
_rawMemory = RawMemory

TOTAL_MEM = 2     # MB
MB = 1000000      # Bytes in MB

# Read from a memory location
readMem = (k) -> _memory[k]

# Write to a memory location
writeMem = (k, v) -> _memory[k] = v

# Delete an element from a memory location
deleteMem = (k) -> delete _memory[k]

# Get the memory of all units
unitsMem = readMem 'creeps'

# Delete the memory of a specific unit
deleteUnitMem = (u) -> delete unitsMem[u]

# Get the memory of all rooms
roomsMem = readMem 'rooms'

# Check if a memory location holds anything
memExists = (k) -> (readMem k)?

# How much memory has been used (in Bytes)
memUsed = _rawMemory.get().length

module.exports = { readMem, writeMem, deleteMem,
                   unitsMem, deleteUnitMem, roomsMem,
                   memExists, memUsed, TOTAL_MEM, MB}
