-- scenes/animator.lua
-- Anim8tor scene. Single LUIS layer for all interactive widgets.
-- Raw love.graphics for panel backgrounds, viewport, preview, and binding list.

local state    = require 'core.animator.state'
local logic    = require 'core.animator.logic'
local viewport = require 'core.animator.viewport'
local ui_right = require 'core.animator.ui_right'

local AnimatorScene = {}

local oldW, oldH, oldFlags
local UI = require("core.ui.init")
local ui_left  = require 'core.animator.ui_left'

local oldW, oldH, oldFlags
-- Screen: 1280 × 720  |  Grid: 20px
-- Left panel:  cols 1-16   (   0 - 320 px )
-- Middle:      cols 17-48  ( 320 - 960 px )
-- Right panel: cols 49-64  ( 960 - 1280 px)
local G       = 20
local R_START = 49   -- right panel first col (960 px)

-- Reference to each widget we need to read back
local _inp = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- (Old buildUI function removed)

-- ─────────────────────────────────────────────────────────────────────────────
function AnimatorScene:load()
    oldW, oldH, oldFlags = love.window.getMode()
    love.window.setMode(1280, 720, {fullscreen=false, resizable=false})
    state.screenW, state.screenH = love.graphics.getDimensions()

    love.graphics.setBackgroundColor(0.05, 0.05, 0.05)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Fonts
    local ok1, f1 = pcall(love.graphics.newFont, "PressStart2P.ttf", 11)
    local ok2, f2 = pcall(love.graphics.newFont, "PressStart2P.ttf", 9)
    state.font      = ok1 and f1 or love.graphics.getFont()
    state.fontSmall = ok2 and f2 or love.graphics.getFont()

    -- Set global UI theme font
    UI.Theme.font = state.font
    UI.Theme.fontSmall = state.fontSmall

    -- Reset session state
    state.savedSlots = {}
    love.keyboard.setKeyRepeat(true)
end

-- ─────────────────────────────────────────────────────────────────────────────
function AnimatorScene:update(dt)
    if state.animation then state.animation:update(dt) end
    UI.update(dt)

    ui_right.update()
end

-- ─────────────────────────────────────────────────────────────────────────────
function AnimatorScene:draw()
    -- Clear background (LUIS draw() also sets it but we pre-clear to avoid flicker)
    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, 0, state.screenW, state.screenH)

    -- Middle viewport
    viewport.draw()

    -- Right panel preview + binding list
    ui_right.draw()

    -- Left panel + buttons
    if ui_left.draw() == "exit" then
        love.window.setMode(oldW, oldH, oldFlags)
        local ok, f = pcall(love.graphics.newFont, "PressStart2P.ttf", 12)
        if ok then love.graphics.setFont(f) end
        local Context   = require("core.context")
        local SceneGame = require("scenes.game")
        Context.scene   = SceneGame
        _G.game         = SceneGame   -- console REPL alias
        love.graphics.setBackgroundColor(0, 0, 0)
        love.keyboard.setKeyRepeat(false)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
function AnimatorScene:mousepressed(x, y, button, istouch, presses)

    -- Viewport only in the middle zone
    if x > 320 and x < 960 then
        viewport.mousepressed(x, y, button)
    end
end

function AnimatorScene:mousereleased(x, y, button, istouch, presses)

end

function AnimatorScene:textinput(t)
    UI.textinput(t)
end

function AnimatorScene:keypressed(key)
    UI.keypressed(key)
end

function AnimatorScene:filedropped(file)
    logic.handleFileDropped(file)
end

function AnimatorScene:resize(w, h)
    state.screenW = w
    state.screenH = h
end

return AnimatorScene
