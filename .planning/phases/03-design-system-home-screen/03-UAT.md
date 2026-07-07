---
status: in_progress
phase: 03-design-system-home-screen
source: [03-01A-SUMMARY.md, 03-01B-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md, 03-04-SUMMARY.md, 03-05-SUMMARY.md, 03-06-SUMMARY.md]
started: 2026-07-05T00:00:00Z
updated: 2026-07-05T22:30:00Z
---

## Current Test

[session ended — UAT incomplete, phase open for continued work]

## Tests

### 1. Sky State Background
expected: The home screen shows a full-bleed illustrated background image that matches the current sky state. The image fills the entire screen behind all content. There is a gradient overlay darkening the bottom portion so text remains legible.
result: pass
fix_applied: "Reverted broken SafeArea→Stack→Positioned.fill layout to SafeArea→Column→Expanded. Background now renders correctly behind all content."

### 2. Hero Condition Label
expected: At the top of the home screen, a large display-sized (72px) condition title is visible (e.g. "Clear Skies", "Partly Cloudy"). Below it is a smaller advice subtitle. A zone badge pill is displayed below the label.
result: pass
fix_applied: "Same layout fix as test 1 — hero content now visible."

### 3. Conditions Card
expected: A glassmorphism-style card showing sun/moon rise/set times and a cloud cover bar.
result: pass
fix_applied: "Same layout fix — conditions card now visible."

### 4. Visibility Mini-Card
expected: MPSAS value, sky label, zone pill, segmented rating bar with active segments.
result: pass
fix_applied: "Same layout fix — visibility mini-card now visible."

### 5. Moon Mini-Card
expected: Moon phase illustration, illumination %, phase name in 12px text. Tapping opens detail sheet.
result: partial
notes: "Card renders and is tappable. Phase name font corrected (micro→labelMd). Detail sheet opens on tap. Visual touch-ups still needed — user not satisfied with overall appearance."

### 6. Navigation Bar — Tab Spacing
expected: Existing icon+label nav bar retained. 32px from sides, 20px between adjacent tabs in each pair.
result: partial
notes: "Spacing adjusted iteratively during session. Currently: 32px sides, 20px inner gaps. User accepted but may revisit."
fix_applied: "Replaced spaceAround with explicit SizedBox spacers. Iterated from 40/32 → 32/20 per user feedback."

### 7. HighlightsFeed Item Styling
expected: Items visible with card border, glass background, tap opens detail sheet. Empty state shows message.
result: partial
notes: "Items render and are tappable. Icon colors corrected to AppColors.accent (blue) per design system. Empty state message added. Layout acceptable but visual polish needed."
fix_applied: "Colors fixed from hardcoded orange to AppColors.accent. CelestialDetailSheet themeColor default changed from Colors.orange to AppColors.accent. Empty state added."

### 8. Overall Visual Consistency
expected: No jarring hardcoded colors. Colors, typography, spacing all cohesive.
result: issue
severity: major
notes: "User explicitly unhappy with how the phase turned out overall. Multiple color violations fixed during session (orange→blue) but overall design fidelity vs Figma still has significant gaps. More work needed."

### 9. Global Header Design
expected: Transparent header with Astr logo centered, location pill left, date nav right — matching Figma.
result: partial
notes: "Header rebuilt to transparent layout with logo centered. Logo asset path corrected (assets/icons/astr/logo.png). Duplicate location text removed from DashboardHeader. Visual polish still needed."

### 10. CelestialDetailSheet Colors
expected: Chart lines and accent colors use design system blue, not orange.
result: pass
fix_applied: "themeColor default changed from Colors.orange to AppColors.accent."

## Summary

total: 10
passed: 4
partial: 5
issues: 1
pending: 0

## Gaps — Open (Carry Forward)

- truth: "Home screen matches Figma design spec with correct layout, spacing, typography, and visual hierarchy"
  status: open
  severity: major
  reason: "User stated they are not happy with how phase 3 has turned out. Overall visual fidelity to Figma still needs significant work. Multiple rounds of touch-ups done in session but more remain."
  artifacts:
    - path: "lib/features/dashboard/presentation/home_screen.dart"
    - path: "lib/features/dashboard/presentation/widgets/moon_mini_card.dart"
    - path: "lib/features/dashboard/presentation/widgets/highlights_feed.dart"
    - path: "lib/app/router/scaffold_with_nav_bar.dart"
  missing:
    - "Systematic Figma pixel-by-pixel comparison against figma/home/Home.png"
    - "Moon mini-card visual polish"
    - "HighlightsFeed visual polish"
    - "Header layout refinements"
    - "Overall spacing audit against Figma spacing specs"

## Design Decisions (from UAT)

- **Nav bar:** Retain existing nav bar design (icon + label style). Do NOT replace with a new floating/pill style.
  Final spacing: 32px from left/right edges, 20px between adjacent tabs in each pair.
- **Color system:** All accent colors must use AppColors.accent (blue). No hardcoded Colors.orange anywhere in home screen or detail sheets.
- **Header:** Transparent, no glass blur. Logo centered (assets/icons/astr/logo.png). Location pill left, date nav right.
- **HighlightsFeed icons:** All items use AppColors.accent. Moon body gets moon_outline icon, planets get planet_outline icon.

## Session Notes (2026-07-05)

Bugs fixed in this UAT session:
1. Blank screen — layout reverted to Column+Expanded (was broken by phase 03 to Stack+Positioned.fill)
2. Moon card phase label — micro (8px) → labelMd (12px)
3. Moon card tap — GestureDetector added, static helpers fixed (were accidentally in extension)
4. HighlightsFeed empty state — added "No bright objects above the horizon right now"
5. Highlight item colors — hardcoded orange → AppColors.accent
6. CelestialDetailSheet themeColor default — Colors.orange → AppColors.accent
7. Header — rebuilt to transparent with centered logo, removed glass blur background
8. DashboardHeader — removed duplicate location name text
9. Nav bar spacing — iterated to 32px sides / 20px inner gaps
10. pubspec.yaml — added assets/favicon/ and assets/icons/astr/ asset declarations
