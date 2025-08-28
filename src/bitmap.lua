
local bitmap = {}
local bitmap_obj = {}
local mt = {__index = bitmap_obj}

local byte = string.byte
local char = string.char
local sub = string.sub
local ceil = math.ceil
local log = math.log
local floor = math.floor

-- private class

local function fromBytes(bytes)
    local n = 0;

    for i, byte in pairs(bytes) do
        n = n + byte * 256 ^ (i-1)
    end

    return n;
end

local function toBytes(n)
    local bytes = {}
    
    for i = 1, ceil(log(n + 1, 256)) do
        bytes[i] = n % 256
        n = floor(n / 256)
    end
    
    return bytes
end

local function write(len, number)
    local value = ''
    local bytes = toBytes(number)
    for i = 1, len do
        value = value .. char(bytes[i] or 0)
    end
    return value
end

local function makeRawHeaders(headers)
    local bin_header = ''

    headers.type = 19778

    bin_header = bin_header .. write(2, headers.type)
    bin_header = bin_header .. write(4, headers.fileSize)
    bin_header = bin_header .. write(4, headers.reserved)
    bin_header = bin_header .. write(4, headers.offset)
    bin_header = bin_header .. write(4, headers.DIB_header_size)
    bin_header = bin_header .. write(4, headers.width)
    bin_header = bin_header .. write(4, headers.height)
    bin_header = bin_header .. write(2, headers.colorPlanes)
    bin_header = bin_header .. write(2, headers.bitsPerPixel)
    bin_header = bin_header .. write(4, headers.compressionMethod)
    bin_header = bin_header .. write(4, headers.rawSize)
    bin_header = bin_header .. write(4, headers.horizontalResolution)
    bin_header = bin_header .. write(4, headers.verticalResolution)
    bin_header = bin_header .. write(4, headers.colorsInPalette)
    bin_header = bin_header .. write(4, headers.importantColors)

    return bin_header
end

local function getHeaders(bin)
    local i = 0
    local function read()
        i = i + 1
        return byte(bin, i, i)
    end
    
    return {
        type = fromBytes{read(), read()},
        fileSize = fromBytes{read(), read(), read(), read()},
        reserved = fromBytes{read(), read(), read(), read()},
        offset = fromBytes{read(), read(), read(), read()},
        DIB_header_size = fromBytes{read(), read(), read(), read()},
        width = fromBytes{read(), read(), read(), read()},
        height = fromBytes{read(), read(), read(), read()},
        colorPlanes = fromBytes{read(), read()},
        bitsPerPixel = fromBytes{read(), read()},
        compressionMethod = fromBytes{read(), read(), read(), read()},
        rawSize = fromBytes{read(), read(), read(), read()},
        horizontalResolution = fromBytes{read(), read(), read(), read()},
        verticalResolution = fromBytes{read(), read(), read(), read()},
        colorsInPalette = fromBytes{read(), read(), read(), read()},
        importantColors = fromBytes{read(), read(), read(), read()}
    }
end

local function getData(bin, headers)
    local i = headers.offset
    local function read()
        i = i + 1
        return byte(bin, i, i)
    end
    
    local width = headers.width
    local height = headers.height
    
    local padding = (4-width)%4
    local map = {}

    for y = 1, height do
        local line = {}

        for x = 1, width do
            local b, g, r = read(), read(), read()
            line[x] = {r,g,b}
            for _ = 1, padding do read() end
        end
        
        map[y] = line
    end

    return map
end

function bitmap.load(name)
    local nameIsString = type(name) == 'string'
    
    if not nameIsString then
        local t = type(name)
		error("bad argument #1 to '?' (string expected, got " .. t .. " )");
    end
    
    local handle = io.open(name, 'rb')

    if not handle then
        error("bad argument #1 to '?', no file found")
    end

    local bin = handle:read('*a')
    handle:close()

    local headers = getHeaders(bin)

    local isBitMap = (headers.type == 19778)
    local noCompression = (headers.compressionMethod == 0)

    if not isBitMap then
        error("bad argument #1 to '?', file is not bitmap")
    elseif not noCompression then
        error("bad argument #1 to '?', file is compressed")
    end
    
    local pixels = getData(bin, headers)
    
    return setmetatable({
        fileName = name,
        fileSize = headers.fileSize,

        width = headers.width,
        height = headers.height,

        img = pixels, --{{R,G,B}, ...},

        bin = bin,
        headers = headers
    }, mt)
end

function bitmap_obj:unload()
    local img = self.img
    --local bin  = self.bin

    local headers = self.headers
    --local offset = headers.offset
    local width = headers.width
    local height = headers.height
    
    local padding = (4-width)%4

    local bin_headers = makeRawHeaders(headers) -- sub(bin, 1, offset)
    
    local data = ''
    for y = 1, height do
        local line = img[y] or {}
        for x = 1, width do
            local rgb  = line[x] or {255, 255, 255}
            local r, g, b = rgb[1], rgb[2], rgb[3]

            data = data .. char(b)
            data = data .. char(g)
            data = data .. char(r)

            for _ = 1, padding do data = data .. char(0) end
        end
    end

    return bin_headers .. data
end

function bitmap_obj:setPixel(x,y, r,g,b)
    self.img[y][x] = {r,g,b}
end

function bitmap_obj:getPixel(x,y)
    return self.img[y][x]
end

return bitmap