local function bytes_to_number(bytes)
    local number = 0
    for i, byte in pairs(bytes) do
        number = number + byte * 2^((i-1)*8)
    end
    return number
end

local function load(name)
    local h = io.open(name, 'rb')
    local img = h:read('*a')
    h:close()

    local i = 0
    local function read()
        i = i + 1
        return string.byte(img, i, i)
    end

    local width, height
    do
        local type = bytes_to_number{read(), read()}
        local fileSize = bytes_to_number{read(), read(), read(), read()}

        local reserved = bytes_to_number{read(), read(), read(), read()}

        local offset = bytes_to_number{read(), read(), read(), read()}
        local DIB_header_size = bytes_to_number{read(), read(), read(), read()}

        width = bytes_to_number{read(), read(), read(), read()}
        height = bytes_to_number{read(), read(), read(), read()}

        local colorPlanes = bytes_to_number{read(), read()}
        local bitsPerPixel = bytes_to_number{read(), read()}

        local compressionMethod = bytes_to_number{read(), read(), read(), read()}
        local rawSize = bytes_to_number{read(), read(), read(), read()}

        local horizontalResolution = bytes_to_number{read(), read(), read(), read()}
        local verticalResolution = bytes_to_number{read(), read(), read(), read()}

        local colorsInPalette = bytes_to_number{read(), read(), read(), read()}
        local importantColors = bytes_to_number{read(), read(), read(), read()}

        local isBitMap = (type == 19778)
        local noCompression = (compressionMethod == 0)
    end

    local pixels = {}
    local pixel_id = 1
    local insert = table.insert

    while true do
        local b, g, r = read(), read(), read()
        if not (r and g and b) then break end

        local x = ((pixel_id - 1) % width) + 1
        local y = (pixel_id - x) / (width) + 1
        
        if x == 18 then 
            read()
            read()
        end -- discard spacing

        pixel_id = pixel_id + 1

        insert(pixels, {r,g,b})
    end

    local img = {}
    local line = {}
    local x = 0

    for _, pixel in pairs(pixels) do
        x = x + 1

        insert(line, pixel)

        if x == width then
            insert(img, line)
            line = {}
            x = 0
        end
    end

    return {
        width = width,
        height = height,
        img = img --{{R,G,B}, ...}
    }
end

return {
    load = load
}