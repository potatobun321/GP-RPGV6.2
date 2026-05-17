local Registry = require("ecs.registry")
local Components = require("ecs.components")

local Object = {
    tiles = {},
    characters = {}
}

local function safeLoad(path)
    local success, img = pcall(love.graphics.newImage, path)
    if success then
        img:setFilter("nearest", "nearest")
        return img
    end
    return nil
end

function Object.load()
    -- Dynamically load all tiles from the world/tiles directory
    local files = love.filesystem.getDirectoryItems("world/tiles")
    for _, file in ipairs(files) do
        if file:sub(-4) == ".lua" and file ~= "template.lua" then
            local chunk = love.filesystem.load("world/tiles/" .. file)
            if chunk then
                local tileDef = chunk()
                if tileDef and tileDef.id then
                    if tileDef.texturePath then
                        tileDef.texture = safeLoad(tileDef.texturePath)
                    end
                    Object.tiles[tileDef.id] = tileDef
                end
            end
        end
    end
    
    -- Characters
    Object.characters.player = {
        name = "Player", speed = 200,
        colorKey = "player", draw_style = "fill",
        texture = safeLoad("assets/characters/player.png")
    }
end

function Object.getTile(id)
    return Object.tiles[id] or Object.tiles["void"]
end

function Object.getCharacter(id)
    return Object.characters[id]
end

function Object.createTileEntity(gridX, gridY, size, typeId)
    local id = Registry.create()
    local tpl = Object.getTile(typeId)
    
    local px = gridX * size
    local py = gridY * size
    
    Registry.add(id, "Transform", Components.Transform(px, py, size, size))
    Registry.add(id, "Renderable", Components.Renderable("tile", tpl.colorKey, tpl.texture, tpl.draw_style))
    
    local flags = tpl.flags or {}
    Registry.add(id, "TileData", { gridX=gridX, gridY=gridY, typeId=typeId, solid=tpl.is_solid, speedMod=tpl.speed_mod, flags=flags })
    
    return id
end

function Object.createCharacterEntity(px, py, typeId)
    local id = Registry.create()
    local tpl = Object.getCharacter(typeId)
    
    Registry.add(id, "Transform", Components.Transform(px, py, 24, 24))
    Registry.add(id, "Velocity", Components.Velocity(0, 0, tpl.speed))
    Registry.add(id, "Renderable", Components.Renderable("character", tpl.colorKey, tpl.texture, tpl.draw_style))
    Registry.add(id, "Health", Components.Health(100, 100))
    
    return id
end

return Object
