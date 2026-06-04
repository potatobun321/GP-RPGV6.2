# Tile Linking Guide

## Overview
Tile Linking provides a bi-directional portal architecture. A player standing on Link Tile A connects to Link Tile B.

## Adding a Link via Editor
1. Open the Map Editor (`~` then `edit()`).
2. Select the **Link Tile** (doorway icon) from the palette.
3. Click a tile coordinate on the map.
4. **Popup 1:** "Select Map". Pick the map the link goes to (e.g. `map2`).
5. **Popup 2:** "Select Link". Pick the ID the link connects to (e.g. `A`).

## Bidirectional Logic
When you place a link, you configure *where it points*. You do not configure *its own ID*.

> [!WARNING]
> A Link Tile acts as both an Exit and an Entrance.
> If a tile points to `map2` -> `A`, it implies that its **own** ID is `A`. If a player travels from `map2` pointing to `map1` -> `A`, the system will search `map1` for a tile whose target points to `A`!

## Link Metadata Structure
Inside a JSON map, a link tile is defined as:
```json
{
  "x": 10,
  "y": 15,
  "id": "scene",
  "flags": {
    "targetMap": "map2",
    "linkId": "A"
  }
}
```

If these fields are missing, they implicitly fall back to the defaults defined in `content/tiles/scene.lua`. Always ensure that bi-directional links share identical `linkId` values on both maps.
