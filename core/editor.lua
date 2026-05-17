-- core/editor.lua
local Factory = require("core.factory")
local Camera  = require("core.camera")
local Theme   = require("core.theme")
local Context = require("core.context")
local UI      = require("core.ui.init")

-- ── Layout constants ──────────────────────────────────────────────────────────
local PANEL_W     = 300   -- wider panel — prevents all text clipping
local POPUP_W     = 300   -- popup modal width
local POPUP_BTN_H = 28    -- height per option row
local POPUP_PAD   = 14    -- inner padding

local Editor = {
    isActive       = false,
    selectedTileId = "grass",
    animX          = nil,
    panelWidth     = PANEL_W,
    showPopup      = false,
    popupStep      = 1,
    popupGx        = 0,
    popupGy        = 0,
    popupTargetMap = nil,
    mapOptions     = {},
    linkOptions    = {"A", "B", "C", "D", "E"},
    _cachedTileIds = nil,
    toolMode       = "brush",
    dragStartX     = nil,
    dragStartY     = nil,
    dragButton     = nil,
    wasDown        = false,
    history        = {},
    historyIdx     = 0,
}
Context.editor = Editor   -- replaces _G.Editor

local Registry = require("ecs.registry")
local function getTileInfo(world, gx, gy)
    if not world then return "void", nil end
    local tid = world:getTileEntity(gx, gy)
    if not tid then return "void", nil end
    local tdata = Registry.get(tid, "TileData")
    if not tdata then return "void", nil end
    local flags = nil
    if tdata.flags then
        flags = {}
        for k, v in pairs(tdata.flags) do flags[k] = v end
    end
    return tdata.typeId, flags
end

function Editor.pushHistory(action)
    if not action or #action == 0 then return end
    while #Editor.history > Editor.historyIdx do
        table.remove(Editor.history)
    end
    table.insert(Editor.history, action)
    Editor.historyIdx = #Editor.history
    if #Editor.history > 50 then
        table.remove(Editor.history, 1)
        Editor.historyIdx = Editor.historyIdx - 1
    end
end

function Editor.undo(world)
    if Editor.historyIdx > 0 and world then
        local action = Editor.history[Editor.historyIdx]
        for _, change in ipairs(action) do
            world:setTile(change.gx, change.gy, change.oldId, change.oldFlags)
        end
        Editor.historyIdx = Editor.historyIdx - 1
    end
end

function Editor.redo(world)
    if Editor.historyIdx < #Editor.history and world then
        Editor.historyIdx = Editor.historyIdx + 1
        local action = Editor.history[Editor.historyIdx]
        for _, change in ipairs(action) do
            world:setTile(change.gx, change.gy, change.newId, change.newFlags)
        end
    end
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function rebuildTileCache()
    Editor._cachedTileIds = {}
    for id in pairs(Factory.tiles) do table.insert(Editor._cachedTileIds, id) end
    table.sort(Editor._cachedTileIds)
end

local function rebuildMapOptions()
    Editor.mapOptions = {}
    for _, f in ipairs(love.filesystem.getDirectoryItems("world/maps")) do
        local n = f:match("(.+)%.lua$")
        if n then table.insert(Editor.mapOptions, n) end
    end
    table.sort(Editor.mapOptions)
    if #Editor.mapOptions == 0 then Editor.mapOptions = {"map1"} end
end

-- Popup box geometry (shared by draw + mousepressed)
-- Returns: bx, by, boxW, boxH, firstButtonY
local function popupLayout(options)
    local sw, sh   = love.graphics.getWidth(), love.graphics.getHeight()
    -- header:  accent(4) + title-row(32) + separator(1) = 37px
    -- rows:    each option is POPUP_BTN_H + 1px separator
    -- footer:  cancel hint (20px) + pad
    local rowBlock = #options * (POPUP_BTN_H + 1)
    local boxH     = 4 + 32 + 1 + rowBlock + POPUP_PAD + 20 + POPUP_PAD
    local bx       = math.floor(sw / 2 - POPUP_W / 2)
    local by       = math.floor(sh / 2 - boxH / 2)
    local firstBY  = by + 4 + 32 + 1          -- first button top-edge
    return bx, by, POPUP_W, boxH, firstBY
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────
function Editor.toggle()
    Editor.isActive = not Editor.isActive
    if Editor.isActive then
        Editor.animX = love.graphics.getWidth()
        rebuildTileCache()
        rebuildMapOptions()
    end
end

function Editor.update(dt, world)
    if not Editor.animX then Editor.animX = love.graphics.getWidth() end
    if not Editor.isActive and Editor.animX >= love.graphics.getWidth() then return end
    
    UI.update(dt)
    
    local tx = Editor.isActive
        and (love.graphics.getWidth() - Editor.panelWidth)
        or   love.graphics.getWidth()
    Editor.animX = Editor.animX + (tx - Editor.animX) * 15 * dt

    local down1 = love.mouse.isDown(1)
    local down2 = love.mouse.isDown(2)
    local down = down1 or down2

    if Editor.wasDown and not down then
        if Editor.toolMode == "area" and Editor.dragStartX and not Editor.showPopup and world then
            local mx, my = love.mouse.getPosition()
            local wx = (mx - love.graphics.getWidth()/2) / Camera.scale + Camera.x
            local wy = (my - love.graphics.getHeight()/2) / Camera.scale + Camera.y
            local gx = math.floor(wx / world.tileSize)
            local gy = math.floor(wy / world.tileSize)
            
            local minX = math.min(Editor.dragStartX, gx)
            local maxX = math.max(Editor.dragStartX, gx)
            local minY = math.min(Editor.dragStartY, gy)
            local maxY = math.max(Editor.dragStartY, gy)
            
            local action = {}
            local fillId = Editor.dragButton == 2 and "void" or Editor.selectedTileId
            
            if fillId ~= "scene" then
                for y = minY, maxY do
                    for x = minX, maxX do
                        local oldId, oldFlags = getTileInfo(world, x, y)
                        if oldId ~= fillId then
                            table.insert(action, {gx=x, gy=y, oldId=oldId, oldFlags=oldFlags, newId=fillId, newFlags=nil})
                            world:setTile(x, y, fillId)
                        end
                    end
                end
                Editor.pushHistory(action)
            end
        end
        Editor.dragStartX = nil
        Editor.dragStartY = nil
        Editor.dragButton = nil
    end
    Editor.wasDown = down
end

-- ── Input ─────────────────────────────────────────────────────────────────────
function Editor.mousepressed(x, y, button, istouch, presses, world)
    if not Editor.isActive then return false end

    -- If the mouse is hovering over any UI element (panel or popup), block world interaction
    if UI.hot or Editor.showPopup or x >= Editor.animX then
        return true
    end

    -- World-space tile painting
    if button == 1 or button == 2 then
        local wx = (x - love.graphics.getWidth()/2) / Camera.scale + Camera.x
        local wy = (y - love.graphics.getHeight()/2) / Camera.scale + Camera.y
        local gx = math.floor(wx / world.tileSize)
        local gy = math.floor(wy / world.tileSize)
        
        local fillId = button == 1 and Editor.selectedTileId or "void"

        if Editor.toolMode == "area" then
            if fillId == "scene" then
                local Console = require("core.console")
                Console.log("Link tile cannot be used with Area tool", {1, 0.5, 0})
                return true
            end
            Editor.dragStartX = gx
            Editor.dragStartY = gy
            Editor.dragButton = button
            return true
        end
        
        -- Brush mode
        local oldId, oldFlags = getTileInfo(world, gx, gy)
        if fillId == "scene" then
            Editor.showPopup = true
            Editor.popupStep = 1
            Editor.popupGx   = gx
            Editor.popupGy   = gy
            Editor._justOpenedPopup = true
            Editor._pendingHistory = {gx=gx, gy=gy, oldId=oldId, oldFlags=oldFlags}
            rebuildMapOptions()
        else
            if oldId ~= fillId then
                world:setTile(gx, gy, fillId)
                Editor.pushHistory({{
                    gx=gx, gy=gy, 
                    oldId=oldId, oldFlags=oldFlags, 
                    newId=fillId, newFlags=nil
                }})
            end
        end
        return true
    end
    return false
end

-- ── Draw ──────────────────────────────────────────────────────────────────────
function Editor.draw(world)
    if not Editor.isActive and Editor.animX >= love.graphics.getWidth() - 1 then return end

    local colors = Theme.get()
    local sw, sh  = love.graphics.getWidth(), love.graphics.getHeight()
    local mx, my  = love.mouse.getPosition()

    -- ── World hover highlight + coordinate overlay ────────────────────────────
    if Editor.isActive then
        if mx < Editor.animX and not Editor.showPopup and world then
            local wx = (mx - sw/2) / Camera.scale + Camera.x
            local wy = (my - sh/2) / Camera.scale + Camera.y
            local gx = math.floor(wx / world.tileSize)
            local gy = math.floor(wy / world.tileSize)

            -- Tile highlight in world-space
            love.graphics.push()
            love.graphics.translate(sw/2, sh/2)
            love.graphics.scale(Camera.scale)
            love.graphics.translate(-Camera.x, -Camera.y)
            
            if Editor.toolMode == "area" and Editor.dragStartX and Editor.dragStartY then
                local minX = math.min(Editor.dragStartX, gx)
                local maxX = math.max(Editor.dragStartX, gx)
                local minY = math.min(Editor.dragStartY, gy)
                local maxY = math.max(Editor.dragStartY, gy)
                
                love.graphics.setColor(1, 1, 0, 0.3)
                love.graphics.rectangle("fill",
                    minX * world.tileSize, minY * world.tileSize,
                    (maxX - minX + 1) * world.tileSize, (maxY - minY + 1) * world.tileSize)
                love.graphics.setColor(1, 1, 0, 0.8)
                love.graphics.setLineWidth(2 / Camera.scale)
                love.graphics.rectangle("line",
                    minX * world.tileSize, minY * world.tileSize,
                    (maxX - minX + 1) * world.tileSize, (maxY - minY + 1) * world.tileSize)
            else
                love.graphics.setColor(1, 1, 0, 0.8)
                love.graphics.setLineWidth(2 / Camera.scale)
                love.graphics.rectangle("line",
                    gx * world.tileSize, gy * world.tileSize,
                    world.tileSize, world.tileSize)
            end
            love.graphics.pop()

            -- Coordinate Tooltip
            local txt = string.format("%d, %d", gx, gy)
            local font = love.graphics.getFont()
            local tw = font:getWidth(txt)
            local th = font:getHeight()
            
            local ttX = mx + 16
            local ttY = my + 16
            if ttX + tw + 16 > Editor.animX then ttX = mx - tw - 20 end
            if ttY + th + 12 > sh then ttY = my - th - 20 end
            
            love.graphics.setColor(0.05, 0.05, 0.05, 0.9)
            love.graphics.rectangle("fill", ttX, ttY, tw + 16, th + 12)
            
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", ttX, ttY, tw + 16, th + 12)
            love.graphics.setLineWidth(1)
            
            love.graphics.setColor(0.95, 0.95, 0.95, 1)
            love.graphics.print(txt, ttX + 8, ttY + 6)
        end
    end

    -- ── Panel background ──────────────────────────────────────────────────────
    love.graphics.setColor(0.1, 0.1, 0.1, 0.98)
    love.graphics.rectangle("fill", Editor.animX, 0, Editor.panelWidth, sh)

    -- Left-edge accent line
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(Editor.animX, 0, Editor.animX, sh)
    love.graphics.setLineWidth(1)

    -- ── Section header: MAP EDITOR ────────────────────────────────────────────
    love.graphics.setColor(0.95, 0.95, 0.95, 1)
    love.graphics.print("MAP EDITOR", Editor.animX + 16, 16)

    -- Thin separator under header
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", Editor.animX + 16, 38, Editor.panelWidth - 32, 1)

    -- ── Tile list ─────────────────────────────────────────────────────────────
    local tileIds = Editor._cachedTileIds or {}
    local y = 50
    for _, id in ipairs(tileIds) do
        local def    = Factory.tiles[id]
        local rowX   = Editor.animX + 12
        local rowW   = Editor.panelWidth - 24

        -- Use UI Button for hitbox logic
        if UI.Button("tile_"..id, "", rowX, y - 4, rowW, 30) then
            Editor.selectedTileId = id
        end
        
        -- Override visual styling for selected
        if Editor.selectedTileId == id then
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", rowX, y - 4, rowW, 30)
            love.graphics.setLineWidth(1)
        end

        -- Colour swatch (14×14, vertically centered in 30px row)
        local tc = colors[def.colorKey] or {0.55, 0.55, 0.55}
        local swatchY = y + 4
        if def.draw_style == "line" then
            love.graphics.setColor(tc[1], tc[2], tc[3], 0.7)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", rowX + 10, swatchY, 14, 14)
            love.graphics.setLineWidth(1)
        else
            love.graphics.setColor(tc)
            love.graphics.rectangle("fill", rowX + 10, swatchY, 14, 14)
        end
        -- Swatch border
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("line", rowX + 10, swatchY, 14, 14)

        -- Tile name  (bright if selected)
        if Editor.selectedTileId == id then
            love.graphics.setColor(0.95, 0.95, 0.95, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
        end
        love.graphics.print(def.name .. " [" .. id .. "]", rowX + 34, y + 5)

        y = y + 34
    end

    -- Top center toolbar (Undo / Area / Redo)
    if Editor.isActive or Editor.animX < love.graphics.getWidth() - 1 then
        local progress = (love.graphics.getWidth() - Editor.animX) / Editor.panelWidth
        if progress > 0 then
            local menuY = -60 + 70 * progress
            local bw = 80
            local pad = 10
            local totalW = 3 * bw + 2 * pad
            local startX = math.floor(sw / 2 - totalW / 2)
            
            if UI.Button("btn_undo", "UNDO", startX, menuY, bw, 32) then
                Editor.undo(world)
            end
            
            local areaText = Editor.toolMode == "area" and "> AREA <" or "AREA"
            if UI.Button("btn_area", areaText, startX + bw + pad, menuY, bw, 32) then
                Editor.toolMode = Editor.toolMode == "area" and "brush" or "area"
            end
            
            if UI.Button("btn_redo", "REDO", startX + 2*bw + 2*pad, menuY, bw, 32) then
                Editor.redo(world)
            end
        end
    end

    -- Popup
    if Editor.showPopup then
        local options = (Editor.popupStep == 1) and Editor.mapOptions or Editor.linkOptions
        local ROW_H = 54
        local mw    = 380
        local mh    = 70 + #options * ROW_H + 24
        local bx    = math.floor(sw / 2 - mw / 2)
        local bby   = math.floor(sh / 2 - mh / 2)

        -- overlay
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, sw, sh)

        -- box
        love.graphics.setColor(0.04, 0.04, 0.04)
        love.graphics.rectangle("fill", bx, bby, mw, mh)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", bx, bby, mw, mh)

        -- title
        love.graphics.setColor(0.9, 0.9, 0.9)
        local title = (Editor.popupStep == 1) and "SELECT MAP" or "SELECT LINK"
        local font = love.graphics.getFont()
        local tw = font:getWidth(title)
        love.graphics.print(title, bx + (mw / 2) - (tw / 2), bby + 24)

        -- rows
        local rowY = bby + 70
        for _, opt in ipairs(options) do
            if UI.Button("pop_"..opt, opt, bx + 24, rowY, mw - 48, ROW_H - 12) then
                if Editor.popupStep == 1 then
                    Editor.popupTargetMap = opt
                    Editor.popupStep = 2
                else
                    local newFlags = {targetMap = Editor.popupTargetMap, linkId = opt}
                    world:setTile(Editor.popupGx, Editor.popupGy, "scene", newFlags)
                    
                    if Editor._pendingHistory then
                        local ph = Editor._pendingHistory
                        Editor.pushHistory({{
                            gx=ph.gx, gy=ph.gy, 
                            oldId=ph.oldId, oldFlags=ph.oldFlags, 
                            newId="scene", newFlags=newFlags
                        }})
                        Editor._pendingHistory = nil
                    end
                    Editor.showPopup = false
                end
            end
            rowY = rowY + ROW_H
        end
        
        -- close popup if click outside
        if UI.mouseClicked and not Editor._justOpenedPopup then
            if mx < bx or mx > bx + mw or my < bby or my > bby + mh then
                Editor.showPopup = false
            end
        end
        
        if not UI.mouseDown then
            Editor._justOpenedPopup = false
        end
    end
end

return Editor
