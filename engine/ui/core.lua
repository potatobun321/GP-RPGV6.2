local UI = {
    hot = nil,
    active = nil,
    focus = nil,
    
    mx = 0,
    my = 0,
    mouseDown = false,
    mouseClicked = false,
    mouseReleased = false,
    
    textInput = "",
    keysPressed = {},
    
    _nextHot = nil,
}

function UI.update(dt)
    UI.mx, UI.my = love.mouse.getPosition()
    local down = love.mouse.isDown(1)
    
    -- Update state
    if down and not UI.mouseDown then
        UI.mouseClicked = true
    else
        UI.mouseClicked = false
    end
    
    if not down and UI.mouseDown then
        UI.mouseReleased = true
    else
        UI.mouseReleased = false
    end
    
    UI.mouseDown = down
    
    if UI.mouseClicked and not UI.hot then
        UI.focus = nil
    end

    if UI.mouseClicked and UI.hot then
        UI.active = UI.hot
    end
    
    if not UI.mouseDown and not UI.mouseReleased then
        UI.active = nil
    end
    
    UI.hot = UI._nextHot
    UI._nextHot = nil
    
    -- Clear transient input states
    UI.textInput = ""
    UI.keysPressed = {}
end

function UI.textinput(t)
    UI.textInput = UI.textInput .. t
end

function UI.keypressed(key)
    UI.keysPressed[key] = true
end

function UI.registerHitbox(id, x, y, w, h)
    if UI.mx >= x and UI.mx <= x + w and UI.my >= y and UI.my <= y + h then
        UI._nextHot = id
        return true
    end
    return false
end

function UI.drawBox(id, x, y, w, h, theme)
    local stateColor = theme.colors.surface
    local borderColor = theme.colors.border
    
    if UI.active == id then
        stateColor = theme.colors.pressed
        borderColor = theme.colors.borderActive
    elseif UI.hot == id then
        stateColor = theme.colors.hover
        borderColor = theme.colors.borderHover
    elseif UI.focus == id then
        borderColor = theme.colors.borderActive
    end
    
    love.graphics.setColor(stateColor)
    love.graphics.rectangle("fill", x, y, w, h)
    
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(theme.metrics.borderWidth)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setLineWidth(1)
end

return UI
