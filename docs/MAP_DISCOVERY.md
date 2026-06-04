# Map Discovery

Map discovery is handled centrally by the `engine/world/map_registry.lua` module. 
This ensures that all UI elements, editor popups, and console commands see the exact same list of available maps.

## How Maps Are Discovered

When `MapRegistry.getPlayableMaps()` is called, the engine scans two locations:
1. `content/maps/` (The developer source directory)
2. `maps/` (The user save directory)

### Supported Extensions
The registry scans for both `.json` and `.lua` files. It deduplicates the list (e.g., if both `map1.json` and `map1.lua` exist, it only lists `map1` once).

## System vs Playable Maps

Not all files in the map directories are meant to be played.

- **System Maps**: Maps like `template` (from `template.json`) are hardcoded to be excluded from discovery. They are blueprints or engine resources.
- **Playable Maps**: Any other valid `.json` or `.lua` map file is considered playable and will appear in the UI.

## UI Integration

- **Editor Map Browser & Selection Popup**: Uses `MapRegistry` to populate its options dynamically. When you open the map selection popup, it guarantees all JSON and LUA maps are listed.
- **Console Commands**: You can view the discovered list at any time by typing `listmaps` in the console.

## No Hardcoding

Because discovery is fully dynamic:
- You do not need to manually register new maps in a list.
- Creating a map via `newmap` makes it instantly available in the link popup.
- There are no hardcoded fallbacks like `{"map1"}`.
