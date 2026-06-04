# Console Guide

The runtime console is triggered by pressing the **tilde (`~`)** key during gameplay. 
It functions as both a command shell and a Lua REPL. It is sandboxed, so variables set in the console do not overwrite engine globals unless explicitly permitted.

## Built-in Commands

Type `commands()` or `help()` in the console to see this list in-game.

### Tools & Editor
- `edit()`: Toggles the Map Editor panel.
- `anim()`: Opens the Anim8tor sprite tool.
- `charc()`: Prints the current player stats in an ASCII table.
- `clear()`: Clears the console logs.
- `history()`: Displays the history of entered commands.

### Map Management
- `save()`: Saves the current map.
- `save('name')`: Saves the map under a new filename.
- `loadmap('name')`: Loads a map by name.
- `resize(N)`: Resizes all map tiles to N pixels (e.g., `resize(64)`).

### Player Stats
- `hp(N)`: Sets current and maximum health.
- `spd(N)`: Sets base movement speed.
- `atk(N)`, `def(N)`, `endr(N)`, `int(N)`: Sets character stats.

### Camera & Display
- `theme('name')`: Sets the color theme (`neon`, `dracula`, `dark`, `light`).
- `zoom.set(N)`: Sets permanent default zoom.
- `zoom.temp(N)`: Sets an active zoom level used when holding `Shift+Z`.

## Lua REPL Features

Because the console parses commands as Lua strings, you can execute arbitrary mathematical operations or logic:

```lua
> 10 * 5
= 50
> math.sqrt(144)
= 12
> player.x
= 320
```

Variables assigned in the console are stored in the console's isolated environment (`Console.env`) and will not pollute the game's `_G`.
