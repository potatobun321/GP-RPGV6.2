# Map Editor Guide

The Map Editor is an embedded, in-game level builder (`tools/editor/editor.lua`).

## Getting Started
1. Open the Developer Console (`~` or `F1`).
2. Type `edit` to slide open the Editor panel.

## Controls & Painting
- **Left-Click**: Paints the selected tile onto the grid.
- **Right-Click**: Erases a tile (turns it into 'void' space).
- **Middle Mouse Button (Hold & Drag)**: Pans the map freely.
- **Space + Left-Click (Hold & Drag)**: Alternative mapping to pan the map freely.
- **Mouse Wheel**: Smooth, continuous zoom in and out.
- **`0` Hotkey**: "Fit To Screen". Instantly calculates the exact scale required to frame the entire map bounds perfectly on your screen.
- **Top Bar Buttons**:
  - **UNDO/REDO**: Steps back or forward in your painting history.
  - **AREA**: Click and drag to fill a rectangular area with the selected tile. (Right-click dragging erases an area).
  - **CBOUNDS**: Click and drag to draw a box defining the Camera Bounds. This prevents the camera from panning off the edge of the map.

## Camera Movement (Free-Cam)
When the Editor is active, your camera detaches from the player.
- Use **W, A, S, D** to fly the camera around the map freely.
- Press **Shift + F** to toggle Free-Cam mode manually while playing.

## Scene Linking (Doors)
The engine features a bidirectional "Link ID" system for seamless map transitions.

### Step 1: Placing the Link
1. Select the `scene` tile in the editor palette.
2. Click on the map grid.
3. A modal popup will appear listing all discovered playable maps.

### Step 2: Configuring the Link
1. **Target Map**: Select the destination map (e.g., `forest`).
2. **Link ID**: Select a unique identifier (`A`, `B`, `C`, `D`, `E`).

### Step 3: Completing the Connection
For the transition to work, the destination map must have a corresponding scene tile pointing back!
- In Map 1: You place a door. Target: `forest`. Link: `A`.
- In Map 2 (`forest`): You place a door. Target: `map1`. Link: `A`.

If you step on a door and it fails, the console will print an error indicating that the destination map lacks a matching Link ID.
