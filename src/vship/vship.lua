-- by crocblancyt, basically a library to abstract the cc:vs ship api (direction vectors, angular velocity, transforms, bounding box position..)

-- (credits to endalion) transform the vector "v" using the rotation represented by quaternion "q"


local function inverseQuat(q)
    return {w=q.w, x=-q.x, y=-q.y, z=-q.z}
end

local function vectorFromTable(v)
    return vector.new(v.x, v.y, v.z)
end

local function isVector(v)
    return (type(v) == "table") and (getmetatable(v) == getmetatable(vector.new()))
end

local function transformDirection(q, d)
    local u = vector.new(q.x, q.y, q.z)
    return u * (u * 2):dot(d) + d*(q.w * q.w - u:dot(u)) + (u * 2 * q.w):cross(d)
end

local function transformPosition(quat, pos, from, to)
    local dir = pos - from
    return to + transformDirection(quat, dir)
end

commandRotationOrder = 'XYZ'
ccvsRotationOrder = 'YXZ'

-- DIRECTION VECTORS
function getLook()  return transformDirection( ship.getQuaternion(), vector.new(0, 0, -1)):normalize() end
function getUp()    return transformDirection( ship.getQuaternion(), vector.new(0, 1, 0) ):normalize() end
function getRight() return transformDirection( ship.getQuaternion(), vector.new(1, 0, 0) ):normalize() end

function getLocalOmega()
    local o = ship.getOmega()
    local q = ship.getQuaternion()
    return transformDirection(q, vectorFromTable(o))
end

world = {}    -- SHIPYARD => WORLD
shipyard = {} -- WORLD => SHIPYARD

function world.transformPosition(pos)
    assert (ship, "must be on a ship")
    assert(isVector(pos) , "bad argument #1 'position' (vector expected, got "..type(pos)..")")
    
    local world = vectorFromTable(ship.getWorldspacePosition())
    local shipyard = vectorFromTable(ship.getShipyardPosition())
    local quat = ship.getQuaternion()
    
    return transformPosition(quat, pos, shipyard, world)
end

function shipyard.transformPosition(pos)
    assert (ship, "must be on a ship")
    assert(isVector(pos) , "bad argument #1 'position' (vector expected, got "..type(pos)..")")

    local world = vectorFromTable(ship.getWorldspacePosition())
    local shipyard = vectorFromTable(ship.getShipyardPosition())
    local quat = ship.getQuaternion()
    
    return transformPosition(inverseQuat(quat), pos, world, shipyard)
end

function world.transformDirection(dir)
    assert (ship, "must be on a ship")
    assert(isVector(dir) , "bad argument #1 'direction' (vector expected, got "..type(dir)..")")
    local quat = ship.getQuaternion()
    return transformDirection(quat, dir)
end

function shipyard.transformDirection(dir)
    assert (ship, "must be on a ship")
    assert(isVector(dir) , "bad argument #1 'direction' (vector expected, got "..type(dir)..")")
    local quat = ship.getQuaternion()
    return transformDirection(inverseQuat(quat), dir)
end

-- returns the center of the bounding box; from it's 2 corners (shipyard positions)
function getPositionAABB(cornerMin, cornerMax)
    assert (ship, "must be on a ship")
    assert(isVector(cornerMin) , "bad argument #1 'cornerMin' (vector expected, got "..type(cornerMin)..")")
    assert(isVector(cornerMax) , "bad argument #2 'cornerMax' (vector expected, got "..type(cornerMax)..")")
    
    local centerShipyard = (cornerMin + cornerMax) / 2
    return vship.transformToWorld(centerShipyard)
end

function blockChanged()
    assert (ship, "must be on a ship")

    local mass = ship.getMass()
    local shipyard = vectorFromTable(ship.getShipyardPosition())
    
    repeat sleep()
    until not (ship.getMass() == mass)

    sleep()

    local change_mass = ship.getMass() - mass
    local change_shipyard = vectorFromTable(ship.getShipyardPosition()) - shipyard

    local mass = ship.getMass()
    local offset = change_shipyard / (change_mass / mass)

    local shipyard_pos = shipyard + offset
    
    local world_pos = world.transformPosition(shipyard_pos)
    
    return world_pos, shipyard_pos - vector.new(0.5, 0.5, 0.5), change_mass
end
