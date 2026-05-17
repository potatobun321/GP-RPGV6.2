-- world/world.lua
local Tilemap = require("world.tilemap")

local World = {}
World.__index = World

function World.new()
    local self = setmetatable({}, World)
    -- Default: Square Dungeon (30x30)
    self.map = Tilemap.new(30, 30, 32)
    return self
end

function World:resize(w, h)
    self.map:resize(w, h)
end

function World:setTileSize(sz)
    self.map.tileSize = sz
end

-- Logic: Ensure an entity is inside the Pixel Bounds of the world
function World:clampEntity(e)
    local worldPixelW = self.map.width * self.map.tileSize
    local worldPixelH = self.map.height * self.map.tileSize
    
    -- Keep inside (with a small buffer for walls)
    local buffer = self.map.tileSize
    if e.x < buffer then e.x = buffer end
    if e.y < buffer then e.y = buffer end
    if e.x > worldPixelW - buffer - e.w then e.x = worldPixelW - buffer - e.w end
    if e.y > worldPixelH - buffer - e.h then e.y = worldPixelH - buffer - e.h end
end

function World:isSolid(x, y, w, h)
    local pts = {{x,y}, {x+w,y}, {x,y+h}, {x+w,y+h}}
    for _, p in ipairs(pts) do
        if self.map:getTileAtPixel(p[1], p[2]) == Tilemap.TILE_WALL then return true end
    end
    return false
end

function World:checkInteraction(x, y, w, h)
    local cx, cy = x + w/2, y + h/2
    local t, gx, gy = self.map:getTileAtPixel(cx, cy)
    if t == Tilemap.TILE_INTERACT then return true, gx, gy end
    return false
end

function World:update(dt) end

function World:draw() self.map:draw() end

return World