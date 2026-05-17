local utf8    = require("utf8")
local Theme   = require('engine.core.theme')
local Context = require('engine.core.context')

local Console = {
    isOpen = false,
    input = "",
    history = {},
    historyIndex = 0,
    logs = {},
    maxLogs = 100,
    scrollOffset = 0,
    animY = -1000
}

function Console.log(text, color)
    local c = color or {1, 1, 1}
    table.insert(Console.logs, {text = tostring(text), color = c})
    if #Console.logs > Console.maxLogs then table.remove(Console.logs, 1) end
    print("[CONSOLE] " .. tostring(text))
end

function Console.clear()
    Console.logs = {}
    Console.scrollOffset = 0
end

function Console.setupGlobals(game)
    local Registry = require('engine.ecs.registry')
    _G.game = game
    _G.world = game.world
    
    if game.playerId then
        _G.player = Registry.get(game.playerId, "Transform")
        _G.vel = Registry.get(game.playerId, "Velocity")
        _G.char = Registry.get(game.playerId, "CharacterStats")
    end
    
    _G.save = function(name) game.world:saveMap(name or game.currentMapName); Console.log("Saved map", {0, 1, 0}) end
    -- Fix #24: renamed from _G.load to _G.loadmap to avoid shadowing Lua's built-in load()
    _G.loadmap = function(name)
        if not name then return Console.log("Need a map name!", {1,0,0}) end
        game.world:saveMap(game.currentMapName)
        game.currentMapName = name
        game.world:loadMap(name)
        Console.log("Loaded map: "..name, {0, 1, 0})
    end
    _G.edit = function()
        if Context.editor then
            Context.editor.toggle()
            Console.log("Toggled Editor Mode", {0.5, 1, 0.5})
            if Console.isOpen then Console.toggle() end
        else
            Console.log("Editor module not found", {1, 0, 0})
        end
    end
    _G.speed = function(s) 
        if _G.vel then 
            _G.vel.baseSpeed = s 
            Console.log("Base speed set to: "..s, {0, 1, 0}) 
        end 
    end
    _G.theme = function(t) 
        if Theme.set(t) then 
            Console.log("Theme set to "..t, {0, 1, 0}) 
        else 
            Console.log("Unknown theme. Try: neon, dracula, dark, light", {1, 0.2, 0.2}) 
        end 
    end
    _G.resize = function(size)
        size = tonumber(size)
        if not size or size < 8 or size > 256 then
            return Console.log("Invalid size. Use 8 to 256.", {1,0,0})
        end
        local oldSize = game.world.tileSize
        game.world.tileSize = size
        
        local tiles = Registry.query("TileData", "Transform")
        for _, id in ipairs(tiles) do
            local tdata = Registry.get(id, "TileData")
            local trans = Registry.get(id, "Transform")
            trans.x = tdata.gridX * size
            trans.y = tdata.gridY * size
            trans.w = size
            trans.h = size
            local rend = Registry.get(id, "Renderable")
            if rend then rend.scaleX = nil; rend.scaleY = nil end
        end
        
        if game.playerId then
            local ptrans = Registry.get(game.playerId, "Transform")
            local pgx = math.floor((ptrans.x + ptrans.w/2) / oldSize)
            local pgy = math.floor((ptrans.y + ptrans.h/2) / oldSize)
            ptrans.x = pgx * size
            ptrans.y = pgy * size
            ptrans.w = size
            ptrans.h = size
            local prend = Registry.get(game.playerId, "Renderable")
            if prend then prend.scaleX = nil; prend.scaleY = nil end
        end
        Console.log("Resized tiles to " .. size, {0, 1, 0})
    end
    _G.charc = function()
        if not game.playerId then return end
        local Registry = require('engine.ecs.registry')
        local health = Registry.get(game.playerId, "Health")
        local vel = Registry.get(game.playerId, "Velocity")
        local cstats = Registry.get(game.playerId, "CharacterStats")
        local stats = cstats and cstats.stats or {atk=0, def=0, endr=0, int=0}
        
        Console.log("+-------------------+", {0, 1, 1})
        Console.log("| STAT  | VALUE     |", {0, 1, 1})
        Console.log("+-------------------+", {0, 1, 1})
        Console.log(string.format("| %-5s | %-9s |", "HP", math.ceil(health.current) .. "/" .. health.max), {0.2, 1, 0.2})
        Console.log(string.format("| %-5s | %-9d |", "SPD", vel.baseSpeed), {1, 1, 0})
        Console.log(string.format("| %-5s | %-9d |", "ATK", stats.atk), {1, 0.2, 0.2})
        Console.log(string.format("| %-5s | %-9d |", "DEF", stats.def), {0.2, 0.5, 1})
        Console.log(string.format("| %-5s | %-9d |", "ENDR", stats.endr), {0.8, 0.5, 0.2})
        Console.log(string.format("| %-5s | %-9d |", "INT", stats.int), {0.8, 0.2, 1})
        Console.log("+-------------------+", {0, 1, 1})
    end
    
    -- numarg: validates a console argument is numeric, logs error and returns nil if not.
    local function numarg(val, name)
        local n = tonumber(val)
        if not n then
            Console.log("ERR: " .. (name or "arg") .. " must be a number (got: " .. tostring(val) .. ")", {1, 0.3, 0.3})
        end
        return n
    end

    local function setStat(statName, val)
        local n = numarg(val, statName)
        if not n or not game.playerId then return end
        local Registry = require('engine.ecs.registry')
        if statName == "hp" then
            local h = Registry.get(game.playerId, "Health")
            h.current = n; h.max = n
        elseif statName == "spd" then
            local v = Registry.get(game.playerId, "Velocity")
            v.baseSpeed = n
        else
            local c = Registry.get(game.playerId, "CharacterStats")
            if c and c.stats then c.stats[statName] = n end
        end
        Console.log(string.upper(statName) .. " set to " .. n, {0, 1, 0})
    end
    
    _G.atk = function(v) setStat("atk", v) end
    _G.def = function(v) setStat("def", v) end
    _G.endr = function(v) setStat("endr", v) end
    _G.int = function(v) setStat("int", v) end
    _G.hp = function(v) setStat("hp", v) end
    _G.spd = function(v) setStat("spd", v) end
    
    local Camera = require('engine.core.camera')
    
    _G.zoom = {
        set = function(s)
            Camera.baseScale = tonumber(s) or 2.0
            Console.log("Zoom set to: " .. tostring(Camera.baseScale), {0, 1, 0})
        end,
        temp = function(s)
            Camera.activeScale = tonumber(s)
            if s then
                Console.log("Temp zoom active: " .. tostring(s), {0, 1, 0})
            else
                Console.log("Temp zoom cleared.", {0, 1, 0})
            end
        end
    }
    
    _G.camera = {
        bounds = function(minX, maxX, minY, maxY)
            if minX and maxX and minY and maxY then
                Camera.customBounds = {tonumber(minX), tonumber(maxX), tonumber(minY), tonumber(maxY)}
                Console.log("Camera bounds locked to: " .. minX .. "," .. maxX .. "," .. minY .. "," .. maxY, {0, 1, 0})
            else
                Camera.customBounds = nil
                Console.log("Camera bounds cleared.", {0, 1, 0})
            end
        end
    }
    
    _G.anim = function()
        Console.log("Switching to Animator Tool...", {1, 0.5, 0})
        Console.isOpen = false
        local AnimatorScene = require('tools.anim8tor.scene')
        Context.scene = AnimatorScene
        Context.scene:load()
    end
    
    _G.clear = Console.clear
    _G.help = function()
        local C  = {0,    1,    1   }   -- cyan   – borders, header, section titles
        local G  = {0.95, 0.72, 0.2 }   -- gold   – section label rows
        local W  = {0.9,  0.9,  0.9 }   -- white  – odd command rows
        local DM = {0.6,  0.6,  0.7 }   -- dim    – even command rows

        -- Column widths: cmd=30, desc=46
        local BORDER  = "+--------------------------------+------------------------------------------------+"
        local HDR_FMT = "| %-30s | %-46s |"
        local ROW_FMT = "| %-30s | %-46s |"

        local function row(cmd, desc, col)
            Console.log(string.format(ROW_FMT, cmd, desc), col)
        end
        local function section(title)
            Console.log(BORDER, C)
            Console.log(string.format("| %-79s|", "  " .. title), G)
        end

        -- ── Header ──────────────────────────────────────────────────────────
        Console.log(BORDER, C)
        Console.log(string.format(HDR_FMT, "COMMAND", "WHAT IT DOES"), C)
        Console.log(BORDER, C)

        -- ── Tools ────────────────────────────────────────────────────────────
        section("TOOLS")
        Console.log(BORDER, C)
        row("anim",       "Open the Anim8tor sprite animation tool",   W)
        row("charc",      "Print the full player stat table",          DM)
        row("edit",       "Toggle the in-game Map Editor panel",       W)
        row("clear",      "Clear all log entries from the console",    DM)
        row("help",       "Show this command reference",               W)

        -- ── Map ───────────────────────────────────────────────────────────────
        section("MAP")
        Console.log(BORDER, C)
        row("save",            "Save the current map to disk",              W)
        row("save.mapname",    "Save the current map under a given name",   DM)
        row("loadmap.mapname", "Load a map by filename (no .lua extension)",W)
        row("resize.N",        "Resize every tile to N pixels (8 – 256)",   DM)

        -- ── Player Stats ──────────────────────────────────────────────────────
        section("PLAYER STATS  (N = any number)")
        Console.log(BORDER, C)
        row("atk.N",   "Set player ATK  (attack power)  to N",      W)
        row("def.N",   "Set player DEF  (defense)       to N",      DM)
        row("endr.N",  "Set player ENDR (endurance)     to N",      W)
        row("int.N",   "Set player INT  (intelligence)  to N",      DM)
        row("hp.N",    "Set player max & current HP to N",           W)
        row("spd.N",   "Set player base movement speed to N",        DM)

        -- ── Camera & Display ──────────────────────────────────────────────────
        section("CAMERA & DISPLAY")
        Console.log(BORDER, C)
        row("theme.name",                 "Switch color theme: neon / dracula / dark / light", W)
        row("zoom.set(x)",                "Set permanent base camera zoom to x",               DM)
        row("zoom.temp(x)",               "Set temporary zoom override (pass nil to clear)",   W)
        row("camera.bounds(x1,x2,y1,y2)", "Lock camera within world tile bounds",              DM)

        Console.log(BORDER, C)
    end
end

function Console.execute(line, game)
    if line == "" then return end
    Console.log("> " .. line, {0.6, 0.6, 0.6})
    table.insert(Console.history, line)
    Console.historyIndex = 0
    
    local rewritten = line
    if line == "edit" then rewritten = "edit()"
    elseif line == "save" then rewritten = "save()"
    elseif line == "clear" then rewritten = "clear()"
    elseif line == "help" then rewritten = "help()"
    elseif line == "charc" then rewritten = "charc()"
    elseif line == "anim" then rewritten = "anim()"
    else
        local cmd, arg = line:match("^([%a_]+)%.([%w_]+)$")
        if cmd and arg then
            -- Fix #24: accept both 'load' and 'loadmap' from the user
            if cmd == "load" or cmd == "loadmap" or cmd == "theme" or cmd == "save" then
                rewritten = (cmd == "load" and "loadmap" or cmd) .. "('" .. arg .. "')"
            elseif tonumber(arg) then
                rewritten = cmd .. "(" .. arg .. ")"
            end
        end
    end
    
    -- Fix #23: setupGlobals is called once in Game:load(). No need to call it here.
    
    local func, err = loadstring(rewritten)
    if not func then
        local funcExpr, _ = loadstring("return " .. line)
        if funcExpr then
            func = funcExpr
        else
            Console.log("Syntax Error: " .. tostring(err), {1, 0.2, 0.2})
            return
        end
    end
    
    local success, result = pcall(func)
    if success then
        if result ~= nil then
            Console.log("= " .. tostring(result), {0.5, 1, 0.5})
        end
    else
        Console.log("Runtime Error: " .. tostring(result), {1, 0.2, 0.2})
    end
end

function Console.toggle()
    Console.isOpen = not Console.isOpen
    if Console.isOpen then
        love.keyboard.setKeyRepeat(true)
        Console.input = ""
    else
        love.keyboard.setKeyRepeat(false)
    end
end

function Console.update(dt)
    local targetY = Console.isOpen and 0 or -love.graphics.getHeight()
    Console.animY = Console.animY + (targetY - Console.animY) * 15 * dt
end

function Console.textinput(t)
    if t ~= "`" and t ~= "~" then Console.input = Console.input .. t end
end

local function autocomplete()
    local envKeys = {"anim", "charc", "atk.", "def.", "endr.", "int.", "hp.", "spd.", "edit", "save", "save.", "load.", "theme.", "resize.", "zoom.set(", "zoom.temp(", "camera.bounds(", "clear", "help"}
    for _, key in ipairs(envKeys) do
        if key:sub(1, #Console.input) == Console.input then
            Console.input = key
            return
        end
    end
end

function Console.keypressed(key, game)
    if key == "return" or key == "kpenter" then
        Console.execute(Console.input, game)
        Console.input = ""
    elseif key == "tab" then
        autocomplete()
    elseif key == "backspace" then
        local byteoffset = utf8.offset(Console.input, -1)
        if byteoffset then Console.input = string.sub(Console.input, 1, byteoffset - 1) end
    elseif key == "up" then
        if #Console.history > 0 then
            if Console.historyIndex == 0 then Console.historyIndex = 1 end
            Console.input = Console.history[#Console.history - Console.historyIndex + 1] or ""
            if Console.historyIndex < #Console.history then Console.historyIndex = Console.historyIndex + 1 end
        end
    elseif key == "down" then
        if Console.historyIndex > 1 then
            Console.historyIndex = Console.historyIndex - 1
            Console.input = Console.history[#Console.history - Console.historyIndex + 1] or ""
        else
            Console.historyIndex = 0
            Console.input = ""
        end
    end
end

function Console.wheelmoved(x, y)
    if not Console.isOpen then return end
    -- Fix #25: clamp scroll so it can never go negative or past the log end
    if y > 0 then
        Console.scrollOffset = math.min(#Console.logs - 1, Console.scrollOffset + 1)
    elseif y < 0 then
        Console.scrollOffset = math.max(0, Console.scrollOffset - 1)
    end
end

function Console.draw()
    if Console.animY <= -love.graphics.getHeight()/2 + 10 then return end
    
    local colors = Theme.get()
    local w, h = love.graphics.getDimensions()
    local ch = h / 2
    local yOff = Console.animY
    
    love.graphics.setColor(colors.console_bg)
    love.graphics.rectangle("fill", 0, yOff, w, ch)
    
    local pulse = math.sin(love.timer.getTime() * 4) * 0.3 + 0.7
    love.graphics.setColor(colors.player[1], colors.player[2], colors.player[3], pulse)
    love.graphics.setLineWidth(3)
    love.graphics.line(0, ch + yOff, w, ch + yOff)
    love.graphics.setLineWidth(1)
    
    love.graphics.setColor(colors.text)
    love.graphics.print("> " .. Console.input .. (math.floor(love.timer.getTime() * 2) % 2 == 0 and "_" or ""), 10, ch - 20 + yOff)
    
    local logY = ch - 40 + yOff
    local startIndex = #Console.logs - Console.scrollOffset
    for i = startIndex, 1, -1 do
        if logY < yOff then break end
        if Console.logs[i] then
            local c = Console.logs[i].color
            love.graphics.setColor(c[1], c[2], c[3], 1)
            love.graphics.print(Console.logs[i].text, 10, logY)
            logY = logY - 20
        end
    end
end

return Console