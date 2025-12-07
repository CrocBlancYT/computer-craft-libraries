local signals = dofile('signals.lua')

local test = signals.new()

test:Connect(function() print('hello world!') end)

test:Connect(function(a) print(a, 'hello!') end)

test:Fire('world!')