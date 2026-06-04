# GP-RPG-7: The 2.5D Hybrid Expansion Plan

I love this direction! You are completely right: a **hybrid approach** (combining ECS for performance-heavy loops and clean OOP objects/controllers for gameplay systems) is often much more practical and faster to develop than strict dogmatic ECS.

Using a **pseudo-Z-axis visual illusion** with mathematical elevation levels (`z_level`) is a brilliant retro-RPG trick (think *Alundra*, *Landstalker*, or *Zelda*). It gives you climbing, jumping, and falling with highly performant 2D mathematics.

Here is how our hybrid engine will implement your pseudo-Z-axis and layers!

---

## 1. How the Pseudo-Z-Axis Works

We will divide height into two distinct values:
1. **`z_level` (Logical Elevation - Integer):** Represents the platform layer the entity is standing on (e.g., `0` for ground level, `1` for a table/ledge, `2` for a mountain cliff).
2. **`z_height` (Visual Height - Float):** Represents how high the entity currently is in the air above their standing plane (e.g., during a jump).

### The Visual Illusion
When drawing any entity:
$$\text{Render Y} = \text{Transform.y} - \text{z\_height} - (\text{z\_level} \times \text{layer\_height})$$
This simple subtraction offsets the sprite upward, perfectly selling the illusion of height and depth!

---

## 2. The Hybrid Elevation Rules

We will build an OOP **`HeightController`** class. It will manage the collision rules between `player.z_level` / `player.z_height` and `tile.z_level` during movement updates:

```
                  [ Player attempts to enter a Tile ]
                                   │
                 Is Tile.z_level <= Player.z_level?
                       ├── Yes ──> Walk normally (or fall down if Tile.z_level is lower)
                       └── No  ──> Is Player.z_height >= (Tile.z_level - Player.z_level) * 32?
                                         ├── Yes ──> Land on ledge! Update Player.z_level
                                         └── No  ──> BLOCKED (Act as a solid wall)
```

- **Walking off a Ledge:** If the player walks from `z_level = 1` to `z_level = 0`, they instantly transition to the lower `z_level`, their visual `z_height` is increased to compensate, and gravity naturally falls them back to the ground.
- **Jumping:** When the spacebar is pressed:
  - We apply upward velocity: $v_z = \text{jump\_force}$.
  - Every frame, $z\_height = z\_height + v_z \times dt$.
  - $v_z = v_z - \text{gravity} \times dt$.
  - Once $z\_height \le 0$, the player lands!

---

## 3. Tilemap Layers (Under, Behind, Over)

To make layers look visually stunning, the `RenderSystem` will perform depth sorting based on `z_level` and `Transform.y`.
- **Layer 1 (Ground):** Always drawn first.
- **Layer 2 (Playground / Obstacles):** Drawn and dynamically sorted. Characters, items, and cliffs are sorted by their bottom `Y` coordinate so you can walk in front of or behind them.
- **Layer 3 (Overhead):** Always drawn last (e.g., tree canopy, roof tiles) so the player passes underneath them.

---

## Proposed Changes

### Phase 1: Handmade UI Asset Slicer (Nine-Slice)
- Update `engine/ui/init.lua` with a new `NineSlice` draw function.
- Load handmade UI window/button assets to replace the dark primitive colors.

### Phase 2: Hybrid Height Controller & Y-Sorting
- Modify `Transform` to include `z_level` and `z_height`.
- Implement the parabolic jump physics inside a clean `engine/core/physics.lua` OOP controller.
- Update `RenderSystem` to sort and draw layers (`ground`, `play`, `overhead`).

### Phase 3: Dynamic Collision Elevation
- Integrate the elevation checks into `Tilemap:isSolidPixel`. A block is only solid if your current height is too low to climb it!
