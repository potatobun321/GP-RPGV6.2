local UI = require('engine.ui.core')
local Theme = require('engine.ui.theme')

local state = {} -- store text string per input id

return function(id, value, x, y, w, h)
    UI.registerHitbox(id, x, y, w, h)
    
    if UI.mouseClicked then
        if UI.hot == id then
            UI.focus = id
        end
    end
    
    if state[id] == nil then
        state[id] = value
    end
    
    if UI.focus == id then
        -- Process input
        if UI.textInput ~= "" then
            state[id] = state[id] .. UI.textInput
        end
        if UI.keysPressed["backspace"] then
            -- UTF8 safe backspace would be better, but simple slice for now
            local text = state[id]
            if #text > 0 then
                local byteoffset = utf8.offset(text, -1)
                if byteoffset then
                    state[id] = string.sub(text, 1, byteoffset - 1)
                end
            end
        end
    else
        -- If an external value update comes in, override
        if value ~= state[id] and not UI.focus == id then
           state[id] = value
        end
    end
    
    UI.drawBox(id, x, y, w, h, Theme)
    
    love.graphics.setColor(Theme.colors.text)
    local font = Theme.font or love.graphics.getFont()
    love.graphics.setFont(font)
    local displayTxt = state[id]
    
    if UI.focus == id then
        -- Blinking cursor
        if math.floor(love.timer.getTime() * 2) % 2 == 0 then
            displayTxt = displayTxt .. "|"
        end
    end
    
    -- Print centered vertically, padded left
    local th = font:getHeight()
    love.graphics.print(displayTxt, x + Theme.metrics.padding, y + h/2 - th/2)
    
    -- Return true if value changed this frame
    if UI.textInput ~= "" or UI.keysPressed["backspace"] then
        return state[id]
    end
    
    return nil
end
