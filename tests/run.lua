-- tests/run.lua
-- Minimal test runner. Run from the project root with:
--   lua tests/run.lua
--
-- Does NOT require Love2D — pure Lua 5.1+ only.
-- Love2D-specific modules (love.graphics etc.) are NOT available here.

local PASS = 0
local FAIL = 0
local ERRORS = {}

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        PASS = PASS + 1
        print(string.format("  [PASS] %s", name))
    else
        FAIL = FAIL + 1
        table.insert(ERRORS, {name = name, err = err})
        print(string.format("  [FAIL] %s\n         %s", name, tostring(err)))
    end
end

local function eq(a, b, msg)
    if a ~= b then
        error((msg or "assert_eq") .. string.format(": expected %s, got %s",
            tostring(b), tostring(a)), 2)
    end
end

local function truthy(v, msg)
    if not v then error((msg or "assert") .. ": expected truthy, got " .. tostring(v), 2) end
end

local function falsy(v, msg)
    if v then error((msg or "assert_false") .. ": expected falsy, got " .. tostring(v), 2) end
end

-- ── Add project root to package path ─────────────────────────────────────────
-- Run this file from the GP-RPGV6 directory, e.g.:
--   cd GP-RPGV6 && lua tests/run.lua
package.path = package.path .. ";./?.lua;./?/init.lua"

-- Stub out love.* so non-graphics modules can be required safely
love = love or {}
love.filesystem = love.filesystem or {
    getDirectoryItems = function() return {} end,
    load = function() return function() return {} end end,
}

-- ─────────────────────────────────────────────────────────────────────────────
print("\n=== Registry ===")
-- ─────────────────────────────────────────────────────────────────────────────
local Registry = require("ecs.registry")

test("create() returns unique IDs", function()
    Registry.clear()
    local a = Registry.create()
    local b = Registry.create()
    truthy(a ~= b, "IDs should differ")
end)

test("add() and get() round-trip", function()
    Registry.clear()
    local id = Registry.create()
    Registry.add(id, "Health", {current = 100, max = 100})
    local h = Registry.get(id, "Health")
    eq(h.current, 100, "health.current")
    eq(h.max,     100, "health.max")
end)

test("has() returns true after add, false before", function()
    Registry.clear()
    local id = Registry.create()
    falsy(Registry.has(id, "Velocity"), "should not have Velocity yet")
    Registry.add(id, "Velocity", {dx=0, dy=0, baseSpeed=200})
    truthy(Registry.has(id, "Velocity"), "should have Velocity after add")
end)

test("remove() deletes entity from all queries", function()
    Registry.clear()
    local id = Registry.create()
    Registry.add(id, "Transform",  {x=0,y=0,w=32,h=32})
    Registry.add(id, "Renderable", {kind="tile"})
    local before = Registry.query("Transform", "Renderable")
    eq(#before, 1, "one entity before remove")
    Registry.remove(id)
    local after = Registry.query("Transform", "Renderable")
    eq(#after, 0, "zero entities after remove")
end)

test("query() cache invalidates after remove", function()
    Registry.clear()
    local a = Registry.create()
    local b = Registry.create()
    Registry.add(a, "Health", {current=50, max=100})
    Registry.add(b, "Health", {current=80, max=100})
    local q1 = Registry.query("Health")
    eq(#q1, 2, "two entities with Health")
    Registry.remove(a)
    -- Cache must be cold after remove
    local q2 = Registry.query("Health")
    eq(#q2, 1, "one entity after remove")
end)

test("query() returns same IDs in deterministic order", function()
    Registry.clear()
    for i = 1, 5 do
        local id = Registry.create()
        Registry.add(id, "Tag", {})
    end
    local r1 = Registry.query("Tag")
    local r2 = Registry.query("Tag")
    eq(#r1, 5)
    for i = 1, 5 do eq(r1[i], r2[i], "order mismatch at " .. i) end
end)

-- ─────────────────────────────────────────────────────────────────────────────
print("\n=== Context ===")
-- ─────────────────────────────────────────────────────────────────────────────
local Context = require("core.context")

test("Context.transitioning starts false", function()
    falsy(Context.transitioning, "should start false")
end)

test("Context fields can be written and read back", function()
    Context.lastTeleportTile = {x = 3, y = 7}
    eq(Context.lastTeleportTile.x, 3)
    eq(Context.lastTeleportTile.y, 7)
    Context.lastTeleportTile = nil   -- clean up
end)

-- ─────────────────────────────────────────────────────────────────────────────
print("\n=== Console numarg validation ===")
-- ─────────────────────────────────────────────────────────────────────────────
-- We test the validation logic directly without loading the full console.
local function numarg(val, name, logFn)
    local n = tonumber(val)
    if not n then
        logFn("ERR: " .. (name or "arg") .. " must be a number (got: " .. tostring(val) .. ")")
    end
    return n
end

test("numarg accepts valid integer", function()
    local logged = {}
    local n = numarg("42", "atk", function(m) table.insert(logged, m) end)
    eq(n, 42)
    eq(#logged, 0, "no error logged")
end)

test("numarg accepts valid float", function()
    local logged = {}
    local n = numarg("3.14", "spd", function(m) table.insert(logged, m) end)
    truthy(math.abs(n - 3.14) < 0.001, "float value")
    eq(#logged, 0, "no error logged")
end)

test("numarg rejects string 'banana'", function()
    local logged = {}
    local n = numarg("banana", "atk", function(m) table.insert(logged, m) end)
    falsy(n, "should return nil")
    eq(#logged, 1, "should log one error")
    truthy(logged[1]:find("banana"), "error message should mention bad value")
end)

test("numarg rejects nil", function()
    local logged = {}
    local n = numarg(nil, "hp", function(m) table.insert(logged, m) end)
    falsy(n, "should return nil for nil input")
    eq(#logged, 1, "one error logged")
end)

-- ─────────────────────────────────────────────────────────────────────────────
print("\n=== Summary ===")
-- ─────────────────────────────────────────────────────────────────────────────
print(string.format("  Passed: %d  |  Failed: %d  |  Total: %d",
    PASS, FAIL, PASS + FAIL))

if FAIL > 0 then
    print("\nFailed tests:")
    for _, e in ipairs(ERRORS) do
        print("  - " .. e.name)
    end
    os.exit(1)
else
    print("\nAll tests passed.")
    os.exit(0)
end
