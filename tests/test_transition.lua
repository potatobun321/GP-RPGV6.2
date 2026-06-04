-- tests/test_transition.lua
local PASS = 0
local FAIL = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        PASS = PASS + 1
        print(string.format("  [PASS] %s", name))
    else
        FAIL = FAIL + 1
        print(string.format("  [FAIL] %s\n         %s", name, tostring(err)))
    end
end

local function eq(a, b, msg)
    if a ~= b then
        error((msg or "assert_eq") .. string.format(": expected %s, got %s", tostring(b), tostring(a)), 2)
    end
end

package.path = package.path .. ";./?.lua;./?/init.lua"

-- Mock global love environment
_G.love = {
    filesystem = {
        getInfo = function(path)
            if path == "maps/testmap.json" then return true end
            if path == "maps/missing.json" then return false end
            return false
        end,
        read = function(path)
            if path == "maps/testmap.json" then
                return [[
                {
                    "name": "testmap",
                    "tiles": [
                        {"x": 5, "y": 5, "len": 3, "id": "scene", "flags": {"linkId": "A"}}
                    ]
                }
                ]]
            end
            return nil
        end,
        load = function(path)
            if path == "content/maps/legacy_map.lua" then
                return function()
                    return {
                        tiles = {
                            {x = 10, y = 10, id = "scene", flags = {linkId = "B"}}
                        }
                    }
                end
            end
            return nil
        end
    }
}

-- Mock Factory and Console
package.loaded['engine.core.factory'] = {
    getTile = function(id)
        if id == "scene" then
            return { flags = { linkId = "DEFAULT" } }
        end
        return {}
    end
}

package.loaded['engine.core.console'] = {
    log = function(msg) print("CONSOLE: " .. tostring(msg)) end
}

package.loaded['engine.core.context'] = {
    transitioning = false
}

local Transition = require('engine.core.transition')

print("\n=== Transition System Tests ===")

test("Transition parses JSON and handles RLE correctly", function()
    local x, y = Transition.findReturnTile("testmap", "currentmap", "A", nil, nil)
    -- Start is at 5. Length is 3. Center is 5 + math.floor(2/2) = 6.
    eq(x, 6, "Expected X to be center of RLE run")
    eq(y, 5, "Expected Y to be 5")
end)

test("Transition falls back to legacy LUA if no JSON", function()
    local x, y = Transition.findReturnTile("legacy_map", "currentmap", "B", nil, nil)
    eq(x, 10, "Expected X to be 10")
    eq(y, 10, "Expected Y to be 10")
end)

test("Transition returns nil for missing links", function()
    local x, y = Transition.findReturnTile("testmap", "currentmap", "NONEXISTENT", nil, nil)
    if x ~= nil or y ~= nil then
        error("Expected nil for missing link")
    end
end)

print(string.format("\n  Passed: %d  |  Failed: %d  |  Total: %d\n", PASS, FAIL, PASS + FAIL))
if FAIL > 0 then os.exit(1) else os.exit(0) end
