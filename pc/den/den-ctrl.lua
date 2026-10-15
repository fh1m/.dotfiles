-- Runtime-only, non-consuming gesture. Never stores key contents or changes app bindings.
if _G.den_ctrl_subscription then _G.den_ctrl_subscription:remove() end
local pressed, dirty, start, last, count = false, false, 0, 0, 0
_G.den_ctrl_subscription = hl.on("input.keyboard.key", function(code, time, state)
    if code ~= 37 and code ~= 105 then
        if state == 1 then dirty = true; count = 0 end
        return
    end
    local flag=io.open("/home/fh1m/.local/state/homie-control/input/active","r")
    local captured=false
    if flag then captured=flag:read("*a")=="1"; flag:close() end
    if captured then count=0; pressed=false; return end -- native capture handles its own escape
    if state == 1 then
        if pressed then dirty = true else pressed = true; dirty = false; start = time end
    elseif state == 0 then
        if pressed and not dirty and time-start < 260 then
            if time-last > 360 then count = 0 end
            count = count+1; last = time
            if count == 2 then hl.exec_cmd("python3 /home/fh1m/.local/state/homie-control/den-cursor.py show") end
            if count == 3 then
                hl.exec_cmd("python3 /home/fh1m/.local/state/homie-control/den-cursor.py recover")
                count = 0
            end
        else count=0 end
        pressed = false
    end
end)
