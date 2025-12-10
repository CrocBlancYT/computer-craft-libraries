
local exception = dofile("rom/modules/main/cc/internal/tiny_require.lua")("cc.internal.exception")

local function createThread(fn, barrier_ctx)
    return { co = coroutine.create(function() return exception.try_barrier(barrier_ctx, fn) end), filter = nil }
end

local function createPool(threads)
    local event = { n = 0 }

    local function cycle()
        for i = 1, #threads do
            local thread = threads[i]
            if thread and (thread.filter == nil or thread.filter == event[1] or event[1] == "terminate") then
                local ok, param = coroutine.resume(thread.co, table.unpack(event, 1, event.n))
                
                if ok then
                    thread.filter = param
                elseif type(param) == "string" and exception.can_wrap_errors() then
                    error(exception.make_exception(param, thread.co))
                else
                    error(param, 0)
                end
                
                if coroutine.status(thread.co) == "dead" then
                    threads[i] = nil
                end
            end
        end
        
        event = table.pack(os.pullEventRaw())
    end
    
    return cycle
end

local function createHandle(fn)
    local handle = {addr = ''}
    
    function handle.fn()
        parallel.waitForAny(fn, function ()
            local _, cancelled
            repeat _, cancelled = os.pullEvent('task_cancel')
            until cancelled == handle.addr
        end)
    end
    
    return handle
end

local barrier_ctx = { co = coroutine.running() }
local threads = {}
local cycle = createPool(threads)

local insert = table.insert
local function spawn(fn)
    local handle = createHandle(fn)
    local thread = createThread(handle.fn, barrier_ctx)
    handle.addr = tostring(thread)
    insert(threads, thread)
    return thread
end

local function cancel(thread)
    os.queueEvent('task_cancel', tostring(thread))
end

local task = {active = threads}

task.spawn = spawn
task.cancel = cancel

function task.run()
    while true do
        cycle()
    end
end

function task.clock()
    return os.epoch('local') / 1000
end

function task.wait(t)
    if t > 0.05 then
        sleep(t - 0.05)
    end
    
    local start = task.clock()
    
    repeat
        os.queueEvent('task_wait')
        os.pullEvent('task_wait')
    until (task.clock() - start) > t
end

return task