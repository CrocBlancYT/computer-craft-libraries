
-- (256 threads max)

-- private methods

local function getRunning(id, callback)
    return function()
        parallel.waitForAny(callback, function()
            os.pullEvent('threads.stop.'..id..':'..tostring(callback))
        end)
    end
end

local function getNextCallback(id)
    local event, address = os.pullEvent('threads.start.'..id)
    local nextCallback = _G[address]
    _G[address] = nil
    return nextCallback
end

local function listen(id)
    local callback = getNextCallback(id)
    local running = getRunning(id, callback)
    local nextListen = function() listen(id) end
    
    parallel.waitForAll(running, nextListen)
end

local function stop(thread)
    assert((type(thread) == "table") and (thread.id) and (thread.callback), "bad argument #1 'thread' (table expected, got "..type(thread)..")")
    
    local id = thread.id
    local callback = thread.callback
    local address = tostring(callback)
    os.queueEvent('threads.stop.'..id..':'..address)
end

local function start(id, callback)
    local address = tostring(callback)
    _G[address] = callback
    os.queueEvent('threads.start.'..id, address)
    return {id=id, callback=callback, stop=stop}
end

-- public methods

local threads = {}

function threads.init(id)
    assert((type(id) == "string"), "bad argument #1 'id' (string expected, got "..type(id)..")")
    listen(id)
end

function threads.start(id, callback)
    assert((type(id) == "string"), "bad argument #1 'id' (string expected, got "..type(id)..")")
    assert((type(callback) == "function"), "bad argument #2 'callback' (function expected, got "..type(callback)..")")
    
    return start(id, callback)
end

return threads