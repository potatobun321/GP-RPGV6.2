-- core/camera.lua
-- Responsibility: Handles view translation, zooming profiles, and bounds clamping.

local Context = require('engine.core.context')

local Camera = {}

local State = {
    activeProfile = "gameplay",
    customBounds = nil,
    profiles = {
        gameplay = {
            x = 0, y = 0,
            zoomLevel = 1,          -- 1 is standard (2.0x scale)
            targetZoomLevel = 1,
            activeZoomLevel = nil,  -- for temp zoom (Shift+Z)
            scale = 2.0,            -- current lerped scale float
            _isFreeCam = false
        },
        editor = {
            x = 0, y = 0,
            scale = 2.0,            -- continuous float
            targetScale = 2.0,
            isFreeCam = true
        }
    }
}

function Camera.getScaleFromLevel(lvl)
    -- Levels map to exact integers: 0=1x, 1=2x, 2=3x, 3=4x, 4=5x, 5=6x
    return 1.0 + math.max(0, lvl)
end

setmetatable(Camera, {
    __index = function(t, k)
        if State[k] ~= nil then return State[k] end
        
        local p = State.profiles[State.activeProfile]
        if k == "x" then return p.x end
        if k == "y" then return p.y end
        if k == "scale" then return p.scale end
        
        if k == "isFreeCam" then
            if State.activeProfile == "editor" then return p.isFreeCam end
            return p._isFreeCam
        end
        
        return nil
    end,
    __newindex = function(t, k, v)
        if k == "activeProfile" or k == "customBounds" or k == "profiles" then 
            State[k] = v 
            return 
        end
        
        local p = State.profiles[State.activeProfile]
        if k == "x" then p.x = v return end
        if k == "y" then p.y = v return end
        if k == "scale" then p.scale = v return end
        
        if k == "isFreeCam" then
            if State.activeProfile == "editor" then p.isFreeCam = v
            else p._isFreeCam = v end
            return
        end
        
        rawset(t, k, v)
    end
})

function Camera:update(dt, targetX, targetY, world)
    local Editor = Context.editor
    local isEditorActive = Editor and Editor.isActive

    -- Profile Switching
    if isEditorActive and State.activeProfile == "gameplay" then
        State.activeProfile = "editor"
        -- Inherit position so the camera doesn't teleport
        State.profiles.editor.x = State.profiles.gameplay.x
        State.profiles.editor.y = State.profiles.gameplay.y
        State.profiles.editor.scale = State.profiles.gameplay.scale
        State.profiles.editor.targetScale = State.profiles.gameplay.scale
    elseif not isEditorActive and State.activeProfile == "editor" then
        State.activeProfile = "gameplay"
    end

    local p = State.profiles[State.activeProfile]

    if State.activeProfile == "editor" then
        if love.keyboard.isDown("0") and world then
            local sw = love.graphics.getWidth()
            local sh = love.graphics.getHeight()
            local mw = world.width * world.tileSize
            local mh = world.height * world.tileSize
            p.targetScale = math.min(sw / mw, sh / mh)
        end
        
        p.scale = p.scale + (p.targetScale - p.scale) * 10 * dt

    elseif State.activeProfile == "gameplay" then
        -- Zoom logic (Discrete)
        local finalTargetZoom = p.zoomLevel
        if p.tempZoomActive then
            finalTargetZoom = p.activeZoomLevel or (p.zoomLevel + 1)
        end

        local targetScale = self.getScaleFromLevel(finalTargetZoom)
        p.scale = p.scale + (targetScale - p.scale) * 10 * dt

        -- Movement Logic
        if p._isFreeCam then
            local camSpeed = 400 / p.scale
            if love.keyboard.isDown("left") then p.x = p.x - camSpeed * dt end
            if love.keyboard.isDown("right") then p.x = p.x + camSpeed * dt end
            if love.keyboard.isDown("up") then p.y = p.y - camSpeed * dt end
            if love.keyboard.isDown("down") then p.y = p.y + camSpeed * dt end
        else
            p.x = p.x + (targetX - p.x) * 5 * dt
            p.y = p.y + (targetY - p.y) * 5 * dt
        end

        -- Bounds Logic
        if world then
            local minX, maxX, minY, maxY
            
            if State.customBounds and not p._isFreeCam then
                minX, maxX, minY, maxY = State.customBounds[1], State.customBounds[2], State.customBounds[3], State.customBounds[4]
            else
                minX = -math.floor(world.width / 2) * world.tileSize
                maxX = math.ceil(world.width / 2) * world.tileSize
                minY = -math.floor(world.height / 2) * world.tileSize
                maxY = math.ceil(world.height / 2) * world.tileSize
            end

            if not p._isFreeCam then
                local hw = (love.graphics.getWidth() / 2) / p.scale
                local hh = (love.graphics.getHeight() / 2) / p.scale
                
                if (maxX - minX) < (hw * 2) then
                    p.x = (minX + maxX) / 2
                else
                    if p.x - hw < minX then p.x = minX + hw end
                    if p.x + hw > maxX then p.x = maxX - hw end
                end

                if (maxY - minY) < (hh * 2) then
                    p.y = (minY + maxY) / 2
                else
                    if p.y - hh < minY then p.y = minY + hh end
                    if p.y + hh > maxY then p.y = maxY - hh end
                end
            end
        end
    end
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    love.graphics.scale(self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:detach()
    love.graphics.pop()
end

return Camera