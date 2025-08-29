local bitmap = dofile('bitmap.lua')

local image = bitmap.loadFromFile('demo.bitmap1.bmp')

image:setPixel(3,3, 255,0,0)

image:saveToFile('out.bmp')