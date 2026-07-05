# Phase 3: Design System + Home Screen - Context

**Gathered:** 2026-07-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish a design token system in `lib/core/design/` and apply tokens globally across all 15 surfaces. Build the fully redesigned home screen per Figma exports: correct illustrated JPG background per sky state, hero condition label, zone badge, conditions card (cloud bar + sun/moon times), visibility mini-card, moon mini-card, date navigation, location pill, and explore button. The nav shell (glass header + 4-tab nav + centered map FAB) is already structurally complete — Phase 3 restyled it using design tokens. Phase ends with the home screen matching the Figma spec and zero hardcoded colors/font sizes/spacing values in any active surface.

</domain>

<decisions>
## Implementation Decisions

### Illustrated Backgrounds
- **D-01:** All 6 sky state backgrounds are **static JPG assets** — no Rive or Lottie animation. One image per sky state.
- **D-02:** Asset paths are confirmed and ready:
  - `assets/img/milky_way.jpg` → Milkyway Visible
  - `assets/img/starry_sky.jpg` → Starry Sky Today
  - `assets/img/planets.jpg` → Planets Visible
  - `assets/img/few_stars.jpg` → Few Stars Visible
  - `assets/img/cloudy.jpg` → Cloudy Sky Tonight
  - `assets/img/excessive_light_pollution.jpg` → Too Much Light
- **D-03:** Background layer approach is **full replacement** — `nebula_background.dart` and `sky_portal.dart` are deleted. New implementation: full-bleed image fill with a dark gradient overlay for legibility, per Figma spec.

### Home Screen Rebuild
- **D-04:** Strategy is **in-place refactor** — keep `home_screen.dart` structure, preserving existing provider wiring and state logic (date nav bounds, launch result handling, `_bannerController`, `_hasHandledLaunchToast`, `_hasHandledLaunchLocation`). Reshape widget tree to match Figma.
- **D-05:** All existing dashboard widgets are **refactored individually** — no deletions. Every widget in `lib/features/dashboard/presentation/widgets/` gets updated to match Figma. Widgets that no longer have a Figma counterpart (e.g. `sky_portal.dart`, `nebula_background.dart`) are replaced with the new background implementation.
- **D-06:** Design reference: Figma exports are placed in `figma/home/` before executor starts. Executor reads images from that folder. Also consult REQUIREMENTS.md HOME-01 through HOME-09 for behavioral spec.

### Design Token System
- **D-07:** Tokens live in a **new `lib/core/design/` directory**. `AppTheme` continues as the `ThemeData` factory; token definitions move to `lib/core/design/` (e.g. `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, or a unified `design_tokens.dart`).
- **D-07a:** The **color primitive palette is locked** — defined in `assets/design/color_system.csv`. The design system uses ONLY these values; no new hex colors are invented. Two families: **Blue** (9 stops: 100–900) and **Grey** (9 stops: 100–900), each with 6 opacity variants (10%, 20%, 30%, 50%, 80%, 100%). Flutter Color values are pre-computed in the CSV (`0xAARRGGBB` column) — use them directly. Key anchors:
  - Surface/background: Grey/900 `#0C0F11` (near-OLED-black), Grey/800 `#181D23`
  - Primary accent: Blue/500 `#448AFF`, Blue/400 `#3A96FF`
  - Text primary: Grey/100 `#F4F5F5`, Grey/200 `#DDDFE2`
  - Text secondary: Grey/400 `#7D8792`, Grey/300 `#B3B7BC`
  - Glass overlays: Grey/900 at 50–80% opacity, or Blue/900 at 50–80% opacity
- **D-08:** DS-02 is enforced **globally in Phase 3** — apply tokens across all 15 active surfaces now. Every hardcoded `Color`, `fontSize`, and spacing value in the active codebase (`lib/`) is replaced with a token reference. Other screens aren't redesigned visually, but their hardcoded values are migrated.
- **D-09:** **Rename `ZoneData.bortleClass` → `ZoneData.astrZone`** in Phase 3. Update all references throughout `lib/` (display code, providers, models). The field represents Astr zone (1–9), not Bortle — the naming debt acknowledged in Phase 2 is resolved here.

### Component Interactions
- **D-13:** The **Explore button** on the conditions card opens `AtmosphericsSheet`. The cloud cover container/bar itself has no tap handler — it is display only.
- **D-14:** The **Visibility mini-card** ("Rural Sky") gets a new visual design in Phase 3 and is display-only — it no longer opens the Atmospherics Sheet. No tap handler.
- **D-15:** The **HighlightsFeed** ("Tonight's Highlights" / best viewed objects) is included in the Phase 3 redesign — all rows restyled to match the new design system. Tap behavior is unchanged (opens `CelestialDetailSheet`).
- **D-16:** All other sheets (`AtmosphericsSheet`, `CelestialDetailSheet`, `LocationSheet`) keep their existing implementation and open behavior.

### Navigation Bar
- **D-10:** The nav bar structure is **already complete** — 4 tabs (Home, Objects, Forecast, Settings) + centered map FAB with notch clipper. FAB already shows "Sky Map coming soon!" toast on tap. No structural changes needed.
- **D-11:** The global glass header (location pill + date navigation) in `scaffold_with_nav_bar.dart` **stays as a global header** — visible on all tabs. Phase 3 restyled it with design tokens but does not change its scope or position.
- **D-12:** Phase 3 applies design token restyling to `scaffold_with_nav_bar.dart` — replacing hardcoded colors (`Colors.blueAccent`, `AppTheme.deepCosmos`, `Colors.white.withOpacity(...)`) with token references.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §UI Design System — DS-01, DS-02, DS-03 are the design system requirements. DS-02 scope is global (all 15 surfaces).
- `.planning/REQUIREMENTS.md` §Home Screen — HOME-01 through HOME-09 define all home screen behaviors. These are the behavioral acceptance criteria.
- `.planning/ROADMAP.md` §Phase 3 — Success criteria: correct backgrounds per state, all components render with correct data/typography, interactivity wired, all surfaces use tokens, dark starfield aesthetic consistent.

### Project Context
- `.planning/PROJECT.md` §6 Sky States — Lists the 6 states in order (best → worst) with their visual descriptions.
- `.planning/PROJECT.md` §Surfaces to Redesign — Lists all 15 surfaces; Phase 3 redesigns only the home screen but migrates tokens across all.
- `.planning/PROJECT.md` §Design — Figma design description: "full-bleed illustrated background, large hero sky condition label, Zone badge, conditions card with cloud cover bar + sun/moon times, visibility + moon mini-cards, 5-tab nav with centered map FAB."
- `.planning/PROJECT.md` §Constraints — Dark theme only, OLED black, portrait-only, FlexColorScheme, Satoshi font, Riverpod, GoRouter.

### Design Reference (Figma exports)
- `figma/home/` — **PRIMARY design reference for Phase 3.** Figma exports will be placed here before executor starts. Executor reads these images to implement exact layout, spacing, typography, and visual hierarchy. Folder exists but may be empty until user adds images — check before planning.

### Color System (locked primitive palette)
- `assets/design/color_system.csv` — **LOCKED color primitives.** Two families (Blue, Grey), 9 stops each (100–900), 6 opacity variants per stop. Flutter Color column (`0xAARRGGBB`) is pre-computed — use these values directly in `lib/core/design/app_colors.dart`. No hex values outside this file. Format: `Token Name, Color Family, Stop, Opacity %, R, G, B, Base Hex, Alpha, Flutter Color, CSS rgba()`.

### Existing Theme & Design Files
- `lib/app/theme/app_theme.dart` — Current theme factory. Existing color constants (`deepCosmos`, `oledBlack`, `starlight`, `accentPurple`, `accentCyan`) and glassmorphism constants will migrate to `lib/core/design/`.
- `lib/app/router/scaffold_with_nav_bar.dart` — Nav shell: global glass header (location pill + date nav), 4-tab nav bar, centered map FAB, notch clipper, loading overlay. Phase 3 restyled with tokens.

### Existing Home Screen Code
- `lib/features/dashboard/presentation/home_screen.dart` — 343-line home screen. Contains: provider watching (weather, astronomy, astrContext, conditionQuality, visibility), date nav bounds logic, launch result handling, banner controller. Preserve this business logic during refactor.
- `lib/features/dashboard/presentation/widgets/` — All existing widgets refactored in-place:
  - `nebula_background.dart`, `sky_portal.dart` → replaced by new full-bleed background widget
  - `moon_phase_card.dart`, `cloud_bar.dart`, `atmospherics_sheet.dart`, `celestial_detail_sheet.dart` → refactored to match Figma
  - `dashboard_header.dart`, `dashboard_grid.dart`, `highlights_feed.dart` → reshaped to new layout
- `lib/features/data_layer/models/zone_data.dart` — `bortleClass` field renamed to `astrZone` in Phase 3. Find all references before changing.

### Zone Data Model
- `lib/features/data_layer/services/remote_zone_service.dart` — Reads `bortleClass` from Cloudflare response. After rename, field mapping must still parse correctly from the JSON key (the API response key name may differ from the Dart field name — verify before renaming).
- Phase 2 context note (from `02-CONTEXT.md`): "`bortleClass` in code refers to Astr zone (1–9), not Bortle. This is a naming debt acknowledged but NOT fixed in Phase 2." → Fixed in Phase 3.

### Codebase Maps
- `.planning/codebase/ARCHITECTURE.md` — Component responsibilities and data flow.
- `.planning/codebase/STRUCTURE.md` — Directory layout; where to add new `lib/core/design/` files.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/widgets/glass_panel.dart` — `GlassPanel` widget used in nav shell for pills. Reuse for conditions card glass styling if Figma calls for glassmorphism.
- `lib/core/widgets/glass_toast.dart` — `showGlassToast()` — already used for "Sky Map coming soon!" and date bound toasts. Keep as-is.
- `lib/features/dashboard/presentation/widgets/cloud_bar.dart` — Cloud cover progress bar. Refactor visual styling; data binding stays.
- `lib/features/dashboard/presentation/widgets/moon_phase_card.dart` — Moon phase data + illustration. Refactor visual layer.
- `lib/features/dashboard/presentation/widgets/atmospherics_sheet.dart` — Explore sheet (HOME-09). Refactor visual; sheet trigger stays in home screen.
- `lib/features/context/presentation/widgets/location_sheet.dart` — Location sheet (HOME-08). Already wired in nav shell header. No change to trigger.

### Established Patterns
- **Riverpod provider watching:** Home screen uses `ref.watch(weatherProvider)`, `ref.watch(astronomyProvider)`, `ref.watch(astrContextProvider)`, `ref.watch(conditionQualityProvider)`, `ref.watch(visibilityProvider)`. All must continue to work after refactor.
- **Token reference style:** After tokens are defined in `lib/core/design/`, access via static getter (e.g. `AppColors.surface`, `AppSpacing.md`). Import `package:astr/core/design/...`.
- **Dark theme only:** All new widgets use `ThemeMode.dark` colors from token system. No light mode variants needed.
- **Glass header structure:** Location pill + date nav are in `ScaffoldWithNavBar`, not `HomeScreen`. HOME-07 (date nav) and HOME-08 (location pill) are handled there, not in home_screen.dart.
- **Sky state → background mapping:** Implement as a `switch` or `Map<SkyState, String>` returning the asset path. Sky state enum/value comes from `conditionQualityProvider` or equivalent.

### Integration Points
- `lib/core/design/` → imported by any widget that references a token; replaces `AppTheme.*` color/spacing references across 15 surfaces.
- `ZoneData.astrZone` rename → verify JSON deserialization: the Cloudflare Worker JSON key may be `bortleClass` — use `@JsonKey(name: 'bortleClass')` if needed to preserve API compatibility.
- Background widget → receives `SkyState` (or sky state enum value) as parameter; returns full-bleed `Image.asset()` with gradient overlay.

</code_context>

<specifics>
## Specific Ideas

- Figma exports will be provided in `figma/home/` before Phase 3 execution starts. Executor should check this folder first — it is the authoritative visual reference for layout, spacing, and component design.
- The nav bar notch + FAB is already complete and well-implemented (custom `NavBarClipper`, `NotchShinePainter`, `FloatingActionButton` at `centerDocked`). Phase 3 only restyled the colors with tokens — do not restructure the nav shell.
- The global glass header (location pill + date nav) is intentionally global (visible on all 4 tabs). This is confirmed as correct behavior — do not move it into home screen only.
- `bortleClass` → `astrZone` rename: check `cloudflare/worker.js` response format to confirm the JSON key name before updating the Dart `@JsonKey` annotation.

### Home Screen Design Specs (from Figma node 119:80)

> Extracted directly from Figma. These are exact values — use them verbatim. All colors reference `assets/design/color_system.csv` tokens.

**Reusable glow shadow (used on active bars, FAB, cloud fill):**
```
BoxShadow: [
  BoxShadow(color: Color(0x40FFFFFF), blurRadius: 1, offset: Offset(0, 0)),
  BoxShadow(color: Color(0xFF3A7FFF), blurRadius: 12.2, offset: Offset(0, 1)),
]
```

**Screen background:**
- Base fill: `Grey/900/100` → `#0C0F11` (`0xFF0C0F11`)
- Background image: full-bleed JPG at **50% opacity**
- Backdrop gradient overlay: `Blue/500` → transparent black, at **20% opacity** (subtle tint)

**Header pills (Location, Date, Prev/Next buttons):**
- Background: `Grey/900/80` → `rgba(12,15,17,0.8)` (`0xCC0C0F11`)
- Border: `Grey/600/100` → `#303A46` (`0xFF303A46`), 1px
- Border radius: **17px**
- Height: **28px**
- Text: Satoshi Regular, **10px**, `Grey/300/100` → `#B3B7BC` (`0xFFB3B7BC`)
- Prev/Next icon size: 12×12px inside 28×28px container

**Logo:** 35×35px, centered in header row, top: 40px

**Hero label ("Excellent"):**
- Font: Satoshi Bold, **72px**
- Color: `Grey/100/100` → `#F4F5F5` (`0xFFF4F5F5`)
- Alignment: center

**Sky state subtitle ("Milkyway Visible"):**
- Font: Satoshi Regular, **15px**
- Color: `Grey/100/100` → `#F4F5F5`
- Alignment: center

**Hero zone badge ("Zone 1"):**
- Background: `Grey/900/50` → `rgba(12,15,17,0.5)` (`0x800C0F11`)
- Border: `Blue/800/100` → `#1B3766` (`0xFF1B3766`), 1px
- Border radius: **70px** (pill)
- Padding: 8px vertical, 16px horizontal
- Text: Satoshi Bold, **12px**, `Grey/100/100` → `#F4F5F5`

**Conditions card (Weather Info Container):**
- Size: 345×242px
- Background: `Grey/900/50` → `rgba(12,15,17,0.5)` (`0x800C0F11`)
- Border: `Blue/800/100` → `#1B3766` (`0xFF1B3766`), 1px
- Border radius: **16px**
- Backdrop blur: **2px**
- "Clear Skies" title: Satoshi Medium, **16px**, `Grey/100/100`, left+top padding 17px
- Subtitle: Satoshi Regular, **10px**, `Grey/300/100` → `#B3B7BC`, centered, 43px from top

- **Explore button:**
  - Size: 100×27px
  - Background: `Blue/500/100` → `#448AFF` (`0xFF448AFF`)
  - Border radius: **8px**
  - Text: Satoshi Medium, **12px**, `Grey/100/100`
  - Positioned: top-right of card (top: 12px, right: 13px)

- **Cloud Cover inner container:**
  - Size: 312×84px
  - Background: `Grey/900/80` → `rgba(12,15,17,0.8)` (`0xCC0C0F11`)
  - Border: `Blue/900/100` → `#0C1E33` (`0xFF0C1E33`), 1px
  - Border radius: **12px**
  - Label: Satoshi Medium, **12px**, `Grey/100/100`, top: 20px, left: 18px
  - No tap action (display only)

- **Cloud cover track:** height **8px**, `Grey/500/30` → `rgba(60,73,87,0.3)`, radius **12px**
- **Cloud cover fill:** height **8px**, `Blue/400/100` → `#3A96FF` (`0xFF3A96FF`), radius **12px**, + glow shadow

- **Sun/Moon time cells (Sunrise, Sunset, Moonrise, Moonset):** each 72×64px
  - Background: `Grey/900/80` → `rgba(12,15,17,0.8)` (`0xCC0C0F11`)
  - Border: `Blue/900/100` → `#0C1E33`, 1px
  - Border radius: **12px**
  - Label: Satoshi Medium, **8px**, `Grey/300/100` → `#B3B7BC`, top: 12px, centered
  - Value: Satoshi Medium, **12px**, `Grey/100/100`, top: 31px, centered

**Visibility mini-card:**
- Size: 164×154px
- Background: `Grey/900/50` → `rgba(12,15,17,0.5)` (`0x800C0F11`)
- Border: `Blue/800/100` → `#1B3766`, 1px
- Border radius: **16px**
- Backdrop blur: **2px**
- "VISIBILITY" label: Satoshi Medium, **10px**, `Grey/300/100`, top: 15px, left: 15px
- "Rural Sky" text: Satoshi Medium, **28px**, `Grey/100/100`, top: 50px
- MPSAS value: Satoshi Medium, **10px**, `Grey/300/100`
- **Zone pill** (top-right, inside card):
  - Background: `Blue/400/20` → `rgba(58,150,255,0.2)` (`0x333A96FF`)
  - Border: `Blue/500/100` → `#448AFF`, 1px
  - Border radius: **70px** (pill)
  - Padding: 4px vertical, 11px horizontal
  - Text: Satoshi Bold, **8px**, `Blue/100/100` → `#B0D5FF` (`0xFFB0D5FF`)
- **Rating bars** (5 bars, horizontal, gap: 5px, total width: 132px, height: 5px each):
  - Active: `Blue/400/100` → `#3A96FF`, border same, radius **12px**, + glow shadow
  - Inactive: `Grey/500/30` → `rgba(60,73,87,0.3)`, radius **12px**

**Moon mini-card:**
- Size: 164×154px
- Background: `Grey/900/50` → `rgba(12,15,17,0.5)` (`0x800C0F11`)
- Border: `Blue/800/100` → `#1B3766`, 1px
- Border radius: **16px**
- Backdrop blur: **2px**
- "MOON" label: Satoshi Medium, **10px**, `Grey/300/100`, top: 15px, left: 15px
- Illumination %: Satoshi Medium, **10px**, `Grey/100/100`, top: 15px, right-aligned
- Moon image: 98×92px, centered
- Phase name: Satoshi Medium, **8px**, `Grey/100/100`, bottom-centered (top: 126px)

**Nav bar:**
- Size: 353×64px, left: 20px from screen edge
- Backdrop blur: **2px**
- Custom notch shape (existing `NavBarClipper` — keep as-is)
- Tab labels: Inter Regular, **8px**, `Grey/100/100`
- Tab icon size: **24×24px**, gap to label: **4px**
- **Map FAB:**
  - Size: **52×52px**, border radius: **32px**
  - Background: `Blue/500/100` → `#448AFF`
  - Border: `Blue/400/100` → `#3A96FF`, 1px
  - + glow shadow (same as above)
  - Icon: 32×32px inside
  - Position: centered, **27px above** nav bar top edge

### Home Screen Layout (from figma/home/Home.png)

**Global header (ScaffoldWithNavBar — not HomeScreen):**
- Left: location icon + "Current Location" pill (glass)
- Center: Astr "A" logo mark
- Right: `<` chevron · date pill ("Jun 2") · `>` chevron (glass pills)

**Hero section (full-bleed background image):**
- Hero condition label: "Excellent" — very large, heavy weight (Satoshi Black or ExtraBold), white, centered
- Sky state subtitle: "Milkyway Visible" — smaller, lighter weight, centered, below hero label
- Zone badge: "Zone 1" — blue pill/chip, centered, below subtitle

**Conditions card (glass card, overlaps bottom of hero):**
- Header row: "Clear Skies" bold label (left) + "Explore" blue filled pill button (right)
- Subtitle: "Perfect visibility for observation" — small, grey/muted, below header row
- Cloud Cover row: "Cloud Cover" label + blue progress bar (fills based on cloud percentage — low cloud = more filled)
- 4-column sun/moon times grid: SUNRISE · SUNSET · MOONRISE · MOONSET — each uppercase label with value below

**Bottom mini-cards row (above nav bar):**
- VISIBILITY card (left half): "Zone 1" blue badge (top) + "Rural Sky" large text (bottom)
- MOON card (right half): "65%" label + moon phase illustration + "MOON" uppercase label

**Navigation bar (already implemented):**
- Tabs: Home · Objects · [centered blue circular FAB with map icon] · Forecast · Settings
- Active tab: filled icon + white; inactive: outline icon + white at 50% opacity
- FAB: blue circle, notch cutout in nav bar, "Sky Map coming soon!" toast on tap

**"Tonight's Highlights" / Best Viewed Objects section (below mini-cards):**
- `HighlightsFeed` widget — shows top 3 celestial objects with best viewing time
- Section label: "TONIGHT'S HIGHLIGHTS" — uppercase, small, muted
- Each row: icon box (orange tint) + object name + "Best view: HH:mm" + quality label + chevron
- Tap on a row → opens `CelestialDetailSheet` (unchanged behavior)
- **Must be restyled** to match the new design system (glass cards, token colors, Figma style)

**Interaction rules (clarified):**
- **Explore button** (conditions card top-right) → opens `AtmosphericsSheet` ✓
- **Cloud cover container / progress bar** → display only, no tap action
- **Visibility card** ("Rural Sky") → new visual design per Phase 3; does NOT open atmospherics sheet (display only)
- **Moon card** → unchanged behavior
- **Highlights row** → opens `CelestialDetailSheet` (unchanged)
- **All other sheets** → function exactly as currently implemented

**Visual style notes:**
- Background: full-bleed JPG, image fills entire screen behind all content
- Cards: dark glass (near-black with slight transparency + blur)
- Accent color: Blue/500 `#448AFF` — used for Explore button, zone badge, cloud bar fill, FAB
- Text primary: white / Grey/100
- Text secondary / labels: Grey/400 muted — used for subtitles, column labels (SUNRISE, MOON, etc.)
- Zone badge and Explore button share the same blue accent
- Overall: dark, immersive, space-themed — content floats over the illustrated sky background

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 3-Design System + Home Screen*
*Context gathered: 2026-07-04*
