# Map Formats

The engine supports multiple map formats to maintain compatibility with legacy data while moving towards a standard JSON structure.

## Active Format: JSON (`.json`)

The primary and recommended format for all maps is JSON.
- **Location**: `maps/` (user saves) or `content/maps/` (developer base maps)
- **Structure**: Contains map dimensions, tile sizes, camera bounds, and RLE-compressed tile arrays.
- **Usage**: When a map is saved (via `save` or Editor), it is always written as a `.json` file.

## Legacy Format: LUA (`.lua`)

The legacy format used Lua scripts returning a table of map data.
- **Location**: `content/maps/`
- **Usage**: The engine's loader (`tilemap.loadMap`) and transition system can still read `.lua` maps. 
- **Migration**: If a `.lua` map is loaded and subsequently saved, it will be saved as a `.json` file, effectively migrating it to the modern format. 

## Format Compatibility Matrix

| System | `.json` (save dir) | `.json` (content dir) | `.lua` (content dir) |
| :--- | :---: | :---: | :---: |
| Editor Map Browser | ✅ | ✅ | ✅ |
| Map Selection Popup | ✅ | ✅ | ✅ |
| Tilemap Loader | ✅ | ✅ | ✅ |
| Transition System | ✅ | ✅ | ✅ |
| Console Commands | ✅ | ✅ | ✅ |

All systems fully support all valid map formats and locations thanks to the unified `MapRegistry` and robust loader fallbacks.
