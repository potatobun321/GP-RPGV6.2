-- Fix #27: require at file top so isSolidPixel/setTile don't re-require every frame
local Registry = require("ecs.registry")
local Factory  = require("core.factory")

local Tilemap = {}
Tilemap.__index = Tilemap

function Tilemap.new(w, h, size)
    local self = setmetatable({}, Tilemap)
    self.width    = w    or 31
    self.height   = h    or 31
    self.tileSize = size or 32
    self.grid     = {}
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
end

function Tilemap:saveMap(mapName)
    local tiles   = Registry.query("TileData")
    
    local mapData = {
        name = mapName,
        width = self.width,
        height = self.height,
        tileSize = self.tileSize,
        tiles = {}
    }
    
    local gridData = {}
    for _, id in ipairs(tiles) do
        local tdata = Registry.get(id, "TileData")
        if tdata then
            local tDef = Factory.getTile(tdata.typeId)
            local defaults = tDef.flags or {}
            
            local customFlags = nil
            for k, v in pairs(tdata.flags) do
                if defaults[k] ~= v then
                    if not customFlags then customFlags = {} end
                    customFlags[k] = v
                end
            end
            
            local y = tdata.gridY
            if not gridData[y] then gridData[y] = {} end
            table.insert(gridData[y], {x = tdata.gridX, id = tdata.typeId, flags = customFlags})
        end
    end
    
    local function flagsMatch(f1, f2)
        if f1 == nil and f2 == nil then return true end
        if f1 == nil or f2 == nil then return false end
        for k, v in pairs(f1) do if f2[k] ~= v then return false end end
        for k, v in pairs(f2) do if f1[k] ~= v then return false end end
        return true
    end

    for y, row in pairs(gridData) do
        table.sort(row, function(a, b) return a.x < b.x end)
        local run = nil
        for _, t in ipairs(row) do
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
    
    local function serialize(val, indent, inline)
        indent = indent or ""
        local nextIndent = indent .. "    "
        if inline then nextIndent = "" end
        local newline = inline and "" or "\n"
        
        if type(val) == "string" then
            return string.format("%q", val)
        elseif type(val) == "number" or type(val) == "boolean" then
            return tostring(val)
        elseif type(val) == "table" then
            local isTileEntry = (val.x and val.y and val.id)
            if isTileEntry then
                local parts = {}
                for _, k in ipairs({"x", "y", "len", "id"}) do
                    if val[k] ~= nil then table.insert(parts, k .. "=" .. serialize(val[k], "", true)) end
                end
                if val.flags then table.insert(parts, "flags=" .. serialize(val.flags, "", true)) end
                return "{" .. table.concat(parts, ", ") .. "}"
            end
            
            local str = "{" .. newline
            local isArray = true
            local maxIndex = 0
            for k, v in pairs(val) do
                if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                    isArray = false
                    break
                end
                if k > maxIndex then maxIndex = k end
            end
            
            if isArray then
                for i = 1, maxIndex do
                    str = str .. nextIndent .. serialize(val[i], nextIndent, inline) .. "," .. newline
                end
            else
                for k, v in pairs(val) do
                    local keyStr = type(k) == "string" and k:match("^[%a_][%w_]*$") and k or "[" .. serialize(k, "", true) .. "]"
                    str = str .. nextIndent .. keyStr .. " = " .. serialize(v, nextIndent, inline) .. "," .. newline
                end
            end
            return str .. (inline and "}" or indent .. "}")
        end
        return "nil"
    end
    
    local str = "return " .. serialize(mapData) .. "\n"
    
    local path = love.filesystem.getSource() .. "/world/maps/" .. mapName .. ".lua"
    local f, err = io.open(path, "w")
    if not f then
        path = "world/maps/" .. mapName .. ".lua"
        f, err = io.open(path, "w")
    end
    
    if f then
        f:write(str)
        f:close()
        print("Saved map: " .. path)
    else
        print("Failed to save map: " .. tostring(err))
    end
end

function Tilemap:loadMap(mapName)
    self:clear()
    
    local path  = love.filesystem.getSource() .. "/world/maps/" .. mapName .. ".lua"
    local chunk, err = loadfile(path)
    if not chunk then
        path = "world/maps/" .. mapName .. ".lua"
        chunk, err = loadfile(path)
    end
    
    if not chunk then
        print("Map " .. mapName .. " not found. Generating fallback canvas.")
        self.width = 31
        self.height = 31
        
        local minX = -math.floor(self.width / 2)
        local maxX = math.ceil(self.width / 2) - 1
        local minY = -math.floor(self.height / 2)
        local maxY = math.ceil(self.height / 2) - 1
        
        for y = minY, maxY do
            self.grid[y] = {}
            for x = minX, maxX do
                local typeId = "grass"
                if x == minX or x == maxX or y == minY or y == maxY then
                    typeId = "wall"
                end
                local id = Factory.createTileEntity(x, y, self.tileSize, typeId)
                self.grid[y][x] = id
            end
        end
        return
    end
    
    local mapData = chunk()
    self.width = mapData.width
    self.height = mapData.height
    self.tileSize = mapData.tileSize or 32
    
    for k, v in pairs(mapData.tiles) do
        if type(k) == "string" then
            -- Backwards compatibility for old hashmap format
            local x, y = k:match("([^,]+),([^,]+)")
            x, y = tonumber(x), tonumber(y)
            if not self.grid[y] then self.grid[y] = {} end
            
            local typeId = type(v) == "string" and v or v.id
            local customFlags = type(v) == "table" and v.flags or nil
            
            local id = Factory.createTileEntity(x, y, self.tileSize, typeId, customFlags)
            self.grid[y][x] = id
        else
            -- New array of objects format + RLE
            local x, y = v.x, v.y
            local length = v.len or 1
            if not self.grid[y] then self.grid[y] = {} end
            
            for i = 0, length - 1 do
                local id = Factory.createTileEntity(x + i, y, self.tileSize, v.id, v.flags)
                self.grid[y][x + i] = id
            end
        end
    end
    print("Loaded map: " .. mapName)
end

function Tilemap:getTileEntity(gx, gy)
    if self.grid[gy] and self.grid[gy][gx] then
        return self.grid[gy][gx]
    end
    return nil
end

function Tilemap:setTile(gx, gy, typeId, customFlags)
    if self.grid[gy] and self.grid[gy][gx] then
        Registry.remove(self.grid[gy][gx])
    end
    if not self.grid[gy] then self.grid[gy] = {} end
    self.grid[gy][gx] = Factory.createTileEntity(gx, gy, self.tileSize, typeId, customFlags)
end

function Tilemap:isSolidPixel(px, py, w, h)
    local minX = math.floor(px / self.tileSize)
    local maxX = math.floor((px + w - 0.01) / self.tileSize)
    local minY = math.floor(py / self.tileSize)
    local maxY = math.floor((py + h - 0.01) / self.tileSize)
    
    for gy = minY, maxY do
        for gx = minX, maxX do
            local tid = self:getTileEntity(gx, gy)
            if tid then
                local tdata = Registry.get(tid, "TileData")
                if tdata and tdata.flags and tdata.flags.solid then return true end
            else
                return true  -- void = solid boundary
            end
        end
    end
    return false
end

function Tilemap:draw()
    love.graphics.setColor(1, 1, 1, 0.1)
    local w    = self.width  * self.tileSize
    local h    = self.height * self.tileSize
    local minX = -math.floor(self.width  / 2) * self.tileSize
    local minY = -math.floor(self.height / 2) * self.tileSize
    love.graphics.rectangle("line", minX, minY, w, h)
end

-- Fix #28: removed empty update(dt) stub

return Tilemap