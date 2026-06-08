# Map System Reference

The Map System orchestrates how environments are managed, serialized, and discovered (`engine/world/`).

## 1. Map Formats
The engine supports multiple map formats for backward compatibility, though modern maps save exclusively as JSON.

- **Active Format (.json)**: Stored in `maps/` (user saves) or `content/maps/` (developer base files). Contains dimensions, tile sizes, camera bounds, and RLE-compressed tile arrays.
- **Legacy Format (.lua)**: Stored in `content/maps/`. The engine can still load these, but if saved, they are automatically migrated to `.json`.

## 2. Map Discovery (`MapRegistry`)
Map discovery is handled centrally by `engine/world/map_registry.lua`.
- The registry scans both `content/maps/` and `maps/` for `.json` and `.lua` files.
- It automatically deduplicates entries (if `map1.lua` and `map1.json` both exist, it only lists `map1`).
- It hides system files (like `template`) from all UI.
- **Why?** This ensures the Editor Link Popup, the Editor Map Selection Popup, and the Console's `listmaps` command all see the exact same accurate list of playable maps without hardcoding.

## 3. Map Lifecycle & Creation
Map creation is an explicit, intentional action designed to prevent accidental blank maps.

### Creation Workflow (`newmap.name`)
1. The engine checks if the requested name already exists.
2. The engine loads the hidden `content/maps/template.json` blueprint (a default 30x30 grass and wall setup).
3. The engine renames the current context and saves the map to disk immediately.

### Graceful Fallbacks
Attempting to load a non-existent map via transitions or `loadmap` will no longer generate an empty 31x31 void. Instead, the engine halts the transition and prints a clear error, preventing infinite loops or corrupted save states.

## 4. Serialization
Maps are saved using "Sparse Tabling".
- The engine does not save thousands of "empty" array slots.
- It iterates the `Tilemap` grid and clusters horizontal identical tiles into RLE (Run-Length Encoded) objects `{x, y, len, id}`.
- This results in extremely small JSON files that load blazingly fast. Maps automatically serialize when transitioning or closing the game.
