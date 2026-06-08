local Registry = require('engine.ecs.registry')
local Factory  = require('engine.core.factory')
local Context  = require('engine.core.context')

local Tilemap = {}
Tilemap.__index = Tilemap

function Tilemap.new(w, h, size)
    local self = setmetatable({}, Tilemap)
    self.width    = w    or 31
    self.height   = h    or 31
    self.tileSize = size or 32
    self.grid     = {}
    self.tileBatches = {}
    self.untexturedTiles = {}
    return self
end

function Tilemap:clear()
    local toRemove = {}
    for id, comps in pairs(Registry.entities) do
        if not comps.Persistent then
            table.insert(toRemove, id)
        end
    end
    for _, id in ipairs(toRemove) do
        Registry.remove(id)
    end
    self.grid = {}
    self.tileBatches = {}
    self.untexturedTiles = {}
    Context.mapDirty = true
end

function Tilemap:saveMap(mapName)
    local mapData = {
        name = mapName,
        width = self.width,
        height = self.height,
        tileSize = self.tileSize,
        zoomLevel = require('engine.core.camera').profiles.gameplay.zoomLevel,
        customBounds = require('engine.core.camera').customBounds,
        tiles = {}
    }
    
    local function flagsMatch(f1, f2)
        if f1 == nil and f2 == nil then return true end
        if f1 == nil or f2 == nil then return false end
        for k, v in pairs(f1) do if f2[k] ~= v then return false end end
        for k, v in pairs(f2) do if f1[k] ~= v then return false end end
        return true
    end

    for y, row in pairs(self.grid) do
        local sortedRow = {}
        for x, tdata in pairs(row) do
            local tDef = Factory.getTile(tdata.typeId)
            local defaults = tDef.flags or {}
            local customFlags = nil
            if tdata.flags then
                for k, v in pairs(tdata.flags) do
                    if defaults[k] ~= v then
                        if not customFlags then customFlags = {} end
                        customFlags[k] = v
                    end
                end
            end
            table.insert(sortedRow, {x = x, id = tdata.typeId, flags = customFlags})
        end
        table.sort(sortedRow, function(a, b) return a.x < b.x end)
        
        local run = nil
        for _, t in ipairs(sortedRow) do
            if not run then
                run = {x = t.x, y = y, len = 1, id = t.id, flags = t.flags}
            elseif t.x == run.x + run.len and t.id == run.id and flagsMatch(t.flags, run.flags) then
                run.len = run.len + 1
            else
                table.insert(mapData.tiles, run)
                run = {x = t.x, y = y, len = 1, id = t.id, flags = t.flags}
            end
        end
        if run then table.insert(mapData.tiles, run) end
    end
    
    local json = require('lib.json')
    local str = json.encode(mapData)
    
    local devPath = love.filesystem.getSource() .. "/content/maps/" .. mapName .. ".json"
    local f, err = io.open(devPath, "w")
    if f then
        f:write(str)
        f:close()
        print("Saved map (dev mode): " .. devPath)
    else
        love.filesystem.createDirectory("maps")
        local success, msg = love.filesystem.write("maps/" .. mapName .. ".json", str)
        if success then
            print("Saved map (save dir): maps/" .. mapName .. ".json")
        else
            print("Failed to save map: " .. tostring(msg))
        end
    end
end

function Tilemap:loadMap(mapName)
    self:clear()
    
    local Assets = require('engine.core.assets')
    local mapData = Assets.getMapData(mapName)
    
    if not mapData then
        print("Error: Map '" .. mapName .. "' not found.")
        return false
    end
    self.width = mapData.width
    self.height = mapData.height
    self.tileSize = mapData.tileSize or 32
    
    self.mapZoomLevel = nil
    if mapData.zoomLevel then
        self.mapZoomLevel = mapData.zoomLevel
    elseif mapData.baseScale then
        -- Legacy support: convert baseScale float directly to discrete zoomLevel ladder
        self.mapZoomLevel = math.floor(mapData.baseScale - 1.0 + 0.5)
    end
    self.customBounds = mapData.customBounds or nil
    
    for k, v in pairs(mapData.tiles) do
        if type(k) == "string" then
            local x, y = k:match("([^,]+),([^,]+)")
            x, y = tonumber(x), tonumber(y)
            local typeId = type(v) == "string" and v or v.id
            local customFlags = type(v) == "table" and v.flags or nil
            self:setTile(x, y, typeId, customFlags)
        else
            local x, y = v.x, v.y
            local length = v.len or 1
            for i = 0, length - 1 do
                self:setTile(x + i, y, v.id, v.flags)
            end
        end
    end
    Context.mapDirty = true
    print("Loaded map: " .. mapName)
end

function Tilemap:getTileData(gx, gy)
    if self.grid[gy] and self.grid[gy][gx] then
        return self.grid[gy][gx]
    end
    return nil
end

function Tilemap:setTile(gx, gy, typeId, customFlags)
    if not self.grid[gy] then self.grid[gy] = {} end
    
    local currentMinX = -math.floor(self.width / 2)
    local currentMaxX = math.ceil(self.width / 2) - 1
    local currentMinY = -math.floor(self.height / 2)
    local currentMaxY = math.ceil(self.height / 2) - 1

    if gx < currentMinX or gx > currentMaxX then
        local newMinX = math.min(currentMinX, gx)
        local newMaxX = math.max(currentMaxX, gx)
        self.width = math.max(math.abs(newMinX) * 2, (newMaxX + 1) * 2)
    end
    if gy < currentMinY or gy > currentMaxY then
        local newMinY = math.min(currentMinY, gy)
        local newMaxY = math.max(currentMaxY, gy)
        self.height = math.max(math.abs(newMinY) * 2, (newMaxY + 1) * 2)
    end

    local tpl = Factory.getTile(typeId)
    local finalFlags = {}
    for k, v in pairs(tpl.flags or {}) do finalFlags[k] = v end
    if customFlags then
        for k, v in pairs(customFlags) do finalFlags[k] = v end
    end
    
    self.grid[gy][gx] = { typeId = typeId, flags = finalFlags, gridX = gx, gridY = gy }
    Context.mapDirty = true
end

function Tilemap:isSolidPixel(px, py, w, h)
    local minX = math.floor(px / self.tileSize)
    local maxX = math.floor((px + w - 0.01) / self.tileSize)
    local minY = math.floor(py / self.tileSize)
    local maxY = math.floor((py + h - 0.01) / self.tileSize)
    
    for gy = minY, maxY do
        for gx = minX, maxX do
            local tdata = self:getTileData(gx, gy)
            if tdata and tdata.flags and tdata.flags.solid then return true end
            if not tdata then return true end
        end
    end
    return false
end

function Tilemap:draw()
    if Context.mapDirty then
        self.tileBatches = {}
        self.untexturedTiles = {}
        
        for y, row in pairs(self.grid) do
            for x, tdata in pairs(row) do
                local tpl = Factory.getTile(tdata.typeId)
                local px = x * self.tileSize
                local py = y * self.tileSize
                
                if tpl.texture then
                    if not self.tileBatches[tpl.texture] then
                        self.tileBatches[tpl.texture] = love.graphics.newSpriteBatch(tpl.texture, 10000, "static")
                    end
                    local scaleX = self.tileSize / tpl.texture:getWidth()
                    local scaleY = self.tileSize / tpl.texture:getHeight()
                    self.tileBatches[tpl.texture]:add(px, py, 0, scaleX, scaleY)
                else
                    table.insert(self.untexturedTiles, {px=px, py=py, typeId=tdata.typeId, tpl=tpl})
                end
            end
        end
        Context.mapDirty = false
    end
    
    local Theme = require('engine.core.theme')
    local colors = Theme.get()
    
    love.graphics.setColor(1, 1, 1, 1)
    if self.tileBatches then
        for tex, batch in pairs(self.tileBatches) do
            love.graphics.draw(batch, 0, 0)
        end
    end
    
    if self.untexturedTiles then
        for _, t in ipairs(self.untexturedTiles) do
            local c = colors[t.tpl.colorKey] or {1, 0, 1}
            if t.tpl.draw_style == "line" then
                love.graphics.setColor(c[1], c[2], c[3], 0.2)
                love.graphics.rectangle("line", t.px, t.py, self.tileSize, self.tileSize)
            else
                love.graphics.setColor(c)
                love.graphics.rectangle("fill", t.px, t.py, self.tileSize, self.tileSize)
            end
        end
    end
end

return Tilemap