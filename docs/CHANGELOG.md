# GP-RPGV6.2 Changelog

## [Phase 2 Final Integration] - Camera System Overhaul
- **Camera Profiles**: Gameplay and Editor cameras now use completely independent profiles to prevent state contamination.
- **Gameplay Zoom Ladder**: Standardized to discrete integer zoom levels (0 to 6) to eliminate sub-pixel shimmering and ensure pixel-perfect presentation.
- **Editor Continuous Zoom**: The editor now correctly uses Mouse Wheel scrolling for continuous arbitrary floating-point zoom.
- **Editor Fit-to-Screen**: Pressing `0` in Editor Mode instantly calculates and applies the exact scale required to frame the entire map on-screen.
- **Bounds Redesign**: Camera bounds now solely restrict camera position (center clamping) and will never violently overwrite user zoom to hide void space.
- **Editor Drag Navigation**: Implemented modern canvas panning. Hold the Middle Mouse Button (MMB) or Space+Left-Click to drag the map intuitively.
- **Removed Keyboard Panning**: Arrow keys no longer pan the editor camera. The workflow is completely mouse-driven.
- **Command Migration**: `zoom.set N` and `zoom.temp N` now strictly enforce integers `0-6`. `zoom.temp clear` instantly drops the active override.
- **Backward Compatibility**: `tilemap.lua` now natively saves `zoomLevel` but silently falls back and converts legacy `baseScale` floats into discrete integer indices to ensure older maps never break.
