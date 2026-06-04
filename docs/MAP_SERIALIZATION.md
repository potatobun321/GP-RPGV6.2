# Map Serialization System

## Overview
Maps in GP-RPGV6.2 are saved and loaded by the `engine/world/tilemap.lua` script. When the Editor saves a map, it is serialized to a standard `.json` format to allow robust parsing and editing.

## Run-Length Encoding (RLE)
To minimize memory footprint and file size, horizontal stretches of identical tiles are compressed using Run-Length Encoding.

Instead of outputting three adjacent grass tiles:
```json
{"x": 1, "y": 5, "id": "grass"}
{"x": 2, "y": 5, "id": "grass"}
{"x": 3, "y": 5, "id": "grass"}
```
The serializer will output a single run:
```json
{"x": 1, "y": 5, "len": 3, "id": "grass"}
```

## Custom Metadata & Defaults
Each tile template (defined in `content/tiles/`) provides default properties and flags.
When the tilemap saves a tile, it compares its properties against the template. **Only modifications are serialized.**

If a `Link Tile` has its `targetMap` set to `map2`, and the default template for Link Tiles already defines `targetMap = "map2"`, that field is omitted from the JSON to save space. It will be seamlessly reconstructed from the template during map load.

## Legacy Formats
The engine maintains backwards compatibility with an older `.lua` map format. 
When loading a map, the engine will search for:
1. `maps/mapName.json` (Save data overrides)
2. `content/maps/mapName.json` (Source map data)
3. `content/maps/mapName.lua` (Legacy source data)
