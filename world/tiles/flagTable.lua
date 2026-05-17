-- world/tiles/flagTable.lua
-- The master template for tile flags. All tiles inherit these properties automatically.
-- Only declare a flag in a specific tile if it differs from these defaults.

return {
    solid = false,         -- Blocks movement
    speedMod = 1.0,        -- Multiplier for walking speed
    healthAffect = 0,      -- HP change per second
    interactable = false,  -- Can the player interact with this?
    interactMessage = false, -- Message displayed on interaction
    destructible = false   -- Can this tile be destroyed?
}
