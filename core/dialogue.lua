-- core/dialogue.lua
-- Responsibility: Manage and render the text overlay system

local Dialogue = {
    active = false,
    text = "",
    displayChars = 0,
    boxY = 0
}

function Dialogue.show(text)
    Dialogue.text = text
    Dialogue.active = true
    Dialogue.displayChars = 0
    Dialogue.boxY = 200
end

function Dialogue.hide()
    Dialogue.active = false
    Dialogue.text = ""
end

function Dialogue.isActive()
    return Dialogue.active
end

function Dialogue.update(dt)
    if Dialogue.active then
        Dialogue.displayChars = Dialogue.displayChars + 40 * dt
        Dialogue.boxY = Dialogue.boxY + (0 - Dialogue.boxY) * 10 * dt
    end
end

function Dialogue.keypressed(key)
    if not Dialogue.active then return end
    
    if key == "e" or key == "space" or key == "return" or key == "escape" then
        if Dialogue.displayChars < #Dialogue.text then
            Dialogue.displayChars = #Dialogue.text
        else
            Dialogue.hide()
        end
    end
end

function Dialogue.draw()
    if not Dialogue.active then return end
    local Theme = require("core.theme")
    local colors = Theme.get()
    
    local w, h = love.graphics.getDimensions()
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    local yOffset = Dialogue.boxY
    
    love.graphics.setColor(colors.wall_border)
    love.graphics.rectangle("line", 50, h - 150 + yOffset, w - 100, 100)
    love.graphics.setColor(colors.console_bg)
    love.graphics.rectangle("fill", 51, h - 149 + yOffset, w - 102, 98)
    
    love.graphics.setColor(colors.text)
    local visibleText = string.sub(Dialogue.text, 1, math.floor(Dialogue.displayChars))
    love.graphics.print(visibleText, 70, h - 120 + yOffset)
    
    if Dialogue.displayChars >= #Dialogue.text then
        local pulse = math.sin(love.timer.getTime() * 5) * 0.5 + 0.5
        love.graphics.setColor(colors.wall_border[1], colors.wall_border[2], colors.wall_border[3], pulse)
        love.graphics.print("Press E to close", 70, h - 80 + yOffset)
    end
end

return Dialogue