
-- quaternion class

local quaternion = {}
local quaternion_obj = {__type = "quaternion"}
local mt = {__index = quaternion_obj}

local pi = math.pi
local abs = math.abs
local min = math.min
local max = math.max
local asin = math.asin
local acos = math.acos
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local sqrt = math.sqrt
local sub = string.sub
local len = string.len

local identityQuat = {
    w = 1, x = 0, y = 0, z = 0
}

-- private functions

local function isVector(v)
    if not (type(v) == "table") then return false end
    
    local x, y, z = v.x, v.y, v.z

    if not x then return false end
    if not y then return false end
    if not z then return false end

    if v.__type and (not v.__type == "vector") then return false end

    if not (type(x) == "number") then return false end
    if not (type(y) == "number") then return false end
    if not (type(z) == "number") then return false end

    return true
end

local function transformVector(q, v)
    -- math from: https://gamedev.stackexchange.com/questions/28395/rotating-vector3-by-a-quaternion
    local u = vector.new(q.x, q.y, q.z)
    return u * (u * 2):dot(v) + v*(q.w * q.w - u:dot(u)) + (u * 2 * q.w):cross(v)
end

local function combineQuaternions(q1, q2) -- hamilton
    local p1, p2 = rawget(q1, "proxy"), rawget(q2, "proxy");
    local x1, y1, z1, w1 = p1.x, p1.y, p1.z, p1.w
    local x2, y2, z2, w2 = p2.x, p2.y, p2.z, p2.w
    return quaternion.new{
        w = w1*w2 - x1*x2 - y1*y2 - z1*z2,
        x = w1*x2 + x1*w2 + y1*z2 - z1*y2,
        y = w1*y2 - x1*z2 + y1*w2 + z1*x2,
        z = w1*z2 + x1*y2 - y1*x2 + z1*w2,
    }
end

local function inverseQuaternion(q)
    q = q.unit
    return quaternion.new{
        w=q.w,
        x=-q.x,
        y=-q.y,
        z=-q.z
    }
end

local function quaternionFromMatrix(m)
	-- taken from: http://wiki.roblox.com/index.php?title=Quaternions_for_rotation#Quaternion_from_a_Rotation_Matrix
	local m11, m12, m13 = m[1][1], m[1][2], m[1][3]
    local m21, m22, m23 = m[2][1], m[2][2], m[2][3]
    local m31, m32, m33 = m[3][1], m[3][2], m[3][3]
	local trace = m11 + m22 + m33;
	if (trace > 0) then
		local s = sqrt(1 + trace);
		local r = 0.5 / s;
		return s * 0.5, {(m32 - m23) * r, (m13 - m31) * r, (m21 - m12) * r};
	else -- find the largest diagonal element
		local big = max(m11, m22, m33);
		if big == m11 then
			local s = sqrt(1 + m11 - m22 - m33);
			local r = 0.5 / s;
			return (m32 - m23) * r, {0.5 * s, (m21 + m12) * r, (m13 + m31) * r};
		elseif big == m22 then
			local s = sqrt(1 - m11 + m22 - m33);
			local r = 0.5 / s;
			return (m13 - m31) * r, {(m21 + m12) * r, 0.5 * s, (m32 + m23) * r};
		elseif big == m33 then
			local s = sqrt(1 - m11 - m22 + m33);
			local r = 0.5 / s;
			return (m21 - m12) * r, {(m13 + m31) * r, (m32 + m23) * r, 0.5 * s};
		end;
	end;
end;

local function quaternionToMatrix(q)
    local p = rawget(q, "proxy");
    local i, j, k, w = p.x, p.y, p.z, p.w
    
	local m11 = 1 - 2*j^2 - 2*k^2;
	local m12 = 2*(i*j - k*w);
	local m13 = 2*(i*k + j*w);
	local m21 = 2*(i*j + k*w);
	local m22 = 1 - 2*i^2 - 2*k^2;
	local m23 = 2*(j*k - i*w);
	local m31 = 2*(i*k - j*w);
	local m32 = 2*(j*k + i*w);
	local m33 = 1 - 2*i^2 - 2*j^2;
    
	return {
        {m11, m12, m13},
        {m21, m22, m23},
        {m31, m32, m33}
    };
end;

local function fromAxisAngle(axis, theta)
    local axis = axis:normalize()
    local sin_half = sin(theta / 2)
    return quaternion.new{
        w = cos(theta / 2),
        x = axis.x * sin_half,
        y = axis.y * sin_half,
        z = axis.z * sin_half,
    };
end;

local function toAxisAngle(q)
    local p = rawget(q, "proxy")
    local w, x, y, z = p.w, p.x, p.y, p.z
    
    local axis = vector.new(x,y,z)
    local norm = axis:length()
    local theta = asin(norm) * 2
    
    if norm == 0 then
        return vector.new(0,0,0);
    end

    return axis / norm * theta;
end;

local function fromRotation(v1, v2)
    local v1, v2 = v1:normalize(), v2:normalize()
    local dot12 = v1:dot(v2)

    if dot12 == 1 then -- no rotation
        return quaternion.new(identityQuat);
    elseif dot12 == -1 then -- 180 degree turn
        local x, y = vector.new(1, 0, 0), vector.new(0, 1, 0)
        local v2 = (v1 == x) and y or x
        local u = v1:cross(v2):normalize()
        return quaternion.new{w=0, x=u.x, y=u.y, z=u.z};
    end
    
    return quaternion.fromAxisAngle(v1:cross(v2), acos(dot12));
end

local function quaternionNorm(q)
    local p = rawget(q, "proxy");
    local x, y, z, w = p.x, p.y, p.z, p.w
    return sqrt(x^2 + y^2 + z^2 + w^2);
end;

local function normalizeQuaternion(q)
    local p = rawget(q, "proxy");
    local x, y, z, w = p.x, p.y, p.z, p.w
    local norm = sqrt(x^2 + y^2 + z^2 + w^2)
    
    return quaternion.new{
        w = w / norm,
        x = x / norm,
        y = y / norm,
        z = z / norm,
    };
end;

local function decomposeString(str)
    local t = {}
    for i = 1, len(str) do
        t[i] = sub(str, i, i)
    end
    return t
end

local function makeEulerQuat(xyz, order)
    local o = decomposeString(order)
    local x, y, z = xyz.x, xyz.y, xyz.z

    local q = {
        x = quaternion.new{w=cos(x/2), x=sin(x/2), y=0, z=0},
        y = quaternion.new{w=cos(y/2), x=0, y=sin(y/2), z=0},
        z = quaternion.new{w=cos(z/2), x=0, y=0, z=sin(z/2)},
    }
    
    return q[o[1]] * q[o[2]] * q[o[3]]
end

-- meta-methods

function mt.__index(self, index)
	if (index == "x" or index == "y" or index == "z" or index == "w") then
		return rawget(self, "proxy")[index];
	elseif quaternion_obj[index] then
		return quaternion_obj[index];
    elseif index == 'magnitude' then
        return quaternionNorm(self)
    elseif index == 'unit' then
        return normalizeQuaternion(self)
    else
		error(index .. " is not a valid member of quaternion");
	end;
end;

function mt.__newindex(v, index, value)
	error(index .. " cannot be assigned to");
end;

function mt.__mul(a, b)
	local aIsQuat = type(a) == "table" and a.__type and a.__type == "quaternion";
	local bIsQuat = type(b) == "table" and b.__type and b.__type == "quaternion";

	if (not aIsQuat) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (quaternion expected, got " .. cust .. " )");
	elseif (not bIsQuat) then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (quaternion expected, got " .. cust .. " )");
	end;

	return combineQuaternions(a, b);
end;

function mt.__tostring(t)
    local proxy = rawget(t, "proxy");
    local w, x, y, z = proxy.w, proxy.x, proxy.y, proxy.z
	return w..'w '..x..'x '..y..'y '..z..'z';
end;

mt.__metatable = false;

-- public class

function quaternion.new(...)
    local proxy = {};
	local self = {};
	self.proxy = proxy;

    for k, v in pairs(identityQuat) do
        proxy[k] = v;
    end
    
    local t = {...};
    
    local q = t[1]
    if type(q) == "table" then
        for k, v in pairs(q) do
            proxy[k] = v;
        end
    else
        proxy['w'] = t[1];
        proxy['x'] = t[2];
        proxy['y'] = t[3];
        proxy['z'] = t[4];
    end
    
	return setmetatable(self, mt);
end

function quaternion.fromAxisAngle(a, b)
	local aIsVector = type(a) == "table" and (a.x and a.y and a.z and not a.w)
	local bIsNumber = type(b) == "number";

	if (not aIsVector) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (vector expected, got " .. cust .. " )");
	elseif (not bIsNumber) then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (number expected, got " .. cust .. " )");
	end;

    return fromAxisAngle(a, b);
end

function quaternion.fromMatrix(a)
    local w, u = quaternionFromMatrix(a);
    return quaternion.new(w, u[1], u[2], u[3]);
end

function quaternion_obj:toMatrix()
    return quaternionToMatrix(self);
end

function quaternion.fromVectorToVector(a, b)
	local aIsVector = isVector(a);
	local bIsVector = isVector(b);

    if (not aIsVector) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (vector expected, got " .. cust .. " )");
	elseif (not bIsVector) then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (vector expected, got " .. cust .. " )");
	end;

    a = vector.new(a.x, a.y, a.z);
    b = vector.new(a.x, a.y, a.z);

    return fromRotation(a, b);
end;

function quaternion.fromEuler(a, b)
	local aIsTable = type(a) == "table"
	local bIsString = type(b) == "string"
    
    if (not aIsTable) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (vector expected, got " .. cust .. " )");
	elseif (not bIsString) then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (vector expected, got " .. cust .. " )");
	end;
    
    return makeEulerQuat(a, b);
end;

function quaternion_obj:transformVector(a)
	local aIsVector = isVector(a);
    
    if (not aIsVector) then
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (vector expected, got " .. cust .. " )");
	end;
    
    return transformVector(self, a);
end;

function quaternion_obj:inverse()
    return inverseQuaternion(self);
end;

function quaternion_obj:toSave()
    local p = rawget(self, "proxy");
    return {
        w = p.w,
        x = p.x,
        y = p.y,
        z = p.z,
        __type = quaternion.__type,
    };
end;

function quaternion_obj:toAxisAngle()
    return toAxisAngle(self)
end

function quaternion_obj:toEulerXYZ() -- world XYZ // local ZYX
    local m = self:toMatrix()
    
    local x
    local y = asin(max(-1, min(1, m[1][3])))
    local z
    
    if abs(m[1][3]) >= 1 then -- Z gimbal-lock
        x, z = atan2(m[3][2], m[2][2]), 0
    else
        x, z = atan2(-m[2][3], m[3][3]), atan2(-m[1][2], m[1][1])
    end
    
    return x, y, z
end

function quaternion_obj:toEulerZYX() -- world ZYX // local XYZ  (command rotation order)
    local m = self:toMatrix()
    
    local z
    local y = asin(-max(-1, min(1, m[3][1])))
    local x
    
    if abs(m[3][1]) >= 1 then -- Z gimbal-lock
        x, z = atan2(-m[2][3], m[2][2]), 0
    else
        x, z = atan2(m[3][2], m[3][3]), atan2(m[2][1], m[1][1])
    end

    return z, y, x
end

function quaternion_obj:toEulerYXZ() -- world YXZ // local ZXY
    local m = self:toMatrix()
    
    local z
    local x = asin(-max(-1, min(1, m[2][3])))
    local y
    
    if abs(m[2][3]) >= 1 then -- Z gimbal-lock
        y, z = atan2(m[3][1], m[1][1]), 0
    else
        y, z = atan2(-m[3][1], m[3][3]), atan2(-m[1][2], m[2][2])
    end

    return z, x, y
end

function quaternion_obj:toEulerZXY() -- world ZXY // local YXZ (cc:vs rotation order)
    local m = self:toMatrix()
    
    local z
    local x = asin(-max(-1, min(1, m[2][3])))
    local y
    
    if abs(m[2][3]) >= 1 then -- Z gimbal-lock
        y, z = atan2(-m[3][1], m[1][1]), 0
    else
        y, z = atan2(-m[1][3], m[3][3]), atan2(m[2][1], m[2][2])
    end
    
    return z, x, y
end

if ship then
    local getQuaternion = ship.getQuaternion;

    function ship.getQuaternion()
        return quaternion.new(getQuaternion());
    end
end

return quaternion