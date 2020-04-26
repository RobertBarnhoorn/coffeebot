{ cpuLimit, cpuTickLimit, cpuBucket, cpuUsed } = require 'cpu'
{ memUsed, TOTAL_MEM, MB } = require 'memory'
{ totalHeapSize, usedHeapSize } = require 'heap'
{ gclLevel, gclProgress, gclNeeded } = require 'control'
{ gplLevel, gplProgress, gplNeeded } = require 'power'

# Write metrics to a specific memory location each tick.
# An external worker reads them occasionally and forwards
# them to Grafana for plotting
emitMetrics = ->
  Memory.stats =
    # Time
    time:           Game.time
    # CPU
    cpu_used:       cpuUsed()
    cpu_limit:      cpuLimit
    cpu_tick_limit: cpuTickLimit
    cpu_bucket:     cpuBucket
    # Memory
    mem_used:       memUsed / MB
    mem_limit:      TOTAL_MEM
    # Heap
    heap_used:      usedHeapSize / MB
    heap_total:     totalHeapSize / MB
    # GCL
    gcl_level:      gclLevel
    gcl_progress:   gclProgress
    gcl_needed:     gclNeeded
    # GPL
    gpl_level:      gplLevel
    gpl_progress:   gplProgress
    gpl_needed:     gplNeeded

module.exports = { emitMetrics }
