# Camera Systems Architecture

The GP-RPGV6.2 engine utilizes a dual-profile camera architecture to serve two fundamentally different experiences: Gameplay (Player-focused) and Editor (Developer-focused). 

**The Golden Rule:** The Gameplay profile and the Editor profile must never mutate each other's state. 

## 1. Camera Profiles

### Gameplay Profile
- **Purpose**: Player experience.
- **Characteristics**: Bounded, pixel-perfect presentation, consistent framing.
- **State**: `x`, `y`, `zoomLevel`, `targetZoomLevel`, `_isFreeCam`.

### Editor Profile
- **Purpose**: Developer productivity.
- **Characteristics**: Unbounded, continuous float scaling via mouse wheel, void visibility allowed.
- **State**: `x`, `y`, `scale`, `targetScale`, `isFreeCam`.

## 2. The Zoom Ladder (Gameplay)
To prevent sub-pixel shimmering caused by the engine's nearest-neighbor filtering, Gameplay uses **Discrete Zoom Levels (0 to 6)**. This enforces strict integer multiplier scaling. 

**Authoritative Ladder (Based on canonical 30x30 map at 1080p):**
- **Zoom 0** (Scale 1.0x): Extreme overview. Shows ~60x33 tiles.
- **Zoom 1** (Scale 2.0x): Open fields / default RPG scale. Shows ~30x16 tiles.
- **Zoom 2** (Scale 3.0x): Indoor dungeons. Shows ~20x11 tiles.
- **Zoom 3** (Scale 4.0x): Action corridors. Shows ~15x8 tiles.
- **Zoom 4** (Scale 5.0x): Dense puzzle focus. Shows ~12x6 tiles.
- **Zoom 5** (Scale 6.0x): Cinematic focus. Shows ~10x5 tiles.
- **Zoom 6** (Scale 7.0x): Extreme close-up details.

## 3. Editor Controls
- **Middle Mouse Button (Drag)**: Smooth, 1:1 canvas panning.
- **Space + Left Click (Drag)**: Laptop-friendly trackpad fallback for canvas panning.
- **Scroll Wheel**: Continuous zooming in and out (e.g. `2.37x`).
- **`0` Hotkey (Fit To Screen)**: Instantly calculates the exact scale required to frame the entire map bounds perfectly on screen, dynamically adjusting for resolution and map dimensions.

## 4. Bounds System (Center Clamped)
Camera Bounds exist to constrain the player's view to a specific region (like a room).
- **Position Control**: Bounds restrict the **center coordinate** of the camera.
- **Void Allowed**: If the player zooms out to Level 0 in a tiny 4x4 room, the engine perfectly centers the room on the screen and renders the black void symmetrically around it. 
- **No Zoom Hijacking**: Bounds are strictly forbidden from mutating the player's zoom state. 

## 5. Console Commands
- **`zoom.set N`**: Sets the persistent Gameplay Zoom Level. Rejects floats. Accepts `0` through `6`.
- **`zoom.temp N`**: Temporarily overrides the Gameplay camera zoom. Accepts `0` through `6`.
- **`zoom.temp clear`**: Clears the temporary override and instantly restores the persistent `zoom.set` level as the active source of truth.

## 6. Legacy Migration & Serialization
`.json` maps now serialize `zoomLevel = N`. If an older map is loaded containing a continuous `baseScale` float, it seamlessly mathematically migrates it to the discrete integer ladder to prevent crashing.

**Migration Table:**
- `baseScale 1.0` -> `Zoom 0`
- `baseScale 2.0` -> `Zoom 1`
- `baseScale 3.0` -> `Zoom 2`
- `baseScale 4.0` -> `Zoom 3`
- `baseScale 5.0` -> `Zoom 4`
- `baseScale 6.0` -> `Zoom 5`
- `baseScale 7.0` -> `Zoom 6`
