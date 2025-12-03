
local getType = type
local type = getmetatable(vector.new())
local __index = type.__index -- methods table

local sqrt = math.sqrt
local acos = math.acos
local cos = math.cos
local sin = math.sin

-- public methods

function vector.fromTable(t)
    if #t > 0 then
        return vector.new(t[1],t[1],t[1])
    end
    return vector.new(t.x,t.y,t.z)
end

function __index.angle(v1, v2)
    assert(getmetatable(v1) == type, "bad argument #1 to 'angle' (vector expected, got "..type(v1)..")")
    assert(getmetatable(v2) == type, "bad argument #2 to 'angle' (vector expected, got "..type(v2)..")")
    
    local dot11 = v1:dot(v1)
    local dot12 = v1:dot(v2)
    local dot22 = v2:dot(v2)
    
    local cos = dot12 / sqrt(dot11 * dot22)
    return acos(cos)
end

function __index.component(vec, on)
    assert(getmetatable(vec) == type, "bad argument #1 to 'component' (vector expected, got "..type(vec)..")")
    assert(getmetatable(on) == type, "bad argument #2 to 'component' (vector expected, got "..type(on)..")")

    local dot12 = vec:dot(on)
    local dot22 = on:dot(on)
    return dot12 / dot22
end

function __index.projectOnto(vec, on)
    assert(getmetatable(vec) == type, "bad argument #1 to 'projectOnto' (vector expected, got "..type(vec)..")")
    assert(getmetatable(on) == type, "bad argument #2 to 'projectOnto' (vector expected, got "..type(on)..")")

    return on * vec:component(on)
end

function __index.projectOnPlane(vec, removalAxis)
    assert(getmetatable(vec) == type, "bad argument #1 to 'projectOnto' (vector expected, got "..type(vec)..")")
    assert(getmetatable(removalAxis) == type, "bad argument #2 to 'projectOnto' (vector expected, got "..type(removalAxis)..")")

    return vec - vec:projectOnLine(removalAxis)
end

function __index.rotate(vec, axis, theta)
    assert(getmetatable(vec) == type, "bad argument #1 to 'rotate' (vector expected, got "..type(vec)..")")
    assert(getmetatable(axis) == type, "bad argument #2 to 'rotate' (vector expected, got "..type(axis)..")")
    assert(getType(theta) == "number", "bad argument #3 to 'rotate' (number expected, got "..type(theta)..")")

    assert(getmetatable)
    axis = axis:unit()
	local cosa, sina = cos(theta), sin(theta)
	return vec * cosa + (1-cosa) * vec:dot(axis) * axis + axis:cross(vec) * sina
end
