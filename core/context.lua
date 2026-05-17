-- core/context.lua
-- Single source of truth for all engine-level state that crosses module
-- boundaries.  Replaces ad-hoc _G.transitioning / _G.lastTeleportTile etc.
--
-- USAGE:
--   local Context = require("core.context")
--   Context.transitioning = true
--   Context.scene         = myScene
--
-- Console REPL aliases (_G.game, _G.world, _G.player, _G.vel) are kept
-- intentionally in console.lua — they exist ONLY for developer convenience
-- in the interactive console, not for cross-module communication.

local Context = {
    -- Scene manager
    scene        = nil,   -- current active scene (replaces _G.currentScene)

    -- Transition lock
    transitioning = false, -- replaces _G.transitioning

    -- Teleport guard (set by game event, cleared by TileEffectSystem)
    lastTeleportTile = nil, -- replaces _G.lastTeleportTile

    -- Editor reference (replaces _G.Editor)
    -- Set by editor.lua on first require, never written by anyone else.
    editor = nil,
}

return Context
