# Persist arbitrary data across game ticks
# Memory can hold a maximum of 2MB stored as JSON
# Encoding: JSON.stringify
# Decoding: JSON.parse
_memory    = Memory
_rawMemory = RawMemory

TOTAL_MEM = 2048  # 2MB

# Read from a memory location
readMem = (k) -> _memory[k]

# Write to a memory location
writeMem = (k, v) -> _memory[k] = v

# Delete an element from a memory location
deleteMem = (k) -> delete _memory[k]

# Get the memory of all units
unitsMem = readMem 'creeps'

# Get the memory of a specific unit
unitMem = (u) -> unitsMem[u]

# Delete the memory of a specific unit
deleteUnitMem = (u) -> delete unitsMem[u]

# Check if a memory location holds anything
memExists = (k) -> (readMem k)?

# How much memory has been used (in Bytes)
usedMem = _rawMemory.get().length

module.exports = { readMem, writeMem, deleteMem,
                   unitsMem, unitMem, deleteUnitMem,
                   memExists, usedMem }
