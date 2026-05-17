-- core/character.lua
local Character = {}
Character.__index = Character

function Character.new(template)
    local self = setmetatable({}, Character)
    
    self.stats = {
        strength = template.strength or 5,
        speed = template.speed or 5,
        health = template.health or 100,
        intellect = template.intellect or 5,
        luck = template.luck or 5,
        endurance = template.endurance or 5
    }

    self.derived = { maxHealth = 0, moveSpeed = 0 }
    self:recalculate()
    return self
end

function Character:recalculate()
    self.derived.maxHealth = self.stats.health + (self.stats.endurance * 10)
    self.derived.moveSpeed = 100 + (self.stats.speed * 20)
end

return Character