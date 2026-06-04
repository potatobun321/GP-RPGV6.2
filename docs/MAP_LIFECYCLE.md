# Map Lifecycle

The map lifecycle defines how maps move from creation, to being edited, saved, loaded, linked, and eventually played.

## The Standard Workflow

1. **Create Map**: A new map is explicitly created using the `newmap.name` console command. This command loads a system `template.json` blueprint and saves it under the new name.
2. **Edit Map**: Once created, the map can be edited in-game by pressing `edit` in the console or pressing the map editor key to place tiles, props, and links.
3. **Save Map**: The map is saved via the `save` command or automatically when transitioning to another map. Maps are saved to `maps/` in the user save directory in `.json` format, or in `content/maps/` during development.
4. **Load Map**: Maps are loaded manually using `loadmap.name` or automatically during gameplay transitions. Attempting to load a non-existent map will result in an error instead of implicitly generating an empty canvas.
5. **Link Map**: In the editor, a map can be linked by placing a "scene" tile. The link tile popup uses the central Map Registry to discover all playable maps, allowing you to select the destination map and link ID.
6. **Play Map**: Players transition between maps smoothly using link tiles, experiencing the interconnected world.

## Key Principles

- **Intentional Creation**: Maps are no longer created by accident when a typo is made in a loading command or a transition. Creation is an explicit action (`newmap`).
- **Centralized Discovery**: All systems (UI, Popups, Console) use the same `MapRegistry` to find maps, ensuring consistency across the engine.
- **Graceful Failures**: If a map doesn't exist, the game will no longer generate a void canvas. It will report a missing map error and halt the transition, preventing save corruption or getting stuck.
