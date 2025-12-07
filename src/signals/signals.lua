
local Connection = {}
local Signal = {}

local function createConnection(_, signal, callback, once)
    local conn = setmetatable({
        signal = signal,
        callback = callback,
        once = once
    }, {__index=Connection})

    signal.connections[conn] = conn

    return conn
end

local function createSignal()
    return setmetatable({
        connections = {}
    }, {__index=Signal})
end

setmetatable(Connection, {__call = createConnection})
setmetatable(Signal, {__call = createSignal})

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

return {
    new = createSignal
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