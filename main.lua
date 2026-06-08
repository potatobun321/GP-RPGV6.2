-- main.lua
local Context   = require('engine.core.context')
local SceneGame = require("scenes.game")

local Factory = require('engine.core.factory')

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    local success, f = pcall(love.graphics.newFont, "fonts/PressStart2P.ttf", 12)
    if success then love.graphics.setFont(f) end

    _G.Event = require('engine.core.event')  -- kept global: event bus used across all modules

    Factory.load()

    local AnimationManager = require('engine.core.animation')
    AnimationManager.verifyAll(Factory)

    Context.scene = SceneGame
    _G.game       = SceneGame   -- console REPL alias only
    Context.scene:load()
end

function love.quit()
    local s = Context.scene
    if s and s.world and s.currentMapName then
        s.world:saveMap(s.currentMapName)
    end
    return false
end

function love.update(dt)
    local s = Context.scene
    if s and s.update then s:update(dt) end
end

function love.draw()
    local s = Context.scene
    if s and s.draw then s:draw() end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    local s = Context.scene
    if s and s.keypressed then s:keypressed(key) end
end

function love.textinput(t)
    local s = Context.scene
    if s and s.textinput then s:textinput(t) end
end

function love.wheelmoved(x, y)
    local s = Context.scene
    if s and s.wheelmoved then s:wheelmoved(x, y) end
end

function love.mousepressed(x, y, button, istouch, presses)
    local s = Context.scene
    if s and s.mousepressed then s:mousepressed(x, y, button, istouch, presses) end
end

function love.mousemoved(x, y, dx, dy, istouch)
    local s = Context.scene
    if s and s.mousemoved then s:mousemoved(x, y, dx, dy, istouch) end
end

function love.mousereleased(x, y, button, istouch, presses)
    local s = Context.scene
    if s and s.mousereleased then s:mousereleased(x, y, button, istouch, presses) end
end

function love.filedropped(file)
    local s = Context.scene
    if s and s.filedropped then s:filedropped(file) end
end
