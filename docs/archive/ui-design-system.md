# UI Design System - Astr

> **Purpose:** Document current UI component designs to prevent workflow regressions.  
> **Status:** Approved  
> **Last Updated:** 2025-11-30

## Core Principle

**UI changes require explicit Acceptance Criteria approval.** Workflows must NOT modify component aesthetics (colors, padding, layout) unless story AC explicitly defines the change.

---

## Components

### 1. Visibility Bar (BortleBar)

**Current Design (AS-IS):**
- **Height:** 140px (matches Moon card)
- **Layout:**
  - **Top:** "VISIBILITY" label (small, grey text)
  - **Center:** Zone badge (e.g., "Zone 4" in glowy blue pill)
  - **Below badge:** Classification text (e.g., "Rural" in large white text)
  - **Bottom:** MPSAS value display
  - **Bottom:** 5-segment horizontal scale (blue gradient) showing active segment
- **Container:** `GlassPanel` (dark glass: `Color(0xFF121212).withAlpha(0.8)`)
- **Interaction:** `onTap` → opens `AtmosphericsSheet`

**DO NOT:**
- Change to 1-9 Rive animation
- Modify segment count (must remain 5)
- Alter zone badge styling (blue glow preserved)

### 2. Cloud Bar (CloudBar)

**Current Design (AS-IS):**
- **Layout:** Blue → Blue Accent gradient fill based on cloud %
- **Container:** `GlassPanel` (dark glass)
- **Label:** "Cloud Cover" with percentage display

**DO NOT:**
- Change gradient colors (Blue theme mandatory)

### 3. Glass Panel (GlassPanel)

**Current Design (AS-IS):**
- **Background:** `Color(0xFF121212).withAlpha(0.8)`
- **Blur:** Backdrop filter (20px)
- **Border:** 1px white (10% opacity)
- **Padding:** 16px default
- **Border Radius:** 16px

**Parameters:** `child`, `padding` only — NO custom `color`, `blur`, `borderColor` parameters

### 4. General Styling

- **Background:** `Color(0xFF020204)` (Deep Cosmos)
- **Text Colors:** White primary, white70 secondary
- **Accents:** Blue (`Colors.blue`) for active elements
- **Icons:** White default

---

## Enforcement

1. **Story ACs must explicitly define UI changes** (e.g., "AC: Visibility bar uses 7-segment scale")
2. **Workflows preserve existing UI** unless AC mandates change
3. **DoD includes:** "Existing UI styling preserved per `ui-design-system.md`"
