# GP-RPGV6.2 Architecture Overview

## Core Philosophy
This engine is built for rapid iteration, embedded tooling, and runtime experimentation rather than competing with established AAA engines. It relies on a custom ECS (Entity Component System) paired with specific Data-Driven sub-systems.

## Sub-Systems

### 1. ECS (Entity Component System)
The heart of the runtime logic is located in `engine/ecs/`. 
- **Registry:** Stores entities (integer IDs) and components (tables). It features query caching to optimize frequent lookups (like `MovementSystem` or `RenderSystem`).
- **Systems:** Functions that iterate over entities with specific components. Found in `systems.lua`, these include `MovementSystem`, `TileEffectSystem`, `AnimationControllerSystem`, etc.

### 2. Hybrid Tile Data (World Management)
Historically, the engine spawned every tile as an ECS entity. This caused significant memory bloat for large maps.
- **Current Architecture:** Static tile rendering and collision data are managed entirely within a 2D array inside `engine/world/tilemap.lua`.
- **Integration:** The `Tilemap` builds its own `SpriteBatch` for rendering and handles solid checks. The ECS (specifically `TileEffectSystem`) queries the tile map data beneath players to trigger interactive effects (like teleporters or lava damage).

### 3. Factory Pipeline
Located in `engine/core/factory.lua`, the factory is responsible for:
- Assembling complex entities from definitions.
- Loading tiles from `content/tiles/`.
- Dynamically discovering characters from `content/characters/` based on folder structure.

### 4. Embedded Tooling
The engine does not have an external editor.
- **Console (`console.lua`):** A Quake-style dropdown terminal that provides direct access to a sandboxed Lua environment. Variables and commands interact safely without polluting `_G`.
- **Editor (`editor.lua`):** A runtime map editor that modifies the `Tilemap` 2D array directly and serializes back to JSON.
- **Anim8tor (`scene.lua`):** A visual tool for creating and debugging animation definitions.

## File Hierarchy

```
GP-RPGV6.2/
├── engine/             # Core engine source
│   ├── core/           # Engine subsystems (Console, Camera, Context)
│   ├── ecs/            # Components, Registry, Systems
│   ├── ui/             # Runtime UI rendering
│   └── world/          # Tilemap and map serialization
├── content/            # Data-driven definitions
│   ├── maps/           # JSON map files
│   ├── tiles/          # Tile definitions and textures
│   └── characters/     # Character sprites and animations
├── tools/              # Embedded tools
│   ├── editor/         # Runtime map editor
│   └── anim8tor/       # Animation tool
└── docs/               # Technical Documentation
```
