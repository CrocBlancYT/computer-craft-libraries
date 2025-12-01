

local term = peripheral.wrap('left')
term.setTextScale(0.5)
dofile('high-res-wrap.lua')(term)

local buffer = term.buffer

-- Hello world + Smiley Demo
term.clear()
term.setCursorPos(1,1)
term.write('hello world')

buffer.clear()

local x, y = 10, 10
buffer[x+1][y] = true
buffer[x+3][y] = true

buffer[x][y+2] = true
buffer[x+1][y+3] = true
buffer[x+2][y+3] = true
buffer[x+3][y+3] = true
buffer[x+4][y+2] = true
buffer.refresh()


-- Diagonal Line Demo
local function lerp(a,b,t)
    return a + (b-a) * t
end

local width, height = #buffer, #buffer[1]
local diagonal_length = math.sqrt(width^2 + height^2)
local floor = math.floor
while true do

    term.clear()
    buffer.clear()
    
    for i = 0, 1, 1/diagonal_length do
        local x =  lerp(1,width,i)
        local y =  lerp(1,height,i)

        x = floor(x)
        y = floor(y)
        
        buffer[x][y] = true
        buffer.refresh()
        
        sleep()
    end

    term.clear()
    buffer.clear()

    for i = 0, 1, 1/diagonal_length do
        local x =  lerp(1,width,1-i)
        local y =  lerp(1,height,1-i)

        x = floor(x)
        y = floor(y)
        
        buffer[x][y] = true
        buffer.refresh()
        
        sleep()
    end

    sleep()
end