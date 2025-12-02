# Visibility Graph Rive Asset Specification

**File:** `visibility_graph.riv`
**Status:** ⚠️ **TO BE CREATED** - Requires Rive Editor

## Overview
This Rive animation displays the Universal Visibility Graph showing a celestial object's altitude over time with moon interference overlay and prime viewing window highlights.

## Rive Configuration

### Artboard
- **Name:** `VisibilityGraph`
- **Dimensions:** 400 x 300px (or responsive)
- **Background:** Deep Cosmos (#0A0E27) - transparent recommended

### State Machine
- **Name:** `GraphLogic`

### State Machine Inputs

| Input Name | Type | Range | Description |
|------------|------|-------|-------------|
| `objectAltitude` | Number | 0-100 | Normalized altitude of the celestial object (0 = horizon, 100 = zenith/90°) |
| `moonInterference` | Number | 0-100 | Moon wash intensity (0 = no interference, 100 = maximum) |
| `timeScrubber` | Number | 0-100 | Time scrubber position (0 = Now, 100 = +12 hours) - Optional for MVP |
| `isOptimal` | Boolean | true/false | True when in Prime Window (altitude > 30° AND interference < 30) |

## Visual Design Requirements

### Graph Elements

1. **X-Axis (Time)**
   - Label: "Time (Next 12 Hours)"
   - Range: Now → +12 hours
   - Labels: "6 PM", "9 PM", "12 AM", "3 AM", "6 AM" (example times)
   - Color: White with 50% opacity
   - Font: Monospace or clean sans-serif

2. **Y-Axis (Altitude)**
   - Label: "Altitude (°)"
   - Range: 0° (horizon) to 90° (zenith)
   - Grid lines at 0°, 30°, 60°, 90°
   - Color: White with 30% opacity
   - Highlight 30° line (Prime Window threshold)

3. **Object Altitude Curve**
   - **Color:** Neon Cyan (#00E5FF)
   - **Style:** Smooth curved line, 2-3px thickness
   - **Glow:** Optional subtle glow effect
   - **Animation:** Bind to `objectAltitude` input
   - **Behavior:** Line should animate/morph based on altitude value

4. **Moon Interference Overlay**
   - **Color:** White (#FFFFFF)
   - **Style:** Gradient or secondary curve showing moon brightness
   - **Opacity:** Variable based on `moonInterference` input (0-100)
   - **Animation:** Fade in/out based on interference level
   - **Visual:** Could be background fill, gradient overlay, or separate curve

5. **Prime Window Highlighting**
   - **Trigger:** When `isOptimal` = true
   - **Visual:** Green glow, highlighted region, or indicator badge
   - **Color:** Green/Lime accent (#00FF00 or similar)
   - **Animation:** Smooth fade in/out, optional pulse effect
   - **Position:** Highlight time ranges on graph where conditions are met

6. **Interactive Scrubber (Optional MVP)**
   - **Bind to:** `timeScrubber` input
   - **Visual:** Vertical line that moves along X-axis
   - **Interaction:** User can drag to see values at different times
   - **Feedback:** Show tooltip with time and altitude values

## Animation Behaviors

- **Idle State:** Graph displays static curves based on input values
- **Update Transition:** When inputs change, smoothly animate curves (200-300ms ease-in-out)
- **Prime Window:** When `isOptimal` = true, trigger highlight animation
- **Moon Interference:** Opacity/intensity changes smoothly with `moonInterference` value

## Design Style

- **Theme:** Deep Cosmos aesthetic (dark background, neon accents)
- **Typography:** Clean, modern, monospace for numerical labels
- **Colors:**
  - Object Curve: Neon Cyan (#00E5FF)
  - Moon Overlay: White (#FFFFFF) with variable opacity
  - Prime Window: Green/Lime accent
  - Grid/Axes: White with low opacity (30-50%)
  - Background: Transparent or Deep Cosmos (#0A0E27)

## Performance Requirements

- Target: 60fps animation
- Smooth transitions for all input changes
- Lightweight asset size (prefer vector over raster)

## Testing Notes

- Flutter code uses `AstrRiveAnimation.asset('assets/rive/visibility_graph.riv')` to load
- State machine inputs are bound via `StateMachineController.fromArtboard(artboard, 'GraphLogic')`
- Test with varying input values to ensure smooth interpolation
- Verify `isOptimal` boolean trigger works correctly

## Creation Steps

1. Open Rive Editor (https://rive.app)
2. Create new file with artboard "VisibilityGraph"
3. Design graph elements (axes, grid, curves)
4. Create state machine "GraphLogic"
5. Add number inputs: objectAltitude (0-100), moonInterference (0-100), timeScrubber (0-100)
6. Add boolean input: isOptimal
7. Bind animations/properties to inputs
8. Test state machine with various input values
9. Export as `visibility_graph.riv`
10. Place in `assets/rive/` directory
11. Test in Flutter app

## Reference

- See existing `dashboard_bars.riv` for Rive pattern examples in this project
- See `BortleBar` widget for Flutter-Rive integration pattern
- Architecture: docs/architecture.md#Rive-Pattern
- Tech Spec: docs/sprint-artifacts/tech-spec-epic-3.md

---

**Note:** Until this asset is created, the app will display an error or fallback UI when loading the ObjectDetailScreen. Consider creating a simple placeholder graph in Rive as an interim solution.
