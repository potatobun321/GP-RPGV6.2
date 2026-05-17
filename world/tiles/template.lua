-- world/tiles/template.lua
-- This is a reference template. Do not use this directly as an active tile.
-- Copy this file to create new tiles.

return {
    id = "template",        -- The unique string ID for this tile
    name = "Template Tile", -- Display name
    colorKey = "bg",        -- The fallback color key in core/theme.lua
    draw_style = "fill",    -- "fill" or "line"
    texturePath = nil,      -- Optional: "assets/tiles/mytile.png"
    flags = {               -- Custom game logic properties (overrides flagTable defaults)
        -- solid = false,
        -- speedMod = 1.0,
        -- healthAffect = -5
    }
}
