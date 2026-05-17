-- ecs/systems.lua
local Registry = require('engine.ecs.registry')
local Context  = require('engine.core.context')
local Input    = require('engine.core.input')
local Theme    = require('engine.core.theme')

local SYS_QUERIES = {
    PlayerInput = { sig = "Velocity|PlayerInput", req = {"Velocity", "PlayerInput"} },
    Movement    = { sig = "Transform|Velocity", req = {"Transform", "Velocity"} },
    TileEffect  = { sig = "PlayerInput|Transform|Health", req = {"PlayerInput", "Transform", "Health"} },
    Animation   = { sig = "Animator", req = {"Animator"} },
    AnimControl = { sig = "Animator|Velocity", req = {"Animator", "Velocity"} },
    Render      = { sig = "Transform|Renderable", req = {"Transform", "Renderable"} },
    UI          = { sig = "Health|PlayerInput", req = {"Health", "PlayerInput"} }
}

local Systems = {}

function Systems.PlayerInputSystem(dt)
    local players = Registry.queryCached(SYS_QUERIES.PlayerInput.sig, SYS_QUERIES.PlayerInput.req)
    for _, id in ipairs(players) do
        local vel = Registry.get(id, "Velocity")
        vel.dx = Input.getAxis("a", "d")
        vel.dy = Input.getAxis("w", "s")
        if vel.dx ~= 0 and vel.dy ~= 0 then
            local l = math.sqrt(vel.dx^2 + vel.dy^2)
            vel.dx, vel.dy = vel.dx/l, vel.dy/l
        end
        -- Fix #8: use Input.isDown instead of direct love.keyboard.isDown
        if Input.isDown("s") then     vel.facing = "down"
        elseif Input.isDown("w") then vel.facing = "up"
        elseif Input.isDown("a") then vel.facing = "left"
        elseif Input.isDown("d") then vel.facing = "right"
        end
    end
end

local function checkEntityCollision(id, nx, ny, w, h)
    local colliders = Registry.queryCached("Transform|Collider", {"Transform", "Collider"})
    for _, cid in ipairs(colliders) do
        if cid ~= id then
            local ct = Registry.get(cid, "Transform")
            local cc = Registry.get(cid, "Collider")
            if nx < ct.x + cc.w and nx + w > ct.x and
               ny < ct.y + cc.h and ny + h > ct.y then
                return true
            end
        end
    end
    return false
end

function Systems.MovementSystem(dt, world)
    local entities = Registry.queryCached(SYS_QUERIES.Movement.sig, SYS_QUERIES.Movement.req)
    for _, id in ipairs(entities) do
        local trans = Registry.get(id, "Transform")
        local vel   = Registry.get(id, "Velocity")

        local cx = trans.x + trans.w/2
        local cy = trans.y + trans.h/2
        local gx = math.floor(cx / world.tileSize)
        local gy = math.floor(cy / world.tileSize)

        local tileId   = world:getTileEntity(gx, gy)
        local speedMod = 1.0
        if tileId then
            local tileData = Registry.get(tileId, "TileData")
            if tileData and tileData.flags and tileData.flags.speedMod then
                speedMod = tileData.flags.speedMod
            end
        end

        vel.currentSpeed = vel.baseSpeed * speedMod

        local fx = trans.x + vel.dx * vel.currentSpeed * dt
        local fy = trans.y + vel.dy * vel.currentSpeed * dt

        local collW, collH = trans.w, trans.h
        local coll = Registry.get(id, "Collider")
        if coll then collW, collH = coll.w, coll.h end

        if not world:isSolidPixel(fx, trans.y, collW, collH) and not checkEntityCollision(id, fx, trans.y, collW, collH) then trans.x = fx end
        if not world:isSolidPixel(trans.x, fy, collW, collH) and not checkEntityCollision(id, trans.x, fy, collW, collH) then trans.y = fy end
    end
end

function Systems.TileEffectSystem(dt, world)
    local players = Registry.queryCached(SYS_QUERIES.TileEffect.sig, SYS_QUERIES.TileEffect.req)
    for _, id in ipairs(players) do
        local trans  = Registry.get(id, "Transform")
        local health = Registry.get(id, "Health")

        if health.immunityTimer > 0 then
            health.immunityTimer = health.immunityTimer - dt
        end

        local gx = math.floor((trans.x + trans.w/2) / world.tileSize)
        local gy = math.floor((trans.y + trans.h/2) / world.tileSize)

        if Context.lastTeleportTile and (Context.lastTeleportTile.x ~= gx or Context.lastTeleportTile.y ~= gy) then
            Context.lastTeleportTile = nil
        end

        local tileId = world:getTileEntity(gx, gy)
        if tileId then
            local tileData = Registry.get(tileId, "TileData")
            if tileData and tileData.flags then
                if tileData.flags.healthAffect then
                    health.current = health.current + (tileData.flags.healthAffect * dt)
                    if health.current < 0   then health.current = 0          end
                    if health.current > health.max then health.current = health.max end
                end
                if tileData.flags.healthAffectInstant and health.immunityTimer <= 0 then
                    health.current = health.current + tileData.flags.healthAffectInstant
                    health.immunityTimer = 1.0
                    if health.current < 0   then health.current = 0          end
                    if health.current > health.max then health.current = health.max end
                end
                if tileData.flags.isSceneTransition then
                    if not Context.lastTeleportTile then
                        local Transition = require('engine.core.transition')
                        Context.lastTeleportTile = {x = gx, y = gy}
                        Transition.execute(tileData, gx, gy)  -- gx/gy needed for same-map link detection
                    end
                end
            end
        end
    end
end

function Systems.AnimationSystem(dt)
    local entities = Registry.queryCached(SYS_QUERIES.Animation.sig, SYS_QUERIES.Animation.req)
    for _, id in ipairs(entities) do
        local anim = Registry.get(id, "Animator")
        if anim.current and anim.animations[anim.current] then
            anim.animations[anim.current]:update(dt)
        end
    end
end

-- Resolve an animation key using the fallback chain.
local function resolveAnim(animations, ...)
    for _, key in ipairs({...}) do
        if animations[key] then return key end
    end
    return nil
end

function Systems.AnimationControllerSystem()
    local entities = Registry.queryCached(SYS_QUERIES.AnimControl.sig, SYS_QUERIES.AnimControl.req)
    for _, id in ipairs(entities) do
        local anim   = Registry.get(id, "Animator")
        local vel    = Registry.get(id, "Velocity")
        local state  = Registry.get(id, "State")
        local action = state and state.current or "idle"
        local f      = vel.facing or "down"
        local moving = (vel.dx ~= 0 or vel.dy ~= 0)

        local target
        if action ~= "idle" then
            target = resolveAnim(anim.animations, action .. "_" .. f, action, "default")
        elseif moving then
            target = resolveAnim(anim.animations, "walk_" .. f, "walk", "default")
        else
            target = resolveAnim(anim.animations, "idle_" .. f, "idle", "walk_" .. f, "walk", "default")
        end

        if target and target ~= anim.current then
            anim.current = target
            anim.animations[target]:gotoFrame(1)
        end
    end
end

-- Fix #9: single-pass RenderSystem — bucket into tiles/chars in one loop,
-- then draw each bucket. Halves entity iteration for maps with 900+ tiles.
function Systems.RenderSystem()
    local entities = Registry.queryCached(SYS_QUERIES.Render.sig, SYS_QUERIES.Render.req)
    local colors   = Theme.get()

    -- Single classification pass
    local tiles, chars = {}, {}
    for _, id in ipairs(entities) do
        local r = Registry.get(id, "Renderable")
        if r.type == "tile" then
            table.insert(tiles, id)
        elseif r.type == "character" then
            table.insert(chars, id)
        end
    end

    -- Draw tiles
    for _, id in ipairs(tiles) do
        local r = Registry.get(id, "Renderable")
        local t = Registry.get(id, "Transform")
        local c = colors[r.colorKey] or {1, 0, 1}
        if r.texture then
            if not r.scaleX or not r.scaleY then
                r.scaleX = t.w / r.texture:getWidth()
                r.scaleY = t.h / r.texture:getHeight()
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(r.texture, t.x, t.y, 0, r.scaleX, r.scaleY)
        else
            if r.draw_style == "line" then
                love.graphics.setColor(c[1], c[2], c[3], 0.2)
                love.graphics.rectangle("line", t.x, t.y, t.w, t.h)
            else
                love.graphics.setColor(c)
                love.graphics.rectangle("fill", t.x, t.y, t.w, t.h)
            end
        end
    end

    -- Draw characters on top
    for _, id in ipairs(chars) do
        local r    = Registry.get(id, "Renderable")
        local t    = Registry.get(id, "Transform")
        local anim = Registry.get(id, "Animator")
        local c    = colors[r.colorKey] or {1, 1, 1}

        if anim and anim.current and anim.animations[anim.current] and r.texture then
            if not r.scaleX or not r.scaleY then
                local w, h = anim.animations[anim.current]:getDimensions()
                r.scaleX = t.w / w
                r.scaleY = t.h / h
            end
            love.graphics.setColor(1, 1, 1)
            anim.animations[anim.current]:draw(r.texture, t.x, t.y, 0, r.scaleX, r.scaleY)
        elseif r.texture then
            if not r.scaleX or not r.scaleY then
                r.scaleX = t.w / r.texture:getWidth()
                r.scaleY = t.h / r.texture:getHeight()
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(r.texture, t.x, t.y, 0, r.scaleX, r.scaleY)
        else
            love.graphics.setColor(c)
            love.graphics.rectangle("fill", t.x, t.y, t.w, t.h)
        end
    end
end

function Systems.UISystem()
    local players = Registry.queryCached(SYS_QUERIES.UI.sig, SYS_QUERIES.UI.req)
    for _, id in ipairs(players) do
        local health = Registry.get(id, "Health")

        -- Background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 18, 18, 204, 24)

        -- Fill (colour-coded by HP%)
        local hpPercent = health.current / health.max
        if     hpPercent > 0.5  then love.graphics.setColor(0.2, 0.8, 0.2, 1)
        elseif hpPercent > 0.25 then love.graphics.setColor(0.8, 0.8, 0.2, 1)
        else                         love.graphics.setColor(0.8, 0.2, 0.2, 1)
        end
        love.graphics.rectangle("fill", 20, 20, 200 * hpPercent, 20)

        -- Border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", 20, 20, 200, 20)

        -- Text (y=46, below the 20px-tall bar that starts at y=20)
        love.graphics.print("HP: " .. math.ceil(health.current) .. "/" .. health.max, 25, 46)
    end
end

return Systems
