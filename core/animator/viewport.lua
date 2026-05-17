local state = require 'core.animator.state'
local logic = require 'core.animator.logic'

local viewport = {}

function viewport.drawCheckerboard(x, y, w, h, size)
    love.graphics.setColor(0.25, 0.25, 0.25, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    for i = 0, math.ceil(w/size)-1 do
        for j = 0, math.ceil(h/size)-1 do
            if (i+j) % 2 == 0 then
                local cx = x + i*size
                local cy = y + j*size
                local cw = math.min(size, w - i*size)
                local ch = math.min(size, h - j*size)
                love.graphics.rectangle("fill", cx, cy, cw, ch)
            end
        end
    end
end

function viewport.getBounds()
    local panelX = 320
    local panelW = state.screenW - 640
    
    local fixSize = 256
    local centerX = panelX + (panelW / 2)
    local centerY = state.screenH / 2
    
    local drawX = centerX - (fixSize / 2)
    local drawY = centerY - (fixSize / 2)
    
    return drawX, drawY, fixSize, fixSize, panelX, panelW
end

function viewport.mousepressed(x, y, button)
    if not state.image or not state.grid then return end
    
    local imgX, imgY = viewport.getBounds()
    
    if button == 1 and x >= imgX and x < imgX + state.image:getWidth() and y >= imgY and y < imgY + state.image:getHeight() then
        local fw = tonumber(state.inputState.frameWidth.text) or 32
        local fh = tonumber(state.inputState.frameHeight.text) or 32
        local l = tonumber(state.inputState.left.text) or 0
        local t = tonumber(state.inputState.top.text) or 0
        local b = tonumber(state.inputState.border.text) or 0
        
        local localX = x - imgX - l
        local localY = y - imgY - t
        
        if localX >= 0 and localY >= 0 then
            local cellX = math.floor(localX / (fw + b)) + 1
            local cellY = math.floor(localY / (fh + b)) + 1
            
            local cols = math.floor((state.image:getWidth() - l) / (fw + b))
            local rows = math.floor((state.image:getHeight() - t) / (fh + b))
            
            if cellX <= cols and cellY <= rows then
                table.insert(state.selectedFrames, {x = cellX, y = cellY})
                logic.createAnimation()
            end
        end
    end
end

function viewport.draw()
    local imgX, imgY, fixW, fixH, panelX, panelW = viewport.getBounds()
    
    -- Draw middle panel background
    love.graphics.setColor(0.05, 0.05, 0.05, 1)
    love.graphics.rectangle("fill", panelX, 0, panelW, state.screenH)
    
    -- Draw drop zone / fixed place indicator
    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.rectangle("fill", imgX, imgY, fixW, fixH)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", imgX, imgY, fixW, fixH)
    love.graphics.setLineWidth(1)
    
    if not state.image then
        love.graphics.setColor(1, 1, 1, 0.5)
        if state.fontSmall then love.graphics.setFont(state.fontSmall) end
        love.graphics.printf("IMPORT SPRITESHEET HERE", imgX, imgY - 20, fixW, "center")
    end
    
    if state.image then
        local w, h = state.image:getDimensions()
        viewport.drawCheckerboard(imgX, imgY, w, h, 16)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(state.image, imgX, imgY)
        
        local fw = tonumber(state.inputState.frameWidth.text) or 32
        local fh = tonumber(state.inputState.frameHeight.text) or 32
        local l = tonumber(state.inputState.left.text) or 0
        local t = tonumber(state.inputState.top.text) or 0
        local b = tonumber(state.inputState.border.text) or 0
        
        local cols = math.floor((w - l) / (fw + b))
        local rows = math.floor((h - t) / (fh + b))
        
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.4, 0.4, 0.4, 0.4)
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                local cx = imgX + l + col * fw + (col + 1) * b
                local cy = imgY + t + row * fh + (row + 1) * b
                love.graphics.rectangle("line", cx, cy, fw, fh)
            end
        end
        
        for i, f in ipairs(state.selectedFrames) do
            local cx = imgX + l + (f.x - 1) * fw + f.x * b
            local cy = imgY + t + (f.y - 1) * fh + f.y * b
            
            love.graphics.setColor(0.9, 0.9, 0.9, 0.3)
            love.graphics.rectangle("fill", cx, cy, fw, fh)
            love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", cx, cy, fw, fh)
            love.graphics.setLineWidth(1)
            
            love.graphics.setColor(1, 1, 1, 1)
            if state.fontSmall then love.graphics.setFont(state.fontSmall) end
            local txt = tostring(i)
            local tw = state.fontSmall and state.fontSmall:getWidth(txt) or 10
            local th = state.fontSmall and state.fontSmall:getHeight() or 10
            
            love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
            love.graphics.rectangle("fill", cx + fw/2 - tw/2 - 4, cy + fh/2 - th/2 - 4, tw + 8, th + 8)
            love.graphics.setColor(0.95, 0.95, 0.95, 1)
            love.graphics.print(txt, cx + fw/2 - tw/2, cy + fh/2 - th/2)
        end
    end
end

return viewport
