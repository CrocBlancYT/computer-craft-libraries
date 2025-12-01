
local charsetStart = 128;
local char = string.char

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
end;

local function refresh(buffer, term, bitColor, backgroundColor)
    local blit = term.blit
    local setCursorPos = term.setCursorPos

    for x = 1, #buffer, 2 do
        for y = 1, #buffer[1], 3 do
            setCursorPos((x+2)/2, (y+3)/3)

            local p1 = buffer[x]   [y]
            local p2 = buffer[x+1] [y]
            local p3 = buffer[x]   [y+1]
            local p4 = buffer[x+1] [y+1]
            local p5 = buffer[x]   [y+2]
            local p6 = buffer[x+1] [y+2]

            local byte
            local inverted = p6
            if not p6 then
                byte = charsetStart + fromBin({p1,p2,p3,p4,p5,p6})
            else
                byte = charsetStart + fromBin({not p1,not p2,not p3,not p4,not p5, not p6})
            end
            
            if not (byte - charsetStart == 0)then
                if inverted then
                    blit(char(byte), backgroundColor, bitColor)
                else
                    blit(char(byte), bitColor, backgroundColor)
                end
            end
        end
    end
end;

local function clear(term, buffer)
    local width, height = term.getSize()
    for x = 1, width*2 do
        local line = buffer[x]
        for y = 1, height*3 do
            line[y] = false
        end
    end;
end;

-- public class

local function wrap(term, bitColor, backgroundColor)
    local buffer = {}
    local width, height = term.getSize();
    
    bitColor = bitColor or colors.toBlit(colors.white);
    backgroundColor = backgroundColor or colors.toBlit(colors.black);

    for x = 1, width*2 do
        local line = {}
        for y = 1, height*3 do
            line[y] = false
        end
        buffer[x] = line
    end

    function buffer.refresh()
        refresh(buffer, term, bitColor, backgroundColor)
    end;

    function buffer.clear()
        clear(term, buffer)
    end;
    
    term.buffer = buffer
    
    return buffer;
end;

return wrap;