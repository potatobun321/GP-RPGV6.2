-- engine/world/map_registry.lua
local MapRegistry = {}

function MapRegistry.getPlayableMaps()
    local mapSet = {}
    
    local function scanDir(dir)
        local info = love.filesystem.getInfo(dir)
        if not info or info.type ~= "directory" then return end
        
        for _, f in ipairs(love.filesystem.getDirectoryItems(dir)) do
            local name = f:match("(.+)%.json$") or f:match("(.+)%.lua$")
            -- Exclude template map from playable maps
            if name and name ~= "template" then
                mapSet[name] = true
            end
        end
    end
    
    scanDir("content/maps")
    scanDir("maps") -- save directory
    
    local mapList = {}
    for name in pairs(mapSet) do
        table.insert(mapList, name)
    end
    table.sort(mapList)
    
    return mapList
end

return MapRegistry
