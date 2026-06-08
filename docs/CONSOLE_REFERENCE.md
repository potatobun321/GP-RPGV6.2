# Console & Shortcuts Reference

The Developer Console (`engine/core/console.lua`) is the master control panel for the GP-RPGV6.2 engine. It runs pure Lua code in a sandboxed environment, allowing you to manipulate state in real-time.

## Opening the Console
Press **Tilde (`~` or `` ` ``)** or **F1** at any time during gameplay.

---

## 1. Map Management
The Map Registry manages all JSON and legacy LUA maps across the `maps/` and `content/maps/` directories.

- **`listmaps`**: Prints a list of all currently discovered playable maps.
- **`newmap.name`**: Creates a new map named `name.json` using the `template.json` blueprint.
- **`duplicatemap.src.dest`**: Duplicates map `src` into a new map `dest`.
- **`deletemap.name`**: Deletes the specified map from disk.
- **`save`**: Saves the map you are currently on.
- **`save.name`**: Saves the current map under a new filename (`name.json`).
- **`loadmap.name`**: Saves the current map and instantly loads `name`.
- **`resize.N`**: Dynamically scales the entire world grid and tiles to `N` pixels (e.g., `resize.64`).

---

## 2. Tools & Display
- **`edit`**: Toggles the Map Editor slide-in panel.
- **`anim`**: Transitions from the game scene into the Anim8tor Sprite Tool.
- **`theme.name`**: Changes the visual UI and primitive colors. Available: `neon`, `dracula`, `dark`, `light`.
- **`zoom.set(N)`**: Sets the permanent gameplay zoom level (0 to 5) (e.g., `zoom.set(3)`).
- **`zoom.temp(N)`**: Sets an active override gameplay zoom level.
- **`clear`**: Wipes the console logs clean.
- **`history`**: Displays previously entered console commands.

---

## 3. Player Stats & Debugging
- **`charc`**: Prints the player's stat block as an ASCII table.
- **`hp.N`**: Sets current and maximum Health.
- **`spd.N`**: Sets the base movement speed.
- **`atk.N`, `def.N`, `endr.N`, `int.N`**: Sets the respective combat stats.

*(Because the console acts as a Lua REPL, you can also execute raw code like `player.x = 0` or `math.sqrt(100)`)*

---

## 4. Keyboard Shortcuts

**Global Actions:**
- **`~` or `F1`**: Toggle Developer Console.
- **`E`**: Interact with a tile (triggers `interactMessage` if the tile has one).
- **`Esc`**: Quit game.

**Editor specific (when `edit()` is active):**
- **Left-Click**: Paint selected tile.
- **Right-Click**: Erase tile (turns to void).
- **Mouse Wheel**: Scroll tile palette in the panel.
- **`W`, `A`, `S`, `D`**: Move the camera freely when detached from the player.
- **`Shift` + `F`**: Toggle Free-Cam mode on or off manually.
