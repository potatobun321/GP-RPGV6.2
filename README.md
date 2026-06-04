# GP-RPGV6.2

A modular 2D RPG engine built with LÖVE (Love2D), focused on rapid content creation, editor-driven workflows, and extensible ECS-based game architecture.

## Overview

GP-RPGV6.2 is a custom RPG engine designed to provide a complete workflow for building 2D RPG experiences. The project combines runtime systems, content pipelines, map management, animation tooling, and editor support into a unified framework.

The engine emphasizes:

* Modular architecture
* Data-driven content
* ECS (Entity Component System) design
* Editor-assisted development
* JSON-based map workflows
* Expandability for future RPG systems

---

## Features

### Core Engine

* Entity Component System (ECS)
* Event-driven architecture
* Camera management
* Input handling
* Theme management
* Asset loading system
* Scene management
* Animation framework
* Transition system

### World & Maps

* JSON map loading
* Dynamic map registry
* Tile-based world rendering
* Map transition support
* Tile metadata system
* Linked world navigation

### Content Creation

* Tile editor
* Animation editor (Anim8tor)
* Content pipelines
* Map serialization tools
* Tile template system

### Documentation

Extensive project documentation covering:

* Engine architecture
* ECS concepts
* Map creation
* Tile linking
* Content workflows
* Console usage
* Transition systems

---

## Project Structure

```text
engine/
    core/
    ecs/
    world/

content/
    maps/
    tiles/
    characters/

tools/
    editor/
    anim8tor/

docs/
    architecture and guides

tests/
    engine tests
```

---

## Running The Project

### Requirements

* LÖVE 11.x or newer

### Launch

```bash
love .
```

Or open the project through your installed LÖVE runtime.

---

## Development Philosophy

The project is built around the idea that game creation tools should be part of the engine itself.

Rather than relying entirely on external editors, GP-RPGV6.2 aims to provide integrated workflows for creating maps, animations, content, and gameplay systems directly within the development environment.

---

## Current Status

Active development.

Major areas currently under development include:

* Expanded map workflows
* Transition improvements
* ECS expansion
* Tooling enhancements
* Content pipeline improvements

---

## License

This project is currently distributed for educational and personal development purposes.

Future licensing may change as development progresses.
