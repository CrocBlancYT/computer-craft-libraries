
-- XOR symmetric encryption in Lua
local char = string.char
local byte = string.byte

local concat = table.concat
local bxor = bit.bxor

local function xor_crypt(message, key)
    local result = {}
    local key_len = #key
    
    for i = 1, #message do
        local key_byte = byte(key, (i-1)%key_len +1)
        local msg_byte = byte(message, i)
        
        local encrypted_byte = bxor(msg_byte, key_byte)

        result[i] = char(encrypted_byte)
    end
    
    return concat(result)
end

local serialise = textutils.serialise
local unserialise = textutils.unserialise

local function send(modem, channel, data)
    local text = serialise(data)
    local encoded = xor_crypt(text, modem.key)
    modem.transmit(channel, 0, encoded)
end

local function receive(modem, targetChannel)
    modem.open(targetChannel)

    local key = modem.key
    local targetSide = modem.side
    local data
    
    repeat
        local _, side, channel, _, encoded, _  = os.pullEvent("modem_message")
        
        if (channel == targetChannel) and (side == targetSide) then
            local text = xor_crypt(encoded, key)
            data = unserialise(text)
        end
    until data

    return data
end

local function wrap(modem, key)
    local isModem= (type(modem) == "table") and (string.sub(tostring(modem), 1, 10) == "peripheral") and (peripheral.getType(modem) == "modem")
    assert(isModem, "bad argument #1 'modem' (modem expected, got "..type(modem)..")")
    
    modem.side = peripheral.getName(modem)
    modem.key = key
    modem.send = send
    modem.receive = receive
end

return wrap