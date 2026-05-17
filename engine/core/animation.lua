-- core/animation.lua
-- ═══════════════════════════════════════════════════════════════════════════
--  Animation Manager
--
--  Loading priority:
--    1.  content/characters/<entity>/animations.lua  — unified manifest (new)
--    2.  content/characters/<entity>/<name>.lua      — individual files (legacy)
--
--  Always use the unified manifest for new characters. The legacy path exists
--  only to avoid breaking old projects.
-- ═══════════════════════════════════════════════════════════════════════════

local anim8 = require 'lib.anim8.anim8'

local AnimationManager = {
    cache = {}
}

-- ── Internal: build anims table from a unified manifest ───────────────────
local function loadFromManifest(manifest, image)
    local anims = {}
    for name, def in pairs(manifest.animations or {}) do
        local ok, g = pcall(function()
            return anim8.newGrid(
                def.frameW  or 32,
                def.frameH  or 32,
                image:getWidth(),
                image:getHeight(),
                def.left   or 0,
                def.top    or 0,
                def.border or 0
            )
        end)
        if not ok then
            print("[AnimationManager] Grid error for '" .. name .. "': " .. tostring(g))
        else
            -- Build frame-coordinate list from the stored string "1,1, 2,1, 3,1"
            local coords = {}
            for n in (def.frames or "1,1"):gmatch("[^,%s]+") do
                table.insert(coords, tonumber(n))
            end
            local ok2, anim = pcall(function()
                return anim8.newAnimation(g(unpack(coords)), def.duration or 0.1)
            end)
            if ok2 then
                anims[name] = anim
            else
                print("[AnimationManager] Anim error for '" .. name .. "': " .. tostring(anim))
            end
        end
    end
    return anims
end

-- ── Internal: legacy loader — one .lua file per animation ─────────────────
local function loadLegacy(entityType, image)
    local anims = {}
    local files = love.filesystem.getDirectoryItems("content/characters/" .. entityType)
    for _, file in ipairs(files) do
        if file:sub(-4) == ".lua"
            and file ~= "bindings.lua"
            and file ~= "animations.lua" then
            local animName = file:sub(1, -5)
            local path = "content.characters." .. entityType .. "." .. animName
            local success, animFunc = pcall(require, path)
            if success and type(animFunc) == "function" then
                anims[animName] = animFunc(image)
            end
        end
    end
    return anims
end

-- ── Public: load animation bundle for an entity type ─────────────────────
function AnimationManager.load(entityType)
    if AnimationManager.cache[entityType] then
        return AnimationManager.cache[entityType]
    end

    -- Determine image path
    local imgPath = "content/characters/" .. entityType .. "/spritesheet.png"
    local successImg, image = pcall(love.graphics.newImage, imgPath)
    if not successImg then
        print("[AnimationManager] No spritesheet found for: " .. entityType)
        return nil
    end
    image:setFilter("nearest", "nearest")

    -- Prefer unified manifest
    local anims
    local manifestPath = "content.characters." .. entityType .. ".animations"
    local ok, manifest = pcall(require, manifestPath)
    if ok and type(manifest) == "table" and manifest.animations then
        print("[AnimationManager] Loading from unified manifest: " .. entityType)
        anims = loadFromManifest(manifest, image)
    else
        -- Fallback to legacy individual files
        print("[AnimationManager] Loading legacy individual files: " .. entityType)
        anims = loadLegacy(entityType, image)
    end

    -- Load optional bindings
    local bindings = nil
    local bindPath = "content.characters." .. entityType .. ".bindings"
    local bok, b = pcall(require, bindPath)
    if bok and type(b) == "table" then
        bindings = b
    end

    local animData = { image = image, anims = anims, bindings = bindings }
    AnimationManager.cache[entityType] = animData
    return animData
end

-- ── Public: invalidate cache for an entity (call after Anim8tor saves) ────
function AnimationManager.invalidate(entityType)
    AnimationManager.cache[entityType] = nil
    -- Also clear require cache so the manifest is re-read fresh
    local manifestKey = "content.characters." .. entityType .. ".animations"
    package.loaded[manifestKey] = nil
end

-- ── Public: verify all animated factory entries have bundles ──────────────
function AnimationManager.verifyAll(factoryModule)
    local missing = {}
    for id, tpl in pairs(factoryModule.characters) do
        if tpl.animated then
            local data = AnimationManager.load(id)
            if not data or not data.anims or next(data.anims) == nil then
                table.insert(missing, id)
            end
        end
    end
    if #missing > 0 then
        error("CRITICAL: Missing animation bundles for: " .. table.concat(missing, ", "))
    end
end

return AnimationManager
