# A cpu limit of x represents x ms of execution time
# Non-subscription limit: 20
# Subscription limit: 10*GCL up to a maximum of 300
# The bucket can accumulate up to 10 000 cpu
# You can use up to 500 cpu from the bucket each tick
_cpu = Game.cpu

# Assigned CPU limit for the current shard
cpuLimit = _cpu['limit']

# Available CPU time at the current game tick
cpuTickLimit = _cpu['tickLimit']

# Unused CPU accumulated in your bucket
cpuBucket = _cpu['bucket']

cpuUsed = -> Game.cpu.getUsed()

module.exports = { cpuLimit, cpuTickLimit, cpuBucket, cpuUsed }
