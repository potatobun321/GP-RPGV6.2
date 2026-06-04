-- core/camera.lua
-- Responsibility: Handles view translation (following the player)

local Context = require('engine.core.context')

local Camera = {
    x = 0, y = 0,
    scale = 2.0, targetScale = 2.0,
    baseScale = 2.0, activeScale = nil,
    customBounds = nil,
    isFreeCam = false
}

function Camera:update(dt, targetX, targetY, world)
    local Editor = Context.editor
    if Editor and Editor.isActive then
        -- Editor just opened: force freecam and remember previous state
        if self._savedFreeCam == nil then
            self._savedFreeCam = self.isFreeCam
            self.isFreeCam = true
        end
        if love.keyboard.isDown("-") then self.baseScale = math.max(0.2, self.baseScale - 2 * dt) end
        if love.keyboard.isDown("=") or love.keyboard.isDown("+") then self.baseScale = math.min(10, self.baseScale + 2 * dt) end
        self.targetScale = self.baseScale
    else
        -- Editor just closed: restore previous freecam state
        if self._savedFreeCam ~= nil then
            self.isFreeCam = self._savedFreeCam
            self._savedFreeCam = nil
        end
        
        -- Temporary zoom via Shift+Z key overrides everything with `activeScale`
        local shiftDown = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
        if love.keyboard.isDown("z") and shiftDown then
            self.targetScale = self.activeScale or (self.baseScale + 1.0)
        else
            self.targetScale = self.baseScale
        end
    end
    self.scale = self.scale + (self.targetScale - self.scale) * 10 * dt
    
    local tx, ty
    if self.isFreeCam then
        local camSpeed = 400 / self.scale
        if love.keyboard.isDown("left") then self.x = self.x - camSpeed * dt end
        if love.keyboard.isDown("right") then self.x = self.x + camSpeed * dt end
        if love.keyboard.isDown("up") then self.y = self.y - camSpeed * dt end
        if love.keyboard.isDown("down") then self.y = self.y + camSpeed * dt end
    else
        tx, ty = targetX, targetY
        self.x = self.x + (tx - self.x) * 5 * dt
        self.y = self.y + (ty - self.y) * 5 * dt
    end

    if world then
        local minX, maxX, minY, maxY
        
        -- Ignore custom bounds if we are in Free Camera or Editor mode
        if self.customBounds and not self.isFreeCam then
            minX, maxX, minY, maxY = self.customBounds[1], self.customBounds[2], self.customBounds[3], self.customBounds[4]
        else
            minX = -math.floor(world.width / 2) * world.tileSize
            maxX = math.ceil(world.width / 2) * world.tileSize
            minY = -math.floor(world.height / 2) * world.tileSize
            maxY = math.ceil(world.height / 2) * world.tileSize
        end
        
        -- If bounded, we CANNOT let the user zoom out so far that the screen 
        -- becomes larger than the bounded area itself. Clamp the minimum scale.
        if not self.isFreeCam then
            local minScaleX = love.graphics.getWidth() / (maxX - minX)
            local minScaleY = love.graphics.getHeight() / (maxY - minY)
            local minRequiredScale = math.max(minScaleX, minScaleY)
            
            if self.scale < minRequiredScale then
                self.scale = minRequiredScale
            end
        end

        local hw = (love.graphics.getWidth() / 2) / self.scale
        local hh = (love.graphics.getHeight() / 2) / self.scale
        
        if self.x - hw < minX then self.x = minX + hw end
        if self.x + hw > maxX then self.x = maxX - hw end
        if self.y - hh < minY then self.y = minY + hh end
        if self.y + hh > maxY then self.y = maxY - hh end
        
        if (maxX - minX) < (hw * 2) then self.x = (minX + maxX) / 2 end
        if (maxY - minY) < (hh * 2) then self.y = (minY + maxY) / 2 end
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