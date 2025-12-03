
local force = {}

dofile('vec.utils.lua')

function force.getForceAt(centerOfMass, mass, omega, positionAt)
    local distanceVector = positionAt - centerOfMass
    local torque = omega * mass
    return torque:cross(distanceVector)
end

function force.angularVelocityFromForce(centerOfMass, mass, forcePos, forceDir)
    local torque = (forcePos - centerOfMass):cross(forceDir)
    return torque / mass
end

function force.linearVelocityFromForce(centerOfMass, mass, forcePos, forceDir)
    return forceDir:projectOnto(forcePos - centerOfMass) / mass
end

function force.velocityAroundAxis(omega, axis)
    return vector.fromTable(omega):component(axis)
end

return force