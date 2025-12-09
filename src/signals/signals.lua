
local Connection = {}
local Signal = {}

local signals = {}

local function createConnection(_, signal, callback, once)
    local conn = setmetatable({
        signal = signal,
        callback = callback,
        once = once
    }, {__index=Connection})

    signal.connections[conn] = conn

    return conn
end

local function createSignal(name)
    local signal = setmetatable({
        connections = {},
        name = name
    }, {__index=Signal})
    
    signals[name or signal] = signal
    return signal
end

setmetatable(Connection, {__call = createConnection})

function Connection:Disconnect()
    self.signal.connections[self] = nil
end

function Signal:Connect(callback)
    return Connection(self, callback)
end

function Signal:ConnectOnce(callback)
    return Connection(self, callback, true)
end

function Signal:Fire(...)
    for _, conn in pairs(self.connections) do
        conn.callback(...)
        if conn.once then
            conn:Disconnect()
        end
    end
end

local function getSignals()
    return signals
end

local function disconnectSignal(signal)
    for _, conn in pairs(signal.connections) do
        conn:Disconnect()
    end
    
    signal[signal.name or signal] = nil
end

return {
    new = createSignal,
    getSignals = getSignals,
    disconnectSignal = disconnectSignal
}

--[[

{
.new()
    signal
        :Connect(callback)
            connection
                :Disconnect()
            
        :ConnectOnce(callback)
            connection
                :Disconnect()

        :Fire(...)
}

]]