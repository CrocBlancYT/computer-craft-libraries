
local binary = {__type = "binary"}
local mt = {__index = binary}

local byte = string.byte
local char = string.char
local insert = table.insert
local format = string.format
local max = math.max

-- private class

local function fromBin(b)
    local n = 0;

    for i, bool in pairs(b) do
        local bin = 2^(i-1)
        if bool then
            n = n + bin
        end
    end

    return n;
end

local function toBin(n)
    local t = {};
    
    local p = 0
    while n>(2^p) do p = p + 1 end;

    for i = p, 0, -1 do
        local bin = 2^i
        
        local bool = n >= bin
        insert(t, 1, bool);
        if n >= bin then
            n = n - bin
        end
    end

    return binary.new(t);
end;

local function xorBin(a, b)
    local new = {}

    for i = 1, max(#a, #b) do
        local a, b = a[i] or false, b[i] or false
        new[i] = (a and not b) or (b and not a)
    end

    return binary.new(new);
end;

local function andBin(a, b)
    local new = {}

    for i = 1, max(#a, #b) do
        local a, b = a[i] or false, b[i] or false
        new[i] = (a and b)
    end

    return binary.new(new);
end;

local function invertBin(a)
    local new = {}

    for i = 1, #a do
        new[i] = not a[i]
    end;

    return new;
end;

local function toSave(a)
    local new = { __type = binary.__type }

    for i = 1, #a do
        new[i] = a[i]
    end
    
    return new;
end

-- meta-methods

function mt.__index(self, index)
    if binary[index] then
		return binary[index];
	else
		error(index .. " is not a valid member of binary");
	end;
end;

function mt.__newindex(v, index, value)
	error(index .. " cannot be assigned to");
end;

function mt.__add(a, b)
    local n1, n2 = fromBin(a), fromBin(b)
    return binary.fromNumber(n1 + n2);
end;

function mt.__sub(a, b)
    local n1, n2 = fromBin(a), fromBin(b)
    return binary.fromNumber(n1 - n2);
end;

function mt.__mult(a, b)
    return andBin(a, b);
end;

function mt.__div(a, b)
    return xorBin(a, b);
end;

function mt.__tostring(a)
    local n = fromBin(a)
    return format(n);
end;

-- public class

function binary.new(a)
    local aIsTable = type(a) == "table"

    if not aIsTable then
        local t = type(a)
		error("bad argument #1 to '?' (table expected, got " .. t .. " )");
    end

    return setmetatable(a, mt);
end;

function binary.fromNumber(a)
    local aIsString = type(a) == "number"

    if not aIsString then
        local t = type(a)
		error("bad argument #1 to '?' (number expected, got " .. t .. " )");
    end
    
    return toBin(a);
end;

function binary.fromCharacter(a)
    local aIsString = type(a) == "string"

    if not aIsString then
        local t = type(a)
		error("bad argument #1 to '?' (string expected, got " .. t .. " )");
    end;

    return binary.fromNumber(byte(a));
end;

function binary:shift(b)
    local bIsNumber = type(b) == "number"

    if not bIsNumber then
        local t = type(b)
		error("bad argument #1 to '?' (string expected, got " .. t .. " )");
    end;
    
    local n = fromBin(self)
    return toBin(n * 2^(b-1));
end;

function binary:invert()
    return invertBin(self);
end;

function binary:toCharacter()
    return char(fromBin(self));
end;

function binary:toNumber()
    return fromBin(self);
end;

function binary:toSave()
    return toSave(self);
end;

return binary;