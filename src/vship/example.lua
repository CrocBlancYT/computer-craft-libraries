local vship = dofile('vship.lua')

local min = vector.new(-28583932, 128, 12290049)
local max = vector.new(-28583937, 128, 12290046)

local world, shipyard, mass = vship.blockChanged()

print(world)
print(shipyard)