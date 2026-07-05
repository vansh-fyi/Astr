# Astr

## What This Is

Astr is a Flutter stargazing conditions app for iOS and Android. It tells you exactly how good your current location is for observing the night sky tonight — and lets you explore any location in the world. It uses a custom Astr Zone system (based on light pollution Zenith Brightness data with skyglow diffusion) combined with live weather data to calculate one of 6 sky states, each with a distinct illustrated background. Beyond conditions, it shows astronomical data: moon phase, visible planets, and deep sky objects from a bundled SQLite catalog.

## Core Value

Know instantly whether tonight's sky is worth going outside — and if not, know why.

## Requirements

### Validated

- ✓ Astr Zone calculation from VNL NPP 2024 light pollution data with H3 geospatial indexing — existing
- ✓ Skyglow diffusion applied to raw light pollution values for accurate zenith brightness — existing
- ✓ 6 sky states derived from zone + cloud cover + moon + atmospheric conditions — existing
- ✓ GPS-based current location with fallback to saved locations — existing
- ✓ Live weather data from Open-Meteo (cloud cover, humidity, wind, seeing) — existing
- ✓ Zone data served via Cloudflare Workers + R2/D1, cached locally in Hive — existing
- ✓ Multi-day forecast (7-day) with per-day sky state — existing
- ✓ Astronomical calculations via Swiss Ephemeris (sweph): moon phase, rise/set/transit times — existing
- ✓ Celestial object catalog (planets + DSOs) via bundled SQLite DB — existing
- ✓ Visibility graph per object (altitude over time) — existing
- ✓ Background sync via WorkManager (Android) / BGTaskScheduler (iOS) — existing
- ✓ Red Mode overlay for night vision preservation — existing
- ✓ Location search and saved locations management — existing
- ✓ English + Turkish localization — existing

### Active

- [ ] Archive dead/legacy code into `archive/` with documented references
- [ ] Full UI redesign across all 15 surfaces following Astr design system (Figma specs provided per screen)
- [ ] 6 illustrated background states wired to correct sky state logic
- [ ] All screens/flows converted to sheets where specified
- [ ] Fix future-date state bug (some providers don't fully update when date changes)
- [ ] Fix location-switch staleness bug (some providers retain data from previous location)
- [ ] Comprehensive test suite: unit + widget + integration
- [ ] Google Play Store submission readiness
- [ ] Apple App Store submission readiness

### Out of Scope

- Real-time chat or social features — not a community app
- MongoDB backend — dead, being archived
- Python/Vercel backend (`backend/`) — dead, being archived
- Web platform target — mobile-first; web is incidental
- Video content — not relevant to the domain

## Context

**Codebase state:** Flutter app with Riverpod + GoRouter + Clean Architecture (feature-first). The app went through multiple ideation cycles before settling on the current Cloudflare + Open-Meteo architecture. This left significant dead code including a MongoDB backend (`backend/`), a Python/Vercel API, duplicate forecast screens, and orphaned features. The active data path is: zone data from Cloudflare Worker → cached in Hive CE → weather from Open-Meteo → combined by domain services → displayed via Riverpod providers.

**Design:** The home screen design is finalized (Figma). It features a full-bleed illustrated background (one of 6 scenes), a large hero sky condition label ("Excellent", "Good", etc.), Zone badge, conditions card with cloud cover bar + sun/moon times, visibility + moon mini-cards, and a 5-tab nav with a centered map FAB. Designs for other screens will be provided per screen during the UI phase.

**Zone system:** Custom Astr Zones derived from Zenith Brightness (inspired by David Lorenz's work at djlorenz.github.io/astronomy/lp/). Light pollution source: VNL NPP 2024 Global Masked Data TIF with diffusion applied for skyglow. Zone formulas and sky state logic are implemented in the codebase.

**6 Sky States (best → worst):**
1. Milkyway Visible — Rural cabin under clear dark sky with shooting stars
2. Starry Sky Today — Bird silhouette against partially cloudy starry sky
3. Planets Visible — City skyline with bright planets prominent
4. Few Stars Visible — Hilltop view with light pollution glow, sparse stars
5. Cloudy Sky Tonight — Dark overcast clouds over city
6. Too Much Light — Urban park with street lamp, minimal stars

**Known bugs:**
- Future date navigation: tapping `<`/`>` date arrows on home screen updates some providers but not all — moon phase, zone, and astronomical data can remain stale from the current date
- Location switch: switching to a saved location or searching a new one leaves residual data from the previous location in some providers

## Constraints

- **Tech Stack**: Flutter (Dart) — no platform change
- **State Management**: Riverpod — established pattern, not changing
- **Navigation**: GoRouter — stay with declarative routing
- **Zone data**: Cloudflare Workers + R2/D1 — active production infrastructure
- **Weather**: Open-Meteo — free, accurate, no key required
- **Design**: Figma specs provided per screen — implement exactly as designed
- **App Store**: Must meet both Google Play and Apple App Store submission requirements
- **Night Vision**: Red Mode overlay must be preserved — core to astronomy use case

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Archive dead code into `archive/` folder with references | Codebase has significant legacy from ideation cycles; clean separation before redesign prevents confusion | — Pending |
| Convert Object Detail, Saved Locations, Add/Edit Location from screens to sheets | Keeps user in context, consistent with app's modal-first interaction pattern | — Pending |
| Single `CelestialDetailSheet` with `themeColor` parameter for moon (blue) and planets (orange) | Reuse same component, differentiate by accent color | ✓ Good — already implemented |
| Cloudflare edge + Hive local cache for zone data | Eliminated MongoDB backend dependency; edge serving is faster and cheaper | ✓ Good |
| Swiss Ephemeris (sweph) for astronomical calculations | Industry-standard accuracy for rise/set/transit/moon phase | ✓ Good |

## Surfaces to Redesign (15 total)

### Main Screens (4)
1. **Home** — hero condition + zone + illustrated background + conditions card + moon/visibility cards
2. **Objects (Catalog)** — planets + DSOs list with visibility ratings
3. **Forecast** — 7-day sky state forecast
4. **Settings** — red mode toggle, locations, app info, ToS link

### Full Screens (2)
5. **Splash / Init** — loading sequence
6. **Terms of Service** — accessible from Settings AND shown on first launch

### Bottom Sheets — existing (4)
7. **Location Sheet** — switch location, search, access saved locations
8. **Atmospherics Sheet** — detailed weather breakdown
9. **Celestial Detail Sheet (Moon)** — moon detail in blue tints
10. **Celestial Detail Sheet (Planet/Object)** — object detail in orange tints

### Bottom Sheets — converted from screens (3)
11. **Object Detail Sheet** — was a full screen push, becomes a sheet
12. **Saved Locations Sheet** — was a full screen push, becomes a sheet
13. **Add / Edit Location Sheet** — was a full screen push, becomes a sheet

### Dialogs (1)
14. **Confirm Delete Dialog** — delete location confirmation

### Global Overlays (1)
15. **Red Mode Overlay** — full-app red tint for night vision

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-13 after initialization*
