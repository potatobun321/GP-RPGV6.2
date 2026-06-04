# Content Creation Guide

This document explains how to add new assets to the engine dynamically without touching the core source code.

## 1. Adding a New Tile

Tiles are defined in `content/tiles/`. The engine scans this folder at startup.

To create a new tile:
1. Create a new `.lua` file in `content/tiles/`, e.g., `content/tiles/lava.lua`.
2. Return a table with the tile's properties:

```lua
-- content/tiles/lava.lua
return {
    id = "lava",
    texturePath = "content/tiles/lava_tex.png", -- Optional
    colorKey = "danger",                        -- Fallback color if no texture
    draw_style = "fill",
    flags = {
        solid = false,
        healthAffect = -20.0,                   -- Drains 20 HP per second
        speedMod = 0.5                          -- Slows player down by 50%
    }
}
```

The tile will automatically appear in the map editor's palette (`edit()`).

## 2. Adding a New Character

Characters are loaded dynamically from folders within `content/characters/`.

To create a new character named "Goblin":
1. Create the folder: `content/characters/goblin/`
2. Add a spritesheet: `content/characters/goblin/goblin.png` or `spritesheet.png`
3. Add an animation manifest: `content/characters/goblin/animations.lua` (if the character is animated).
4. Add a specific logic file (optional): `content/characters/goblin/goblin.lua`

**Example `goblin.lua` Definition:**
```lua
return {
    name = "Goblin",
    speed = 150,
    colorKey = "enemy",
    draw_style = "fill"
}
```
If you omit the `.lua` file, the engine will use default fallback values based on the folder name.

## 3. Creating Animations

If a character needs animations, create an `animations.lua` file inside their folder. The Anim8tor tool (`anim()`) can help generate this file automatically.

Example `animations.lua`:
```lua
return {
    imagePath = "content/characters/player/spritesheet.png",
    frameWidth = 24,
    frameHeight = 24,
    animations = {
        walk_down = {
            frames = {1, 2, 3, 4},
            durations = {0.1, 0.1, 0.1, 0.1}
        },
        idle_down = {
            frames = {1},
            durations = {1.0}
        }
    }
}
```
