
local task = dofile('task.lua')

local function mainThread()
    sleep(3)

    task.spawn(function ()
        sleep(2)
        print('hello world!')
    end)

    print('printed first')

end

parallel.waitForAll(mainThread, task.run)