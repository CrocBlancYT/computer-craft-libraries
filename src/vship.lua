-- library to abstract the cc:vs ship api (direction vectors, angular velocity, transforms, bounding box position..)

local function transformVector(q, v)
    local u = vector.new(q.x, q.y, q.z)
    return u * (u * 2):dot(v) + v*(q.w * q.w - u:dot(u)) + (u * 2 * q.w):cross(v)
end

local function inverseQuat(q)
    return {w=q.w, x=-q.x, y=-q.y, z=-q.z}
end

function vector.fromTable(v)
    return vector.new(v.x, v.y, v.z)
end

local vship = {}

vship.commandRotationOrder = 'ZYX'
vship.ccvsRotationOrder = 'YXZ'

-- DIRECTION VECTORS
function vship.getLook()  return transformVector( ship.getQuaternion(), vector.new(0, 0, -1)):normalize() end
function vship.getUp()    return transformVector( ship.getQuaternion(), vector.new(0, 1, 0) ):normalize() end
function vship.getRight() return transformVector( ship.getQuaternion(), vector.new(1, 0, 0) ):normalize() end

function vship.getAngularVelocity() -- to test
    local o = ship.getOmega()
    local v = transformVector(ship.getQuaternion(), vector.new(o.x, o.y, o.z))
    
    return {
        pitch = v.x,
        yaw  = v.y,
        roll   = v.z,
    }
end

-- SHIPYARD => WORLD
function vship.transformToWorld(block)
    assert(block, "shipyard position missing")

    local w, s = ship.getWorldspacePosition(), ship.getShipyardPosition()

    local world = vector.new(w.x, w.y, w.z)
    local shipyard = vector.new(s.x, s.y, s.z)

    local offset = block - shipyard

    -- the offset is rotated in VS's rendering
    offset = transformVector(ship.getQuaternion(), offset)

    return world + offset
end

-- WORLD => SHIPYARD
function vship.transformToShip(block)
    assert(block, "world position missing")

    local w, s = ship.getWorldspacePosition(), ship.getShipyardPosition()

    local world = vector.new(w.x, w.y, w.z)
    local shipyard = vector.new(s.x, s.y, s.z)

    local offset = block - world

    -- the offset is rotated in VS's rendering
    offset = transformVector(inverseQuat(ship.getQuaternion()), offset)

    return shipyard + offset
end

-- returns the center of the bounding box; from it's 2 corners (shipyard positions)
function vship.getPositionAABB(cornerMin, cornerMax)
    assert(cornerMin, "shipyard position 1 missing")
    assert(cornerMax, "shipyard position 2 missing")

    local centerShipyard = (cornerMin + cornerMax) / 2
    return vship.transformToWorld(centerShipyard)
end

function vship.getCenterOfMass()
    return vector.fromTable(ship.getWorldspacePosition())
end

function vship.blockChanged()
    local mass = ship.getMass()
    local shipyard = vector.fromTable(ship.getShipyardPosition())
    
    repeat sleep()
    until not (ship.getMass() == mass)

    sleep()

    local change_mass = ship.getMass() - mass
    local change_shipyard = vector.fromTable(ship.getShipyardPosition()) - shipyard

    local mass = ship.getMass()
    local offset = change_shipyard / (change_mass / mass)

    local shipyard_pos = shipyard + offset 

    local world_pos = vship.transformToWorld(shipyard_pos)

    return world_pos, shipyard_pos - vector.new(0.5, 0.5, 0.5), change_mass
end

return vship