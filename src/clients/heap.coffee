# Various heap statistics for your VM
_heap = -> Game.cpu.getHeapStatistics()

totalHeapSize           = _heap['total_heap_size']
totalHeapSizeExecutable = _heap['total_heap_size_executable']
totalPhysicalSize       = _heap['total_physical_size']
totalAvailableSize      = _heap['total_available_size']
usedHeapSize            = _heap['used_heap_size']
heapSizeLimit           = _heap['heap_size_limit']
mallocedMemory          = _heap['malloced_memory']
peakMallocedMemory      = _heap['peak_malloced_memory']
doesZapGarbage          = _heap['does_zap_garbage']
externallyAllocatedSize = _heap['externally_allocated_size']

module.exports = { totalHeapSize, totalHeapSizeExecutable, totalPhysicalSize,
                   totalAvailableSize, usedHeapSize, heapSizeLimit,
                   mallocedMemory, peakMallocedMemory, doesZapGarbage,
                   externallyAllocatedSize }
