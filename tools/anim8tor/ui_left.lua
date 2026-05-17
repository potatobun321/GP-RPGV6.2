local UI = require('engine.ui.init')
local state = require('tools.anim8tor.state')
local logic = require('tools.anim8tor.logic')

local ui_left = {}

function ui_left.update()
    -- IMGUI handles everything during draw
end

function ui_left.draw()
    local px = 0
    local py = 0
    local pw = 320
    
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", px, py, pw, state.screenH)
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.line(pw, 0, pw, state.screenH)
    love.graphics.setLineWidth(1)
    
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.print("ANIM8TOR", 20, 20)
    
    love.graphics.print("GRID", 20, 60)
    
    -- Draw inputs
    local function field(label, id, y, val)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(label..":", 20, y + 6)
        local newVal = UI.Input(id, val, 120, y, 160, 30)
        return newVal
    end
    
    local fw = field("Frame W", "fw", 100, state.inputState.frameWidth.text)
    if fw then state.inputState.frameWidth.text = fw; logic.updateGrid() end
    
    local fh = field("Frame H", "fh", 140, state.inputState.frameHeight.text)
    if fh then state.inputState.frameHeight.text = fh; logic.updateGrid() end
    
    local ml = field("Margin L", "ml", 180, state.inputState.left.text)
    if ml then state.inputState.left.text = ml; logic.updateGrid() end
    
    local mt = field("Margin T", "mt", 220, state.inputState.top.text)
    if mt then state.inputState.top.text = mt; logic.updateGrid() end
    
    local bd = field("Border", "bd", 260, state.inputState.border.text)
    if bd then state.inputState.border.text = bd; logic.updateGrid() end
    
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.print("ANIMATION", 20, 320)
    
    local dur = field("Duration", "dur", 360, state.inputState.duration.text)
    if dur then state.inputState.duration.text = dur; logic.createAnimation() end
    
    if UI.Button("btn_refresh", "REFRESH", 20, 420, 260, 40) then
        logic.updateGrid()
    end
    
    if UI.Button("btn_clear", "CLEAR SELECTION", 20, 480, 260, 40) then
        state.selectedFrames = {}
        logic.createAnimation()
    end
    
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.print("EXPORT", 20, 560)
    
    local ent = field("Entity", "entity", 600, state.inputState.entityType.text)
    if ent then state.inputState.entityType.text = ent end
    
    -- Draw EXIT button at the top bar area (centered horizontally)
    if UI.Button("btn_exit", "EXIT TO GAME", state.screenW/2 - 100, 20, 200, 40) then
        return "exit"
    end
end

return ui_left
