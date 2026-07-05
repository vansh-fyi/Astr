# Roadmap: Astr

## Overview

Astr is a brownfield Flutter stargazing conditions app being transformed from a legacy-burdened codebase into a polished, App Store-ready product. The journey runs in 9 phases: first clearing the codebase of dead code and validating zone accuracy (independent tracks that have no UI risk), then building the UI layer screen-by-screen from home outward, then fixing the two known provider staleness bugs on the freshly redesigned UI, then locking in comprehensive test coverage, and finally preparing both platform store submissions. Each phase ships a verifiable slice of working capability.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Archive & Cleanup** - Dead code, legacy backends, and obsolete pipeline scripts moved to `archive/` with documentation
- [ ] **Phase 2: Zone Data Validation** - Astr Zone calculation verified against real-world reference locations and inaccuracies resolved
- [ ] **Phase 3: Design System + Home Screen** - Design system tokens established; home screen fully redesigned per Figma spec
- [ ] **Phase 4: Objects Screen & Object Detail Sheet** - Objects catalog screen and object detail sheet redesigned and converted to sheet navigation
- [ ] **Phase 5: Bug Fixes** - Date-change and location-switch provider staleness bugs eliminated on redesigned UI
- [ ] **Phase 6: Forecast, Settings & Location Sheets** - Remaining core screens (forecast, settings) and all location management sheets redesigned
- [ ] **Phase 7: Atmospherics, Splash & Terms of Service** - Remaining surfaces (atmospherics sheet, splash screen, ToS screen, red mode overlay) redesigned
- [ ] **Phase 8: Comprehensive Testing** - Full unit, widget, and integration test suite covering all critical paths
- [ ] **Phase 9: App Store Submission** - Both Android and iOS stores prepared and submitted

## Phase Details

### Phase 1: Archive & Cleanup

**Goal**: The active codebase contains only live, working code — all dead backends, legacy screens, and obsolete pipeline scripts are isolated in `archive/` with clear documentation.
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: ARCH-01, ARCH-02, ARCH-03, ARCH-04, ARCH-05, ARCH-06
**Success Criteria** (what must be TRUE):

  1. A developer reading `archive/INDEX.md` can immediately understand what each archived subfolder contains, why it was archived, and what replaced it
  2. The MongoDB `backend/` folder, Python/Vercel API, and duplicate forecast screens are no longer in the active `lib/` tree
  3. The TIF-to-database data pipeline scripts are documented and preserved in `archive/data-pipeline/` so the methodology can be understood and rerun
  4. No dead imports or dangling references to archived code remain in the active codebase

**Plans**: 6 plans
Plans:
**Wave 1**

- [x] 01-01-PLAN.md — gitignore fixes, delete junk root files, archive backend/
- [x] 01-02-PLAN.md — archive api/, write archive/data-pipeline/README.md (full VNL pipeline guide)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-03-PLAN.md — migrate planner domain/data layer to lib/features/forecast/

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-04-PLAN.md — create forecast provider + screen, update router, clean hive_adapters, run build_runner

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01-05-PLAN.md — archive lib/features/planner/, lib/config/theme/, dead lib/common/ widgets

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 01-06-PLAN.md — create archive/INDEX.md, final flutter analyze + flutter test, human-verify checkpoint

### Phase 2: Zone Data Validation

**Goal**: The Astr Zone values returned for any geographic location are demonstrably accurate — validated against known reference data, with inaccuracies documented and resolved.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: ZONE-01, ZONE-02, ZONE-03, ZONE-04
**Success Criteria** (what must be TRUE):

  1. A diverse test set of at least 10 locations (urban, suburban, rural, multiple continents) each returns a zone value that matches the expected reference
  2. Locations that previously returned wrong zones now return correct values after the database or algorithm update
  3. Given a known input luminance, the skyglow diffusion calculation produces the expected zenith brightness output (verifiable via a test or script)
  4. Any remaining known inaccuracies are documented with expected vs. actual values so they can be tracked

**Plans**: 5 plans
Plans:
**Wave 1** *(parallel — no shared files)*

- [x] 02-01-PLAN.md — generate assets/db/zones.db + extend validate_zones_db.py with expected Astr zones + run first 25-location validation pass (ZONE-01, ZONE-02)
- [x] 02-02-PLAN.md — Dart unit tests: zone threshold boundary tests in darkness_calculator_test.dart (ZONE-04)

**Wave 2** *(blocked on 02-01 completion)*

- [x] 02-03-PLAN.md — retune apply_skyglow.py scatter params, regenerate zones_accumulator.db + zones.db, re-validate (ZONE-03)

**Wave 3** *(blocked on 02-03 completion)*

- [ ] 02-04-PLAN.md — final 25-location validation report, mismatch documentation, deploy recommendation (ZONE-01, ZONE-02)

**Wave 4** *(blocked on 02-04 completion)*

- [ ] 02-05-PLAN.md — Cloudflare D1/R2 deploy, live endpoint verification, tester cache instructions (ZONE-03, ZONE-01)

### Phase 3: Design System + Home Screen

**Goal**: Users experience the fully redesigned home screen — correct illustrated backgrounds per sky state, hero label, zone badge, conditions card, moon and visibility mini-cards, and date navigation — all built on a consistent design system with no hardcoded values.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: DS-01, DS-02, DS-03, HOME-01, HOME-02, HOME-03, HOME-04, HOME-05, HOME-06, HOME-07, HOME-08, HOME-09
**Success Criteria** (what must be TRUE):

  1. The home screen displays the correct illustrated background for each of the 6 sky states (Milkyway Visible, Starry Sky Today, Planets Visible, Few Stars Visible, Cloudy Sky Tonight, Too Much Light)
  2. The hero condition label, zone badge, conditions card (with cloud bar and sun/moon times), visibility mini-card, and moon mini-card all render with correct data and typography
  3. Tapping `<` / `>` date arrows advances the displayed date; tapping the location pill opens the Location Sheet; tapping "Explore" opens the Atmospherics Sheet
  4. All 15 surfaces use design system tokens — no hardcoded color, font size, or spacing value exists outside the token system
  5. The dark-theme starfield aesthetic is consistent across all home screen components

**Plans**: 8 plans
Plans:
**Wave 1**

- [x] 03-01A-PLAN.md — design token files (AppColors, AppTypography, AppSpacing) (DS-01, DS-03)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 03-01B-PLAN.md — SkyState enum + bortleClass → astrZone rename (DS-01)

**Wave 3** *(parallel — blocked on Wave 2 completion)*

- [x] 03-02-PLAN.md — SkyStateBackground widget + HeroConditionLabel + home_screen.dart Stack refactor (HOME-01, HOME-02, HOME-03)
- [x] 03-05-PLAN.md — HighlightsFeed restyle + ScaffoldWithNavBar token migration + GlassPanel update (HOME-07, HOME-08, DS-02)

**Wave 4** *(parallel — blocked on Wave 3 completion)*

- [x] 03-03-PLAN.md — ConditionsCard + CloudBar restyle wired into home_screen.dart (HOME-04, HOME-09)
- [x] 03-06-PLAN.md — global DS-02 token sweep: atmospherics_sheet, celestial_detail_sheet, dashboard_grid, AppTheme cleanup (DS-02)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 03-04-PLAN.md — VisibilityMiniCard + MoonMiniCard wired into home_screen.dart (HOME-05, HOME-06)

**Wave 6** *(blocked on Wave 5 + Wave 4 completion)*

- [ ] 03-07-PLAN.md — human verification checkpoint: visual + interactive verification of full home screen

### Phase 4: Objects Screen & Object Detail Sheet

**Goal**: Users can browse planets and deep sky objects from the redesigned catalog screen, and tap any object to open a draggable detail sheet — replacing the old full-screen push navigation.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: OBJ-01, OBJ-02, OBJ-03, OBJ-04, OBJD-01, OBJD-02, OBJD-03
**Success Criteria** (what must be TRUE):

  1. The objects screen lists planets and DSOs visible tonight with name, type, visibility rating, and rise/set summary for each
  2. Tapping any object opens a draggable, dismissible sheet (not a full-screen push) showing the visibility graph, transit/set times, and observing conditions rating
  3. Moon detail uses blue accent tint; planets and DSOs use orange accent tint — both use the same sheet component
  4. The objects screen matches the Figma spec provided at planning time

**Plans**: TBD
**UI hint**: yes

### Phase 5: Bug Fixes

**Goal**: All home screen providers refresh completely and correctly when the date changes or the location switches — no stale data from a previous date or location remains visible on any screen.
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: BUG-01, BUG-02, BUG-03
**Success Criteria** (what must be TRUE):

  1. Tapping `<` / `>` on home screen causes weather, astronomy, zone, sky state, moon phase, and visibility data to all update for the new date — no value from the prior date remains
  2. Switching to a saved location or searching a new one causes all providers to refresh with data for the new location — no value from the prior location persists on any screen
  3. Tapping a day on the Forecast screen navigates home and fully refreshes all home screen state for that date (end-to-end flow produces consistent data)

**Plans**: TBD

### Phase 6: Forecast, Settings & Location Sheets

**Goal**: Users can view the 7-day forecast, manage app settings, and handle all location management through properly redesigned screens and sheets — including all screen-to-sheet conversions for saved locations and add/edit flows.
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: FORE-01, FORE-02, FORE-03, FORE-04, SETT-01, SETT-02, SETT-03, LOC-01, LOC-02, LOC-03, LOC-04, LOC-05
**Success Criteria** (what must be TRUE):

  1. The forecast screen shows a 7-day list with date, sky state icon/label, cloud cover indicator, and moon phase per day; tapping a day updates the home screen for that date
  2. The settings screen contains red mode toggle, saved locations entry, ToS link, and app version; toggling red mode immediately applies the overlay across the whole app
  3. The Location Sheet lists saved locations and GPS location; tapping any switches the active context; a search entry point opens add-location flow
  4. Saved Locations, Add/Edit Location, and Confirm Delete all operate as sheets or dialogs (not full-screen pushes)
  5. Forecast and settings screens match their respective Figma specs provided at planning time

**Plans**: TBD
**UI hint**: yes

### Phase 7: Atmospherics, Splash & Terms of Service

**Goal**: All remaining surfaces — atmospherics detail sheet, splash initialization screen, terms of service screen, and the red mode overlay — are redesigned per spec and function correctly across the full app.
**Mode:** mvp
**Depends on**: Phase 6
**Requirements**: ATMO-01, SPLASH-01, TOS-01, TOS-02
**Success Criteria** (what must be TRUE):

  1. The Atmospherics Sheet shows cloud cover, seeing, transparency, humidity, and wind with the correct visual design
  2. The Splash screen shows Astr branding during the initialization sequence
  3. The Terms of Service screen is accessible from Settings (not only on first launch) and displays correctly
  4. The Red Mode Overlay applies correctly across every redesigned screen — no surface is exempt from the tint

**Plans**: TBD
**UI hint**: yes

### Phase 8: Comprehensive Testing

**Goal**: The codebase has a comprehensive test suite covering zone calculation, sky state logic, skyglow diffusion, provider refresh correctness for date and location changes, and the core end-to-end user flow.
**Mode:** mvp
**Depends on**: Phase 7
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06
**Success Criteria** (what must be TRUE):

  1. Unit tests assert correct zone output for known input luminance values and correct sky state for given zone + cloud cover + moon illumination combinations
  2. Unit tests assert skyglow diffusion output matches expected zenith brightness for known inputs
  3. Widget or integration tests confirm all home screen providers update without stale reads after a date change
  4. Widget or integration tests confirm all providers refresh after a location switch
  5. An integration test covers the full flow: app launch → view home → switch location → browse forecast → return home with updated data

**Plans**: TBD

### Phase 9: App Store Submission

**Goal**: The app is signed, screenshotted, documented, and submitted to both Google Play and Apple App Store — all policies audited, metadata written, and release pipeline established.
**Mode:** mvp
**Depends on**: Phase 8
**Requirements**: STORE-01, STORE-02, STORE-03, STORE-04, STORE-05, STORE-06, STORE-07, STORE-08, STORE-09, STORE-10
**Success Criteria** (what must be TRUE):

  1. A release AAB (Android) and Xcode archive (iOS) both build successfully from the CI pipeline without manual signing steps
  2. All required store screenshots are captured for every required device size on both platforms
  3. The privacy policy is published and linked in both store listings, covering GPS use, background sync, and Cloudflare data handling
  4. Both stores' policy audits pass with no known rejection-risk items (entitlements, permissions, background location declarations, target SDK)
  5. App name, description, keywords, category, content rating, and app version are finalized and submitted in both store consoles

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Archive & Cleanup | 5/6 | In Progress|  |
| 2. Zone Data Validation | 3/5 | In Progress|  |
| 3. Design System + Home Screen | 2/8 | In Progress|  |
| 4. Objects Screen & Object Detail Sheet | 0/TBD | Not started | - |
| 5. Bug Fixes | 0/TBD | Not started | - |
| 6. Forecast, Settings & Location Sheets | 0/TBD | Not started | - |
| 7. Atmospherics, Splash & Terms of Service | 0/TBD | Not started | - |
| 8. Comprehensive Testing | 0/TBD | Not started | - |
| 9. App Store Submission | 0/TBD | Not started | - |
