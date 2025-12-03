
-- (256 tasks max)

task = {}

function task.spawn(callback)
    assert(type(callback) == "function", "bad argument #1 'spawn' (function expected, got "..type(callback)..")")
    
    local addr = tostring(callback)
    task[addr] = callback
    os.queueEvent('task_create', addr)
    return addr
end

function task.clock()
    return os.epoch('local') / 1000
end

function task.wait(duration)
    assert(type(duration) == "number", "bad argument #1 'wait' (number expected, got "..type(duration)..")")
    
    local start = task.clock()
    
    if duration > 0.05 then
        sleep(duration - 0.05)
    end

    repeat
        os.queueEvent('task_wait')
        os.pullEvent('task_wait')
    until (task.clock() - start) > duration
end

function task.cancel(addr)
    assert(type(addr) == "string", "bad argument #1 'cancel' (string expected, got "..type(addr)..")")
    
    os.queueEvent('task_cancel', addr)
end

local function run(addr)
    local fun = task[addr]
    if not fun then return end

    parallel.waitForAny(fun, function () -- main & cancel
        local _, cancelled
        repeat _, cancelled = os.pullEvent('task_cancel')
        until cancelled == addr
    end)
end

function task.run()
    local function listen()
        local event, addr = os.pullEvent('task_create')
        
        parallel.waitForAll(listen,
        function() run(addr) end)
    end

    listen()
end

return task