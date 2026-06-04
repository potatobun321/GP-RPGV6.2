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

return Assets
