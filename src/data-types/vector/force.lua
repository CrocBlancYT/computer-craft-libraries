
local force = {}

-- private class

local function Component(vec, line)
    local dot12 = vec:dot(line)
    local dot22 = line:dot(line)
    local dist = dot12 / dot22
    
    return dist
end

local function ProjectLine(vec, line)
    return line * Component(vec, line)
end

-- public class

function force.getForceAt(centerOfMass, mass, omega, positionAt)
    local distanceVector = positionAt - centerOfMass
    local torque = omega * mass
    return torque:cross(distanceVector)
end

function force.angularVelocityFromForce(centerOfMass, mass, forcePos, forceDir)
    local distanceVector = forcePos - centerOfMass
    local torque = distanceVector:cross(forceDir)
    return torque / mass
end

function force.linearVelocityFromForce(centerOfMass, mass, forcePos, forceDir)
    local distanceVector = forcePos - centerOfMass
    return ProjectLine(forceDir, distanceVector) / mass
end

function force.velocityAroundAxis(omega, axis)
    local o = omega
    return Component(vector.new(o.x, o.y, o.z), axis)
end

return force