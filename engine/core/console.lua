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
    animY = -1000,
    env = setmetatable({
        print = print, math = math, string = string, table = table,
        tostring = tostring, tonumber = tonumber, pairs = pairs,
        ipairs = ipairs, type = type
    }, {__index = _G})
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
    Console.env.game = game
    Console.env.world = game.world
    
    if game.playerId then
        Console.env.player = Registry.get(game.playerId, "Transform")
        Console.env.vel = Registry.get(game.playerId, "Velocity")
        Console.env.char = Registry.get(game.playerId, "CharacterStats")
    end
    
    Console.env.save = function(name) game.world:saveMap(name or game.currentMapName); Console.log("Saved map", {0, 1, 0}) end
    
    Console.env.listmaps = function()
        local MapRegistry = require('engine.world.map_registry')
        local maps = MapRegistry.getPlayableMaps()
        Console.log("--- PLAYABLE MAPS ---", {0, 1, 1})
        for _, m in ipairs(maps) do
            Console.log(m, {0.8, 0.8, 0.8})
        end
    end

    Console.env.newmap = function(name)
        if not name then return Console.log("Need a map name!", {1,0,0}) end
        if love.filesystem.getInfo("maps/" .. name .. ".json") or love.filesystem.getInfo("content/maps/" .. name .. ".json") then
            return Console.log("Map already exists!", {1,0,0})
        end
        game.world:saveMap(game.currentMapName)
        game.currentMapName = name
        game.world:loadMap("template")
        game.world:saveMap(name)
        Console.log("Created new map: " .. name, {0, 1, 0})
    end

    Console.env.duplicatemap = function(src, dest)
        if not src or not dest then return Console.log("Need src and dest names!", {1,0,0}) end
        game.world:saveMap(game.currentMapName)
        game.world:loadMap(src)
        game.currentMapName = dest
        game.world:saveMap(dest)
        Console.log("Duplicated " .. src .. " to " .. dest, {0, 1, 0})
    end

    Console.env.deletemap = function(name)
        if not name then return Console.log("Need a map name!", {1,0,0}) end
        if name == "template" then return Console.log("Cannot delete template", {1,0,0}) end
        
        local deleted = false
        if love.filesystem.getInfo("maps/" .. name .. ".json") then
            love.filesystem.remove("maps/" .. name .. ".json")
            deleted = true
        end
        
        local devPath = love.filesystem.getSource() .. "/content/maps/" .. name .. ".json"
        local f = io.open(devPath, "r")
        if f then
            f:close()
            os.remove(devPath)
            deleted = true
        end
        
        if deleted then
            Console.log("Deleted map: " .. name, {0, 1, 0})
            if game.currentMapName == name then
                game.currentMapName = "map1"
                game.world:loadMap("map1")
            end
        else
            Console.log("Map not found to delete: " .. name, {1,0,0})
        end
    end

    -- Fix #24: renamed from Console.env.load to Console.env.loadmap to avoid shadowing Lua's built-in load()
    Console.env.loadmap = function(name)
        if not name then return Console.log("Need a map name!", {1,0,0}) end
        if not love.filesystem.getInfo("maps/" .. name .. ".json") and not love.filesystem.getInfo("content/maps/" .. name .. ".json") and not love.filesystem.getInfo("content/maps/" .. name .. ".lua") then
             return Console.log("Map not found: " .. name, {1,0,0})
        end
        game.world:saveMap(game.currentMapName)
        game.currentMapName = name
        game.world:loadMap(name)
        Console.log("Loaded map: "..name, {0, 1, 0})
    end
    Console.env.edit = function()
        if Context.editor then
            Context.editor.toggle()
            Console.log("Toggled Editor Mode", {0.5, 1, 0.5})
            if Console.isOpen then Console.toggle() end
        else
            Console.log("Editor module not found", {1, 0, 0})
        end
    end
    Console.env.speed = function(s) 
        if Console.env.vel then 
            Console.env.vel.baseSpeed = s 
            Console.log("Base speed set to: "..s, {0, 1, 0}) 
        end 
    end
    
    Console.env.theme = function(t)
        if Theme.set(t) then
            Console.log("Theme set to "..t, {0, 1, 0})
        else
            Console.log("Unknown theme. Try: neon, dracula, dark, light", {1, 0.2, 0.2})
        end
    end
    
    Console.env.resize = function(size)
        size = tonumber(size)
        if not size or size < 8 or size > 256 then
            return Console.log("Invalid size. Use 8 to 256.", {1,0,0})
        end
        local oldSize = game.world.tileSize
        game.world.tileSize = size
        
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
        
        local Context = require('engine.core.context')
        Context.mapDirty = true
        Console.log("Resized tiles to " .. size, {0, 1, 0})
    end
    Console.env.charc = function()
        if not game.playerId then return Console.log("No player", {1,0,0}) end
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
    
    Console.env.atk = function(v) setStat("atk", v) end
    Console.env.def = function(v) setStat("def", v) end
    Console.env.endr = function(v) setStat("endr", v) end
    Console.env.int = function(v) setStat("int", v) end
    Console.env.hp = function(v) setStat("hp", v) end
    Console.env.spd = function(v) setStat("spd", v) end
    
    local Camera = require('engine.core.camera')
    
    Console.env.zoom = {
        set = function(s)
            local n = tonumber(s)
            if not n or n < 0 or n > 6 or n ~= math.floor(n) then
                return Console.log("ERR: zoom.set requires integer 0-6", {1, 0.2, 0.2})
            end
            Camera.profiles.gameplay.zoomLevel = n
            Camera.profiles.gameplay.targetZoomLevel = n
            Console.log("Gameplay zoom set to Level " .. n, {0, 1, 0})
        end,
        temp = function(s)
            if s == "clear" then
                Camera.profiles.gameplay.activeZoomLevel = nil
                Console.log("Temp zoom cleared.", {0, 1, 0})
                return
            end
            local n = tonumber(s)
            if not n or n < 0 or n > 6 or n ~= math.floor(n) then
                return Console.log("ERR: zoom.temp requires integer 0-6 or 'clear'", {1, 0.2, 0.2})
            end
            Camera.profiles.gameplay.activeZoomLevel = n
            Console.log("Temp zoom active: Level " .. n, {0, 1, 0})
        end
    }
    
    Console.env.anim = function()
        Console.log("Switching to Animator Tool...", {1, 0.5, 0})
        Console.isOpen = false
        local AnimatorScene = require('tools.anim8tor.scene')
        Context.scene = AnimatorScene
        Context.scene:load()
    end
    
    Console.env.history = function()
        Console.log("--- COMMAND HISTORY ---", {0, 1, 1})
        for i, h in ipairs(Console.history) do
            Console.log(i .. ": " .. h, {0.8, 0.8, 0.8})
        end
    end

    Console.env.commands = function()
        Console.env.help()
    end
    
    Console.env.clear = Console.clear
    Console.env.help = function()
        local C = {0, 1, 1}       -- cyan for headers
        local W = {0.9, 0.9, 0.9} -- white for commands

        local function section(title)
            Console.log(" ", C)
            Console.log("--- " .. title .. " ---", C)
        end
        local function row(cmd, desc)
            Console.log(string.format("%-15s - %s", cmd, desc), W)
        end

        section("TOOLS & EDITOR")
        row("edit",       "Toggle the Map Editor panel")
        row("anim",       "Open the Anim8tor sprite tool")
        row("charc",      "Print the player stat table")
        row("clear",      "Clear all console logs")

        section("MAP MANAGEMENT")
        row("listmaps",   "List all playable maps")
        row("newmap.X",   "Create a new map named X")
        row("duplicatemap.A.B", "Duplicate map A to B")
        row("deletemap.X","Delete map named X")
        row("save",       "Save current map")
        row("save.X",     "Save map under filename X")
        row("loadmap.X",  "Load map by filename X")
        row("resize.N",   "Resize every tile to N pixels")

        section("PLAYER STATS")
        row("hp.N",       "Set max & current HP")
        row("spd.N",      "Set base movement speed")
        row("atk.N",      "Set ATK (attack power)")
        row("def.N",      "Set DEF (defense)")
        row("endr.N",     "Set ENDR (endurance)")
        row("int.N",      "Set INT (intelligence)")

        section("CAMERA & DISPLAY")
        row("theme.X",    "Set theme (neon/dracula/dark/light)")
        row("zoom.set(N)",  "Set permanent default zoom")
        row("zoom.temp(N)", "Set active zoom (used with Shift+Z)")
        Console.log(" ", C)
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
    elseif line == "listmaps" then rewritten = "listmaps()"
    else
        local cmd, arg = line:match("^([%a_]+)%.([%w_]+)$")
        if cmd and arg then
            -- Fix #24: accept both 'load' and 'loadmap' from the user
            if cmd == "load" or cmd == "loadmap" or cmd == "theme" or cmd == "save" or cmd == "newmap" or cmd == "deletemap" then
                rewritten = (cmd == "load" and "loadmap" or cmd) .. "('" .. arg .. "')"
            elseif tonumber(arg) then
                rewritten = cmd .. "(" .. arg .. ")"
            end
        else
            local c, a1, a2 = line:match("^([%a_]+)%.([%w_]+)%.([%w_]+)$")
            if c == "duplicatemap" then
                rewritten = "duplicatemap('" .. a1 .. "', '" .. a2 .. "')"
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
    
    setfenv(func, Console.env)
    
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
    local envKeys = {"anim", "charc", "atk.", "def.", "endr.", "int.", "hp.", "spd.", "edit", "save", "save.", "loadmap.", "theme.", "resize.", "zoom.set(", "zoom.temp(", "clear", "help", "listmaps", "newmap.", "deletemap.", "duplicatemap."}
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
    
    love.graphics.setScissor(0, math.max(0, yOff), w, ch)
    
    love.graphics.setColor(colors.text)
    love.graphics.print("> " .. Console.input .. (math.floor(love.timer.getTime() * 2) % 2 == 0 and "_" or ""), 10, ch - 20 + yOff)
    
    local logY = ch - 40 + yOff
    local startIndex = #Console.logs - Console.scrollOffset
    for i = startIndex, 1, -1 do
        if logY < yOff + 10 then break end
        if Console.logs[i] then
            local c = Console.logs[i].color
            love.graphics.setColor(c[1], c[2], c[3], 1)
            love.graphics.print(Console.logs[i].text, 10, logY)
            logY = logY - 20
        end
    end
    
    love.graphics.setScissor()
end

return Console