local UI = require("core.ui.core")
local Theme = require("core.ui.theme")

return function(id, text, x, y, w, h)
    UI.registerHitbox(id, x, y, w, h)
    
    local clicked = false
    if UI.active == id and UI.hot == id and UI.mouseReleased then
        clicked = true
    end
    
    UI.drawBox(id, x, y, w, h, Theme)
    
    love.graphics.setColor(Theme.colors.text)
    local font = Theme.font or love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    love.graphics.setFont(font)
    love.graphics.print(text, x + w/2 - tw/2, y + h/2 - th/2)
    
    return clicked
end
