-- engine/core/assets.lua
local Assets = {
    images = {}
}

function Assets.getImage(path)
    if not path or path == "" then return nil end
    if Assets.images[path] then
        return Assets.images[path]
    end
    
    local success, img = pcall(love.graphics.newImage, path)
    if success then
        img:setFilter("nearest", "nearest")
        Assets.images[path] = img
        return img
    end
    return nil
end

function Assets.clear()
    Assets.images = {}
end

function Assets.getMapData(mapName)
    local json = require('lib.json')
    local mapData = nil
    
    local savePath = "maps/" .. mapName .. ".json"
    if love.filesystem.getInfo(savePath) then
        local content = love.filesystem.read(savePath)
        if content then mapData = json.decode(content) end
    end
    
    if not mapData then
        local content = love.filesystem.read("content/maps/" .. mapName .. ".json")
        if content then
            mapData = json.decode(content)
        end
    end
    
    if not mapData then
        local chunk = love.filesystem.load("content/maps/" .. mapName .. ".lua")
        if chunk then
            local ok, data = pcall(chunk)
            if ok and type(data) == "table" then mapData = data end
        end
    end
    
    return mapData
end

return Assets
