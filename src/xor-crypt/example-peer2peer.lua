
local modem -- = ...
dofile('xor-crypt.lua').wrap(modem, 'key')

modem:send(123, {message='hello world'})

-- on another computer
local modem -- = ...
dofile('xor-crypt.lua').wrap(modem, 'key')

local message = modem:receive(123)
print(message.message) --> 'hello world'