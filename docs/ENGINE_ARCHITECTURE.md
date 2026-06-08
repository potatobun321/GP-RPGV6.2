# GP-RPGV6.2 Engine Architecture Master Guide

This document is the current architecture snapshot for the GP-RPGV6.2 engine. It is written to serve as the definitive guide for future developers to understand the structure, subsystems, and flow of the codebase.

## 1. Core Philosophy

GP-RPGV6.2 is built for rapid iteration, embedded tooling, and runtime experimentation. It relies on a custom Entity Component System (ECS) paired with a robust data-driven Tilemap to power the environment, avoiding the memory bloat of treating every static tile as an entity.

## 2. Directory Structure

```text
GP-RPGV6.2/
├── engine/             # The core logic and systems
│   ├── core/           # Utilities (Console, Camera, Factory, Event Bus, Transitions)
│   ├── ecs/            # Components, Registry, and logic Systems
│   ├── ui/             # In-game UI framework
│   └── world/          # The Tilemap array manager and Map Registry
├── content/            # Data-driven game assets
│   ├── characters/     # Sprites and animation manifests
│   ├── maps/           # Developer map base files (.json or .lua)
│   └── tiles/          # Tile definitions and static textures
├── maps/               # User-generated map save files (.json)
├── tools/              # Embedded editors
│   ├── anim8tor/       # Animation creation tool
│   └── editor/         # The in-game map editor
├── scenes/             # High-level game states
│   ├── animator.lua    # The scene for Anim8tor
│   └── game.lua        # The primary gameplay loop
└── docs/               # Technical documentation
```

## 3. Subsystems

### 3.1. ECS (Entity Component System)
Located in `engine/ecs/`. It handles dynamic interactive objects (Player, enemies, projectiles).
- **Registry (`registry.lua`)**: Manages integer IDs and component tables. Uses `queryCached` to optimize tight loops.
- **Components (`components.lua`)**: Pure data structures without logic (`Transform`, `Velocity`, `Health`).
- **Systems (`systems.lua`)**: Loops that mutate components every frame (e.g., `MovementSystem`, `RenderSystem`).

### 3.2. Tilemap & World Data
Located in `engine/world/tilemap.lua`.
- Manages the grid array of static tiles.
- Responsible for serialization to and from JSON.
- Provides collision (`isSolidPixel`) and rendering via optimized `SpriteBatch`.

### 3.3. Embedded Tooling
The engine ships with its tools embedded into the runtime:
- **Map Editor (`tools/editor/editor.lua`)**: Allows real-time tile placement, box-filling, and scene link creation in the world.
- **Anim8tor (`tools/anim8tor/scene.lua`)**: An interface for tweaking frame timings on sprite-sheets.
- **Developer Console (`engine/core/console.lua`)**: A Quake-style drop-down providing a sandboxed Lua environment for executing live commands and altering state.

## 4. Data Flows & Pipelines

### 4.1. Map Lifecycle
- **Discovery**: `engine/world/map_registry.lua` scans `content/maps/` and `maps/` to dynamically build the list of playable maps, feeding the editor and console.
- **Creation**: Use `newmap.name` to spawn a new JSON map based on `content/maps/template.json`.
- **Serialization**: Maps are saved automatically on transitions or via the `save` command, utilizing a sparse-array JSON format for file-size efficiency.

### 4.2. Content Pipeline (Tiles & Entities)
- The **Factory** (`engine/core/factory.lua`) acts as the bridge between files and logic.
- Upon startup, it scans `content/tiles/`. It reads individual `.lua` tile scripts and seamlessly merges them with `flagTable.lua` (the master defaults). 
- To add a new tile, you just drop a `.lua` and `.png` file into `content/tiles/`. The engine builds it instantly.

## 5. Runtime Flow

1. `main.lua`: The entry point. Loads the global `Event` bus, initializes the `Factory`, and boots the `Game` scene.
2. `scenes/game.lua:load()`: Spawns the `Tilemap`, creates the player entity, and configures the `Console`.
3. `scenes/game.lua:update()`: 
   - Receives input.
   - Updates ECS `Systems` sequentially (Input -> Movement -> Tile Effects -> Animation).
   - Instructs the `Camera` to track the player's updated `Transform`.
4. `scenes/game.lua:draw()`: 
   - Attaches the camera transform.
   - Renders the `Tilemap` (base layer).
   - Renders ECS entities via `RenderSystem` (dynamic layer).
   - Detaches the camera and draws `UI`, `Editor`, and `Console` in screen-space.
