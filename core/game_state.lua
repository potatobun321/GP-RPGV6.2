-- core/game_state.lua
-- Responsibility: Global state management (Flags, Inventory, Quests, Stats)

local GameState = {
    flags = {},
    inventory = {},
    quests = {},
    
    -- The Blueprint for the Player
    -- This allows stats to persist even if the Player entity is destroyed/recreated
    playerTemplate = {
        name = "kartikay",
        strength = 5,
        speed = 123,
        health = 100,
        intellect = 5,
        luck = 5,
        endurance = 5
    }
}

function GameState.setFlag(name, value)
    GameState.flags[name] = value
end

function GameState.getFlag(name)
    return GameState.flags[name]
end

function GameState.addItem(item, count)
    local current = GameState.inventory[item] or 0
    GameState.inventory[item] = current + (count or 1)
end

return GameState