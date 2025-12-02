--- RSA-like encryption (asymmetric)
--- xor encryption (symmetric)
--- wrapper library 
--- 
--- METHODS:
--- https.wrap(modem)
--- 
--- modem.connect(channel) -> connection
--- modem.host(channel) -> connection
--- 
--- connection.send(payload)
--- connection.receive() -> payload
--- 

local function is_prime(n)
    if n <= 1 then return false end
    if n <= 3 then return true end
    if n % 2 == 0 or n % 3 == 0 then return false end
    local i = 5
    while i * i <= n do
        if n % i == 0 or n % (i + 2) == 0 then
            return false
        end
        i = i + 6
    end
    return true
end

local function gcd(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

local function modinv(a, m)
    local m0, x0, x1 = m, 0, 1
    if m == 1 then return 0 end
    while a > 1 do
        local q = math.floor(a / m)
        local t = m
        m = a % m
        a = t
        t = x0
        x0 = x1 - q * x0
        x1 = t
    end
    if x1 < 0 then x1 = x1 + m0 end
    return x1
end

--modular exponentiation (a^b mod m)
local function modpow(a, b, m)
    local result = 1
    a = a % m
    while b > 0 do
        if b % 2 == 1 then
            result = (result * a) % m
        end
        b = math.floor(b / 2)
        a = (a * a) % m
    end
    return result
end

local function generate_keys()
    --two distinct primes (still too small for real security)
    local p, q
    repeat p = math.random(17, 47) until is_prime(p)
    repeat q = math.random(17, 47) until is_prime(q) and q ~= p
    
    local n = p * q
    local phi = (p - 1) * (q - 1)
    
    --public exponent
    local e
    repeat e = math.random(3, phi - 1) until gcd(e, phi) == 1
    
    --private exponent
    local d = modinv(e, phi)
    
    return {
        public = {e = e, n = n},
        private = {d = d, n = n}
    }
end

local function encrypt(number, public_key)
    if number >= public_key.n then
        error("Message must be smaller than n")
    end
    return modpow(number, public_key.e, public_key.n)
end

local function decrypt(number, private_key)
    return modpow(number, private_key.d, private_key.n)
end

local function text_to_bytes(text)
    local bytes = {}
    for i = 1, string.len(text) do
        table.insert(bytes, string.byte(string.sub(text,i,i)))
    end
    return bytes
end

local function bytes_to_text(bytes)
    local text = ''
    for _, byte in pairs(bytes) do
        text = text .. string.char(byte)
    end
    return text
end

local function encrypt_text(text, public_key)
    local bytes = text_to_bytes(text)
    local encrypted_bytes = {}

    for i, v in pairs(bytes) do
        encrypted_bytes[i] = encrypt(v, public_key)
    end

    return encrypted_bytes
end

local function decrypt_bytes_table(bytes_table, private_key)
    local bytes = bytes_table
    local encrypted_bytes = {}

    for i, v in pairs(bytes) do
        encrypted_bytes[i] = decrypt(v, private_key)
    end

    return bytes_to_text(encrypted_bytes)
end

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

local asymmetric = {
    generateKeys = generate_keys,
    encrypt = encrypt_text,
    decrypt = decrypt_bytes_table
}

local symmetric = {
    crypt = xor_crypt
}

local function generateConnection(connChannel, modem, session_key)
    local conn = {}

    conn.receive = function ()
        local payload

        repeat
            local _, _, channel, _, text = os.pullEvent('modem_message')

            if (channel == connChannel) and type(text) == "string" then
                local encoded = symmetric.crypt(text, session_key)
                payload = textutils.unserialise(encoded)
            end

        until payload -- textutils.unserialise returns nil on incorrect strings

        return payload
    end

    conn.send = function (payload)
        local text = textutils.serialise(payload)
        local encrypted = symmetric.crypt(text, session_key)

        modem.transmit(connChannel, 0, encrypted)
    end

    return conn
end

local function listen(channel, modem)
    modem.open(channel)

    local _, _, recv_channel, _, message
    repeat _, _, recv_channel, _, message = os.pullEvent('modem_message')
    until (channel == recv_channel) and (type(message) == "table") and (message.public_key) and (message.clientId)

    -- receive public key
    local public_key = message.public_key
    local session_key = ''
	for i = 1, 64 do
		session_key = session_key .. string.char(math.random(0, 128))
	end

    local server_id = math.random()
    local client_id = message.clientId

    -- encrypt & send session key + server id
    modem.transmit(channel, 0, {
        session_key = asymmetric.encrypt(session_key, public_key),
        public_key = public_key,

        clientId = client_id,
        serverId = server_id
    })

    -- await confirmation
    local _, _, recv_channel, _, message
    repeat _, _, recv_channel, _, message = os.pullEvent('modem_message')
    until (channel == recv_channel) and (type(message) == "table") and (message.confirmedServer) and (message.clientId) and (message.clientId == client_id)

    if not (message.confirmedServer == server_id) then return end

    return generateConnection(channel, modem, session_key)
end

local function connect(channel, modem)
    -- generate public & private key
    local client_keys = asymmetric.generateKeys()
    local client_id = math.random()

    -- send public key
    modem.transmit(channel, 0, {
        public_key = client_keys.public,
        clientId = client_id
    })

    modem.open(channel)

    local _, _, recv_channel, _, message
    repeat _, _, recv_channel, _, message = os.pullEvent('modem_message')
    until (channel == recv_channel) and (type(message) == "table") and (message.session_key) and (message.clientId) and (message.clientId == client_id) and (message.serverId)

    -- server confirmation
    modem.transmit(channel, 0, {
        clientId = client_id,
        confirmedServer = message.serverId
    })

    -- receive & decrypt session key
    local session_key = asymmetric.decrypt(message.session_key, client_keys.private)

    return generateConnection(channel, modem, session_key)
end

-- methods shown here
local function wrap(modem)
    modem.closeAll()

    modem.listen = function (channel)
        local conn
        repeat conn = listen(channel, modem)
        until conn
        return conn
    end

    modem.connect = function (channel)
        return connect(channel, modem)
    end
end

return {wrap=wrap}