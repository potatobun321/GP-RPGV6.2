# Transition System

## Overview
The Transition System (`engine/core/transition.lua`) manages seamless teleports between coordinates on a single map (doors, stairs) and across entirely different map files.

## Transition Pipeline
1. **Trigger:** `TileEffectSystem` detects when a player's `Transform` intersects with a `scene` tile.
2. **Execution:** It calls `Transition.execute()`, parsing the tile's metadata.
3. **Lookup:** It delegates to `Transition.findReturnTile` to locate the destination.
4. **Resolution:** The player's coordinates are forcibly overridden and a `change_map` event triggers.

## Lookup Mechanics

### Same-Map Transitions
When `targetMap` matches the `currentMap`, the system queries the runtime `_G.game.world.grid` memory directly. It loops over the active tiles looking for a `scene` tile with a matching `linkId`.
*To prevent infinite transition loops, it actively ignores the coordinates the player is currently stepping on (`excludeX`, `excludeY`).*

### Cross-Map Transitions
When `targetMap` differs from the current map, the system must search the target file *without* fully loading the map into memory and overwriting the game state.
1. It looks for `targetMap.json` on disk.
2. If found, it parses the JSON via `lib.json` and scans the `tiles` array for the matching `linkId`.
3. If no JSON exists, it falls back to parsing legacy `.lua` maps.

> [!CAUTION]
> The transition scanner fully supports Run-Length Encoding (RLE). If a target link is embedded in an RLE sequence of length 5, the scanner will intelligently return the exact center coordinate of the sequence.
