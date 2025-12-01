
local extension = {}

local sqrt = math.sqrt
local acos = math.acos
local cos = math.cos
local sin = math.sin

-- private methods

local function VectorToVectorAngle(vec1, vec2)
    local dot11 = vec1:dot(vec1)
    local dot12 = vec1:dot(vec2)
    local dot22 = vec2:dot(vec2)
    
    local cos = dot12 / sqrt(dot11 * dot22)
    return acos(cos)
end

local function Component(vec, line)
    local dot12 = vec:dot(line)
    local dot22 = line:dot(line)
    local dist = dot12 / dot22
    
    return dist
end

local function ProjectLine(vec, line)
    return line * Component(vec, line)
end

local function ProjectPlane(vec, removalAxis)
    local component = ProjectLine(vec, removalAxis)
    return vec - component
end

local function rotate(vec, axis, theta)
    axis = axis:unit()

	local cosa = cos(theta)
    local sina = sin(theta)
    
	return vec * cosa + (1-cosa) * vec:dot(axis) * axis + axis:cross(vec) * sina
end

-- public class

function extension:angle(self2)
    return VectorToVectorAngle(self, self2)
end

function extension:component(self2)
    return Component(self, self2)
end

function extension:projectOnto(self2)
    return ProjectLine(self, self2)
end

function extension:planeFromNormal(self2)
    return ProjectPlane(self, self2)
end

function extension:rotate(self2, theta)
    return rotate(self, self2, theta)
end

-- expose methods

local new = vector.new
function vector.new(...)
    local v = new(...)
    
    for name, method in pairs(extension) do
        v[name] = method
    end

    return v
end
