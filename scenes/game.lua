-- scenes/game.lua
local Context    = require('engine.core.context')
local Tilemap    = require('engine.world.tilemap')
local Camera     = require('engine.core.camera')
local Console    = require('engine.core.console')
local Registry   = require('engine.ecs.registry')
local Factory    = require('engine.core.factory')
local Systems    = require('engine.ecs.systems')
local Theme      = require('engine.core.theme')
local Components = require('engine.ecs.components')
local Editor     = require('tools.editor.editor')

local Game = {}

function Game:load()
    Registry.clear()

    self.currentMapName = "map1"
    self.world = Tilemap.new(31, 31, 32)
    self.world:loadMap(self.currentMapName)
    if self.world.mapZoomLevel then
        Camera.profiles.gameplay.zoomLevel = self.world.mapZoomLevel
        Camera.profiles.gameplay.targetZoomLevel = self.world.mapZoomLevel
    end
    Camera.customBounds = self.world.customBounds

    -- Guard against duplicate event listener on re-load (#32)
    if not self._mapEventRegistered then
        self._mapEventRegistered = true
        Event.on("change_map", function(targetMap, targetX, targetY)
            self.world:saveMap(self.currentMapName)
            self.currentMapName = targetMap
            self.world:loadMap(self.currentMapName)
            
            if self.world.mapZoomLevel then
                Camera.profiles.gameplay.zoomLevel = self.world.mapZoomLevel
                Camera.profiles.gameplay.targetZoomLevel = self.world.mapZoomLevel
            end
            Camera.customBounds = self.world.customBounds

            if self.playerId then
                local trans = Registry.get(self.playerId, "Transform")
                if trans then
                    trans.x = (targetX or 0) * self.world.tileSize
                    trans.y = (targetY or 0) * self.world.tileSize
                end
            end
            Context.lastTeleportTile = {x = targetX or 0, y = targetY or 0}
            Context.transitioning    = false
        end)
    end

    self.playerId = Factory.createCharacterEntity(0, 0, "player")
    Registry.add(self.playerId, "PlayerInput", Components.PlayerInput())

    -- Setup console globals once here (#23)
    Console.setupGlobals(self)

    Console.log("Engine Loaded in Minimalist Object ECS Mode.")
    Console.log("Current Theme: " .. Theme.current)
end

function Game:update(dt)
    Console.update(dt)
    Editor.update(dt, self.world)
    if Console.isOpen then return end

    Systems.PlayerInputSystem(dt)
    Systems.MovementSystem(dt, self.world)
    Systems.TileEffectSystem(dt, self.world)
    Systems.AnimationControllerSystem()
    Systems.AnimationSystem(dt)

    local trans = Registry.get(self.playerId, "Transform")
    if trans then
        local shiftDown = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
        Camera.profiles.gameplay.tempZoomActive = (love.keyboard.isDown("z") and shiftDown)
        
        local tx = trans.x + trans.w / 2
        local ty = trans.y + trans.h / 2
        Camera:update(dt, tx, ty, self.world)
    end
end

function Game:textinput(t)
    if Console.isOpen then Console.textinput(t) end
end

function Game:wheelmoved(x, y)
    if Console.isOpen then Console.wheelmoved(x, y); return end
    if Editor.isActive then Editor.wheelmoved(x, y) end
end

function Game:keypressed(key)
    if key == "`" or key == "~" or key == "f1" then
        Console.toggle()
        return
    end

    if Console.isOpen then
        Console.keypressed(key, self)
        return
    end

    if key == "f" and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
        Camera.isFreeCam = not Camera.isFreeCam
        Console.log("Free Camera: " .. tostring(Camera.isFreeCam), {0.5, 1, 0.5})
    end

    if key == "e" then
        local trans = Registry.get(self.playerId, "Transform")
        if trans then
            local gx = math.floor((trans.x + trans.w/2) / self.world.tileSize)
            local gy = math.floor((trans.y + trans.h/2) / self.world.tileSize)
            local tdata = self.world:getTileData(gx, gy)
            if tdata and tdata.flags and tdata.flags.interactMessage then
                Console.log("Interaction: " .. tdata.flags.interactMessage, {1, 1, 0})
            end
        end
    end
end

function Game:draw()
    Camera:attach()
    self.world:draw()
    Systems.RenderSystem()
    Camera:detach()

    Systems.UISystem()
    Editor.draw(self.world)
    Console.draw()
end

function Game:mousepressed(x, y, button, istouch, presses)
    if Console.isOpen then return end
    if Editor.mousepressed(x, y, button, istouch, presses, self.world) then
        return
    end
end

function Game:mousereleased(x, y, button, istouch, presses)
    if Console.isOpen then return end
    if Editor.isActive then Editor.mousereleased(x, y, button, istouch, presses) end
end

function Game:mousemoved(x, y, dx, dy, istouch)
    if Console.isOpen then return end
    if Editor.isActive then Editor.mousemoved(x, y, dx, dy, istouch) end
end

return Game