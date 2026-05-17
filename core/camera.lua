-- core/camera.lua
-- Responsibility: Handles view translation (following the player)

local Context = require("core.context")

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
        -- Editor just opened: force freecam and remember it was us who set it
        if not self._editorFreeCam then
            self._editorFreeCam = true
            self.isFreeCam = true
        end
        if love.keyboard.isDown("-") then self.baseScale = math.max(0.2, self.baseScale - 2 * dt) end
        if love.keyboard.isDown("=") or love.keyboard.isDown("+") then self.baseScale = math.min(10, self.baseScale + 2 * dt) end
        self.targetScale = self.baseScale
    else
        -- Editor just closed: release the freecam lock we set, but respect Shift+Z toggle
        if self._editorFreeCam then
            self._editorFreeCam = false
            self.isFreeCam = false
        end
        if love.keyboard.isDown("z") and not (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            self.targetScale = self.baseScale + 1.0
        elseif self.activeScale then
            self.targetScale = self.activeScale
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
        local hw = (love.graphics.getWidth() / 2) / self.scale
        local hh = (love.graphics.getHeight() / 2) / self.scale
        
        local minX, maxX, minY, maxY
        if self.customBounds then
            minX, maxX, minY, maxY = self.customBounds[1], self.customBounds[2], self.customBounds[3], self.customBounds[4]
        else
            minX = -math.floor(world.width / 2) * world.tileSize
            maxX = math.ceil(world.width / 2) * world.tileSize
            minY = -math.floor(world.height / 2) * world.tileSize
            maxY = math.ceil(world.height / 2) * world.tileSize
        end
        
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