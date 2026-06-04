-- core/input.lua
-- Responsibility: Abstracting raw Love2D input checks

local Input = {}

function Input.isDown(key)
    return love.keyboard.isDown(key)
end

function Input.getAxis(negativeKey, positiveKey)
    local val = 0
    if Input.isDown(positiveKey) then val = val + 1 end
    if Input.isDown(negativeKey) then val = val - 1 end
    return val
end

return Input