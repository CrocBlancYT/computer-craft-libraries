
-- server
local modem -- = peripheral.find('modem')
dofile('https.lua').wrap(modem)

local connection = modem.listen(123)
connection.send('hello world!')
print(connection.receive()) -- 'echo: hello world!'

-- client
local modem -- = peripheral.find('modem')
dofile('https.lua').wrap(modem)

local connection = modem.connect(123)
local msg = connection.receive()
connection.send('echo: '..msg)
