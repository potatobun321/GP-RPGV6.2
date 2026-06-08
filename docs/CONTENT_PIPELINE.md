# Content Pipeline

The engine utilizes a modular, data-driven "Factory" architecture (`engine/core/factory.lua`). This allows you to add new tiles and characters without touching core engine logic. 

## 1. Adding a New Tile

Tiles are defined dynamically by dropping files into the `content/tiles/` folder.

1. **Add the Asset**: Place an image (e.g., `myTile.png`) in `content/tiles/`. The engine uses nearest-neighbor filtering, keeping pixel art sharp.
2. **Create the Script**: Create `content/tiles/myTile.lua` with the following template:

```lua
return {
    id = "myTile",              -- The unique ID used in the editor
    name = "My Custom Tile",    -- The display name
    colorKey = "grass",         -- Fallback color from core/theme.lua
    draw_style = "fill",        -- "fill" or "line"
    texturePath = "content/tiles/myTile.png", 
    flags = {
        -- Overridden properties go here!
    }
}
```

### Tile Property Inheritance
All tiles automatically inherit the defaults located in `content/tiles/flagTable.lua`. Currently, defaults are:
- `solid = false`
- `speedMod = 1.0`
- `healthAffect = 0`
- `interactMessage = false`

You **only** need to declare a flag in your custom tile if you want it to behave differently.

**Example: A Radioactive Wall**
```lua
flags = {
    solid = true,          -- Blocks movement
    healthAffect = -10,    -- Drains 10 HP per second
    interactMessage = "It's glowing green. I shouldn't touch this."
}
```

When the game boots, the `Factory` seamlessly merges your script with the defaults. Your new tile instantly appears in the map editor palette.

---

## 2. Adding a New Character

Characters are loaded dynamically from folders within `content/characters/`.

To create a new character named "Goblin":
1. Create the folder: `content/characters/goblin/`
2. Add a spritesheet: `content/characters/goblin/spritesheet.png`
3. Add a logic file (optional): `content/characters/goblin/goblin.lua`

**Example `goblin.lua`:**
```lua
return {
    name = "Goblin",
    speed = 150,
    colorKey = "enemy",
    draw_style = "fill"
}
```

### Character Animations
If a character is animated, the Anim8tor tool (`anim` console command) can generate an `animations.lua` manifest.

**Example `animations.lua`:**
```lua
return {
    imagePath = "content/characters/goblin/spritesheet.png",
    frameWidth = 24,
    frameHeight = 24,
    animations = {
        walk_down = { frames = {1, 2, 3, 4}, durations = {0.1, 0.1, 0.1, 0.1} },
        idle_down = { frames = {1}, durations = {1.0} }
    }
}
```
