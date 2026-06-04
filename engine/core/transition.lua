-- core/transition.lua
local Factory = require('engine.core.factory')
local Console = require('engine.core.console')
local Context = require('engine.core.context')

local Transition = {}

-- excludeX, excludeY: when searching the same map, skip the origin tile so we
-- don't teleport a player back to the exact tile they stepped on.
function Transition.findReturnTile(targetMap, currentMap, targetLinkId, excludeX, excludeY)
    local sameMap = (targetMap == currentMap)

    if sameMap then
        local grid = _G.game and _G.game.world and _G.game.world.grid
        if grid then
            for gy, row in pairs(grid) do
                for gx, tdata in pairs(row) do
                    if tdata.typeId == "scene" then
                        if excludeX and excludeY and gx == excludeX and gy == excludeY then
                            -- skip origin tile
                        else
                            local defaults = Factory.getTile("scene").flags or {}
                            local finalLinkId = (tdata.flags and tdata.flags.linkId) or defaults.linkId
                            if finalLinkId == targetLinkId then
                                return gx, gy
                            end
                        end
                    end
                end
            end
        end
        return nil, nil
    end

    -- If different map, load from disk
    local mapData = nil
    local json = require('lib.json')
    
    local savePath = "maps/" .. targetMap .. ".json"
    if love.filesystem.getInfo(savePath) then
        local content = love.filesystem.read(savePath)
        if content then mapData = json.decode(content) end
    end
    
    if not mapData then
        local content = love.filesystem.read("content/maps/" .. targetMap .. ".json")
        if content then mapData = json.decode(content) end
    end
    
    if not mapData then
        local chunk = love.filesystem.load("content/maps/" .. targetMap .. ".lua")
        if chunk then
            local ok, data = pcall(chunk)
            if ok and type(data) == "table" then mapData = data end
        end
    end
    
    if not mapData or not mapData.tiles then return nil, nil end

    for k, v in pairs(mapData.tiles) do
        local t_id, t_flags, t_x, t_y, t_len

        if type(k) == "number" then
            if type(v) == "table" then
                t_id    = v.id
                t_flags = v.flags
                t_x, t_y = v.x, v.y
                t_len   = v.len or 1
            end
        else
            if type(v) == "table" then
                t_id    = v.id
                t_flags = v.flags
            else
                t_id = v
            end
            local sx, sy = k:match("([^,]+),([^,]+)")
            t_x, t_y = tonumber(sx), tonumber(sy)
            t_len = 1
        end

        if t_id == "scene" then
            local defaults    = Factory.getTile("scene").flags or {}
            local finalLinkId = (t_flags and t_flags.linkId) or defaults.linkId
            if finalLinkId == targetLinkId then
                -- Support RLE: Return the center of the link tile run if it's multiple tiles wide
                return t_x + math.floor((t_len - 1) / 2), t_y
            end
        end
    end

    return nil, nil
end

-- gx, gy: the tile grid-position the player is currently standing on.
-- Required so same-map links know which tile to EXCLUDE from the search.
function Transition.execute(tileData, gx, gy)
    if not _G.Event or Context.transitioning then return end

    local targetMap  = tileData.flags.targetMap
    local currentMap = _G.game and _G.game.currentMapName or "map1"
    local linkId     = tileData.flags.linkId or "A"

    if not targetMap then
        Console.log("Link Tile has no targetMap set!", {1, 0.4, 0.4})
        return
    end

    local rx, ry = Transition.findReturnTile(targetMap, currentMap, linkId, gx, gy)

    if rx and ry then
        Context.transitioning = true
        _G.Event.fire("change_map", targetMap, rx, ry)
    else
        Context.transitioning = false
        Console.log(
            "Link '" .. linkId .. "' not found in '" .. targetMap .. "' " ..
            "(check both tiles have matching Link IDs)",
            {1, 0.2, 0.2})
    end
end

return Transition
