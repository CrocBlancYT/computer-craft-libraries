-- only works between computers with the same ids

local net = dofile('modemless.lua')

net.transmit('host', {message = '123'})

local message = net.receive('host')
print(message.message) --> "123"