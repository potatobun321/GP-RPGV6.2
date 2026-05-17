-- core/animator/ui_right.lua
-- Right panel: animation preview (top) + binding slot list (bottom).
-- SUIT is GONE. Pure love.graphics + mouse detection only.
-- LUIS buttons for BIND & SAVE / EXPORT are registered in scenes/animator.lua.

local state    = require 'core.animator.state'
local viewport = require 'core.animator.viewport'
local logic    = require 'core.animator.logic'
local UI       = require 'core.ui.init'

local ui_right = {}

local PANEL_W = 320
local PAD     = 16
local ROW_H   = 20

local TEMPLATES = {
    "walk_down",  "walk_up",  "walk_left",  "walk_right",
    "idle_down",  "idle_up",  "idle_left",  "idle_right",
    "attack", "hurt", "default"
}

local hoverIdx     = nil
local mouseWasDown = false

-- ─────────────────────────────────────────────────────────────────────────────
local function panelX() return state.screenW - PANEL_W end

-- Y where the first template row starts
local function listStartY()
    return math.floor(state.screenH * 0.5) + PAD + 40
end

-- ─────────────────────────────────────────────────────────────────────────────
function ui_right.update()
    local px  = panelX()
    local lsY = listStartY()
    local mx, my = love.mouse.getPosition()

    -- hover detection
    hoverIdx = nil
    for i = 1, #TEMPLATES do
        local ry = lsY + (i - 1) * ROW_H
        if mx >= px + PAD and mx <= px + PANEL_W - PAD
        and my >= ry and my < ry + ROW_H then
            hoverIdx = i
            break
        end
    end

    -- single-click to select template
    local down = love.mouse.isDown(1)
    if down and not mouseWasDown and hoverIdx then
        state.selectedTemplate = TEMPLATES[hoverIdx]
        -- keep exportName in sync so logic.bindAndSave knows what to save
        state.inputState.exportName.text = TEMPLATES[hoverIdx]
    end
    mouseWasDown = down
end

-- ─────────────────────────────────────────────────────────────────────────────
function ui_right.draw()
    local px   = panelX()
    local divY = math.floor(state.screenH * 0.5)
    local prevW = PANEL_W - PAD * 2

    -- ── panel background ──────────────────────────────────────────────────────
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", px, 0, PANEL_W, state.screenH)

    -- Left border line
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(px, 0, px, state.screenH)
    love.graphics.setLineWidth(1)

    -- ══════════════════════════════════════════════════════════════════════════
    --  TOP HALF  –  PREVIEW
    -- ══════════════════════════════════════════════════════════════════════════
    if state.font then love.graphics.setFont(state.font) end
    love.graphics.setColor(0.75, 0.75, 0.85)
    love.graphics.print("PREVIEW", px + PAD, PAD + 4)

    local prevY = PAD + 28
    local prevH = divY - prevY - PAD
    local bx, by, bw, bh = px + PAD, prevY, prevW, prevH

    -- dark box
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", bx, by, bw, bh)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx, by, bw, bh)
    love.graphics.setLineWidth(1)

    if state.errorMessage ~= "" then
        love.graphics.setColor(0.6, 0.6, 0.6)
        if state.fontSmall then love.graphics.setFont(state.fontSmall) end
        love.graphics.printf("ERR: " .. state.errorMessage,
            px + PAD + 6, prevY + 6, prevW - 12, "left")

    elseif state.animation and state.image then
        local fw = tonumber(state.inputState.frameWidth.text)  or 32
        local fh = tonumber(state.inputState.frameHeight.text) or 32
        local sc = math.min((prevW - 8) / fw, (prevH - 8) / fh)
        if sc > 1 then sc = math.floor(sc) end
        local dw = fw * sc
        local dh = fh * sc
        local dx = px + PAD + (prevW / 2) - (dw / 2)
        local dy = prevY       + (prevH / 2) - (dh / 2)
        viewport.drawCheckerboard(dx, dy, dw, dh, 16)
        love.graphics.setColor(1, 1, 1)
        state.animation:draw(state.image, dx, dy, 0, sc, sc)

    else
        love.graphics.setColor(0.33, 0.33, 0.38)
        if state.fontSmall then love.graphics.setFont(state.fontSmall) end
        love.graphics.printf("Drop spritesheet\n& click frames",
            px + PAD, prevY + prevH * 0.35, prevW, "center")
    end

    -- ══════════════════════════════════════════════════════════════════════════
    --  BOTTOM HALF  –  BINDING SLOTS
    -- ══════════════════════════════════════════════════════════════════════════
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", px, divY, PANEL_W, state.screenH - divY)

    -- Divider glow line
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(px + PAD, divY, px + PANEL_W - PAD, divY)

    -- Header
    if state.font then love.graphics.setFont(state.font) end
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.print("BINDINGS", px + PAD, divY + PAD)

    -- Compact hint below header
    if state.fontSmall then love.graphics.setFont(state.fontSmall) end
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("select slot → BIND & SAVE → animations.lua", px + PAD, divY + PAD + 22)

    -- ── Template list ─────────────────────────────────────────────────────────
    local lsY = listStartY()

    for i, tmpl in ipairs(TEMPLATES) do
        local ry      = lsY + (i - 1) * ROW_H
        local rx      = px + PAD - 4
        local rw      = PANEL_W - PAD * 2 + 8
        local saved   = state.savedSlots[tmpl]
        local hovered = (i == hoverIdx)

        -- row bg
        if state.selectedTemplate == tmpl then
            love.graphics.setColor(0.9, 0.9, 0.9, 0.2)
            love.graphics.rectangle("fill", rx, ry, rw, ROW_H - 2)
            love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", rx, ry, rw, ROW_H - 2)
            love.graphics.setLineWidth(1)
        elseif hovered then
            love.graphics.setColor(0.25, 0.25, 0.25, 1)
            love.graphics.rectangle("fill", rx, ry, rw, ROW_H - 2)
        end

        -- status icon
        love.graphics.setColor(saved and {0.9, 0.9, 0.9} or {0.3, 0.3, 0.3})
        love.graphics.print(saved and "✓" or "○", px + PAD, ry + 4)

        -- label
        local hasData = state.bindings and state.bindings[tmpl] ~= nil
        if state.selectedTemplate == tmpl then
            love.graphics.setColor(0.95, 0.95, 0.95)
        elseif hasData then
            love.graphics.setColor(0.7, 0.7, 0.7)
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
        end
        love.graphics.print(tmpl, px + PAD + 18, ry + 4)
    end

    -- divider above buttons
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.line(px + PAD, state.screenH - 110, px + PANEL_W - PAD, state.screenH - 110)

    -- Bottom Action Buttons
    local btnY = state.screenH - 100
    if UI.Button("btn_bind", "BIND & SAVE", px + PAD, btnY, PANEL_W - PAD * 2, 40) then
        logic.bindAndSave()
    end
    
    if UI.Button("btn_export", "VIEW MANIFEST", px + PAD, btnY + 48, PANEL_W - PAD * 2, 40) then
        logic.exportBindings()
    end
end

return ui_right
