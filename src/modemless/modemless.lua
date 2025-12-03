local encode = textutils.serialiseJSON
local decode = textutils.unserialiseJSON

local net = {}

function net.receive(host) -- returns the stored table at the path data/[host].json
    local h, err = io.open('net.' .. host .. '.json', 'r')

    if not h then return {}, false, err end -- receive fail

    local text = h:read('*a')
    h:close()

    local payload = decode(text)
    return payload or {}, not (payload == nil) -- success
end

function net.transmit(host, payload) -- replaces the stored table at the path data/[host].json with the payload
    local text = encode(payload)

    local h, err = io.open('net.' .. host .. '.json', 'w+')

    if not h then return false, err end -- message fail

    h:write(text or '')
    h:close()

    return true -- success
end

return net