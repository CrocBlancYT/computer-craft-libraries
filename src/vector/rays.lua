local ray = {}

local floor = math.floor
local sqrt = math.sqrt

function ray.raycast(position, direction, forEach)
    --parameters
    local x,y = position.x, position.y
    local dx,dy = direction.x, direction.y

    --grid position
    local int_x, int_y = floor(x), floor(y)
    
    --unit direction + distance
    local dist = sqrt(dx^2 + dy^2)
    local ux = dx / dist
    local uy = dy / dist

    local int_x2, int_y2 = x, y
    local function on_dist(len, side)
        local x2 = x + (ux*len)
        local y2 = y + (uy*len)
        
        forEach(
            { x = int_x2, y = int_y2 }, --integer position
            { x = x2, y = y2 }, --float position

            { x = ux, y = uy}, --unit direction 
            len, side --length, entry side
        )
    end

    --increments for x & y axises
    local onX_len = dist/dy
    local onY_len = dist/dx

    --current lengths
    local len_line_x = onX_len
    local len_line_y = onY_len

    --line steps + start positions
    local step_x = 0
    local step_y = 0

    --for float start pos
    if dx < 0 then
        step_x = -1
        len_line_x = (x-int_x) * onX_len
    else
        step_x = 1
        len_line_x = (int_x+1-y) * onX_len
    end

    if dy < 0 then
        step_y = -1
        len_line_y = (y-int_y) * onY_len
    else
        step_y = 1
        len_line_y = (int_y+1-x) * onY_len
    end
    
    on_dist(0, '') --distance of 0
    while (len_line_x < dist) or (len_line_y < dist) do

        --traverse for the shortest axis line (x or y)
        if (len_line_x < len_line_y) then
            int_y2 = int_y2 + step_y --traverse for 1 y
            on_dist(len_line_x, 'Y')
            len_line_x = len_line_x + onX_len
        else
            int_x2 = int_x2 + step_x --traverse for 1 x
            on_dist(len_line_y, 'X')
            len_line_y = len_line_y + onY_len
        end
    end
end

function ray.closestPoint(ray_start, ray_dir, point_pos)
    local point_pos = point_pos:sub(ray_start)

    local point_on_dir, scalar = point_pos:project(ray_dir)

    return ray_start:add(point_on_dir), scalar
end

return ray