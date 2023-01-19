---@class Benchmark
local Benchmark = {}

-- Runs a function n times and returns the elapsed time in seconds
---@return number
function Benchmark.Run(n, func)
    local startTime = os.clock()
    for _ = 1, n do
        func()
    end
    local endTime = os.clock()
    local elapsedTime = endTime - startTime
    return elapsedTime
end

return Benchmark
