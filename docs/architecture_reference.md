# GP-RPGV6.2 Engine Architecture Reference

This document serves as a master reference for the GP-RPGV6.2 engine. It outlines the purpose of every core file in the project, what piece of the puzzle it solves, and how it fits into the overall architecture. 

Use this guide to track down where logic lives when you need to refactor or expand the engine.

---

## 1. The Entry Point

### `main.lua`
- **Purpose:** The absolute root of the engine. It is the first file Love2D executes.
- **What it does:** Initializes the window, loads the core engine modules, and delegates the primary `load`, `update`, and `draw` loops to the currently active Scene (e.g., `scenes/game.lua`).

---

## 2. Core Engine Services (`engine/core/`)

These files act as the backbone utilities and managers for the game.

### `context.lua`
- **Purpose:** The safe "Global State" manager.
- **What it does:** Entirely replaces fragile `_G` variables. It holds references to the active `world`, the `player` entity, and engine flags like `mapDirty` so different modules can communicate without polluting the global namespace.

### `factory.lua`
- **Purpose:** The Blueprint Spawner.
- **What it does:** Reads the raw data templates from your `content/` folder and uses them to construct living ECS Entities (like Tiles and Characters), assigning them their necessary Components.

### `assets.lua`
- **Purpose:** The RAM Optimizer (Memory Cache).
- **What it does:** Sits between the Factory and the Hard Drive. It ensures that if 1,000 tiles use `grass.png`, the image is only loaded into your computer's RAM exactly once, and a lightweight reference is handed to the entities.

### `camera.lua`
- **Purpose:** The Viewport Director.
- **What it does:** Handles smooth panning, zooming (`baseScale` and `activeScale`), and strict boundary enforcement (`customBounds`) so the player can never see off the edge of the map. It also handles the "Free Camera" logic used by the Map Editor.

### `console.lua`
- **Purpose:** The Developer Terminal.
- **What it does:** The drop-down menu (accessed via `~`) that allows you to execute commands (`help`, `edit`, `zoom`, `theme`) safely via a sandboxed execution environment. 

### `theme.lua`
- **Purpose:** The Color System.
- **What it does:** Stores centralized color palettes (`dark`, `light`, `neon`, `dracula`). Changing the theme here instantly updates all primitive shapes, UI elements, and untextured tiles across the entire game.

### `animation.lua`
- **Purpose:** The Sprite Animator.
- **What it does:** A wrapper for the `anim8` library that translates sprite-sheets into playable, looped animations for entities.

---

## 3. Entity-Component-System (`engine/ecs/`)

This is the architectural heart of the gameplay logic. It completely replaces the old Object-Oriented `object.lua` and `character.lua` files.

### `registry.lua`
- **Purpose:** The Database.
- **What it does:** Stores every entity in the game as a simple ID (number). It holds all attached components and allows Systems to query for specific types of entities blazingly fast.

### `components.lua`
- **Purpose:** The Data Definitions.
- **What it does:** Defines pure data structures. E.g., `Transform` (x,y,w,h), `Velocity` (speed), `Renderable` (texture), `Health` (hp), `Collider` (hitbox). Components have no logic, just data.

### `systems.lua`
- **Purpose:** The Logic Loops.
- **What it does:** Contains the actual gameplay math. 
  - *Example:* The `RenderSystem` queries the Registry for everything with a `Transform` and `Renderable` component, heavily optimizes them into a GPU `SpriteBatch`, and draws them to the screen in a single hardware call.

---

## 4. The World & Map (`engine/world/`)

### `tilemap.lua`
- **Purpose:** The Grid Manager.
- **What it does:** Manages the 2D array of tiles. It handles grid-to-pixel coordinate translation, dynamic boundary expansion (when you paint outside the map), and map serialization (saving and loading the grid to/from `.json` files).

---

## 5. User Interface (`engine/ui/`)

### `init.lua`
- **Purpose:** The GUI Framework.
- **What it does:** Provides a centralized, state-based UI library (buttons, panels, hover logic) heavily utilized by the Map Editor and available for future pause/inventory menus.

---

## 6. Scenes (`scenes/`)

### `game.lua`
- **Purpose:** The primary Gameplay State.
- **What it does:** Connects the World, the Camera, the ECS Systems, and the Map Editor together. It handles player inputs, updates the systems, and draws the final composited frame to the screen.

---

## 7. Tools (`tools/`)

### `editor/editor.lua`
- **Purpose:** The In-Game World Builder.
- **What it does:** A robust visual tool triggered by the `edit` command. It allows real-time tile painting, area filling, boundary manipulation, and map-linking, injecting changes directly into the `Tilemap` and `Registry`.

---

## 8. Content Data (`content/`)

This folder contains pure data, no engine logic.

- **`maps/`**: Stores all saved levels as strictly formatted `.json` files.
- **`tiles/`**: Stores `.lua` tables defining static tile properties (e.g., `grass`, `water`, `wall`, their flags, and texture paths).
- **`characters/`**: Stores sprite-sheets and stat definitions for players and enemies.
