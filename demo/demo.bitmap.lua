local bitmap = dofile('bitmap.lua')

local image = bitmap.load('demo.bitmap1.bmp')

image:setPixel(3,3, 255,0,0)

image.headers.width = 128

local content = image:unload()

local h = io.open('out.bmp', 'wb')
h:write(content)
h:close()