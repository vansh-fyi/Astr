# Requirements: Astr

**Defined:** 2026-06-13
**Core Value:** Know instantly whether tonight's sky is worth going outside — and if not, know why.

## v1 Requirements

### Archive & Cleanup

- [ ] **ARCH-01**: Comprehensive dead code audit across the entire codebase identifies all unused features, providers, widgets, screens, and backend code
- [ ] **ARCH-02**: MongoDB backend (`backend/` folder — Flask API, pymongo, requirements.txt) is moved into `archive/backend/` with a README explaining what it was and why it was replaced
- [ ] **ARCH-03**: Duplicate and unused forecast screens (`features/forecast/presentation/forecast_screen.dart`, `features/planner/presentation/screens/forecast_screen.dart`) are archived with reference documentation
- [ ] **ARCH-04**: Skyglow diffusion data processing pipeline (TIF → database generation scripts) is archived in `archive/data-pipeline/` with full documentation of the methodology, inputs, and outputs so it can be referenced or rerun in future
- [ ] **ARCH-05**: All other dead features, providers, widgets, and services identified in the audit are archived with per-folder README references
- [ ] **ARCH-06**: `archive/` root contains an index document mapping each subfolder to what it contains, why it was archived, and what replaced it

### Zone Data Accuracy

- [x] **ZONE-01**: Zone calculation is validated against known reference data for a diverse set of geographic locations (urban, suburban, rural, across multiple continents)
- [x] **ZONE-02**: Locations where zone output is inaccurate or unexpected are documented with expected vs. actual values
- [x] **ZONE-03**: Zone database and/or skyglow diffusion algorithm is updated to resolve identified inaccuracies
- [ ] **ZONE-04**: Skyglow diffusion results are verifiable: given a known input luminance, the diffusion output matches expected zenith brightness values

### UI Design System

- [x] **DS-01**: Astr design system is defined and implemented: color tokens, typography scale, spacing system, component library (cards, sheets, pills, buttons, icons)
- [ ] **DS-02**: All 15 surfaces use design system tokens — no hardcoded colors, font sizes, or spacing values outside the system
- [x] **DS-03**: Dark theme is the only theme; all components are designed for near-black backgrounds with the starfield aesthetic

### Home Screen

- [ ] **HOME-01**: Home screen displays the correct illustrated background for the current sky state (one of 6 states: Milkyway Visible, Starry Sky Today, Planets Visible, Few Stars Visible, Cloudy Sky Tonight, Too Much Light)
- [ ] **HOME-02**: Hero sky condition label ("Excellent", "Good", etc.) is displayed prominently with correct typography
- [ ] **HOME-03**: Astr Zone badge is displayed beneath the condition label
- [ ] **HOME-04**: Conditions card shows: overall assessment label, cloud cover progress bar, Sunrise / Sunset / Moonrise / Moonset times
- [ ] **HOME-05**: Visibility mini-card shows zone number and sky type label ("Rural Sky", "Suburban Sky", etc.)
- [ ] **HOME-06**: Moon mini-card shows moon phase percentage and moon phase illustration
- [ ] **HOME-07**: Date navigation arrows (`<` / `>`) allow browsing future/past dates; tapping a date fully refreshes all home screen data for that date
- [ ] **HOME-08**: "Current Location" pill taps open the Location Sheet
- [ ] **HOME-09**: "Explore" button on conditions card opens the Atmospherics Sheet

### Objects Screen

- [ ] **OBJ-01**: Objects screen lists planets and deep sky objects visible from the current location tonight
- [ ] **OBJ-02**: Each object shows name, type, visibility rating, and rise/set summary
- [ ] **OBJ-03**: Tapping an object opens the Object Detail Sheet (not a full-screen push)
- [ ] **OBJ-04**: Objects screen is redesigned per Figma spec (provided when this phase is planned)

### Object Detail Sheet

- [ ] **OBJD-01**: Object Detail Sheet (converted from full screen) shows object name, type, altitude-over-time visibility graph, transit and set times, observing conditions rating
- [ ] **OBJD-02**: Moon uses blue accent tint; planets and DSOs use orange accent tint
- [ ] **OBJD-03**: Sheet is draggable and dismissible

### Forecast Screen

- [ ] **FORE-01**: Forecast screen shows 7-day sky state forecast for the current location
- [ ] **FORE-02**: Each day row shows date, sky state icon/label, cloud cover indicator, and moon phase
- [ ] **FORE-03**: Tapping a day on the forecast screen navigates home screen to that date and fully refreshes all home screen data
- [ ] **FORE-04**: Forecast screen is redesigned per Figma spec (provided when this phase is planned)

### Settings Screen

- [ ] **SETT-01**: Settings screen contains: Red Mode toggle, Saved Locations entry point, Terms of Service link, app version info
- [ ] **SETT-02**: Red Mode toggle immediately applies/removes the red overlay across the entire app
- [ ] **SETT-03**: Settings screen is redesigned per Figma spec (provided when this phase is planned)

### Location Management Sheets

- [ ] **LOC-01**: Location Sheet (triggered from Home header) lists saved locations and current GPS location; tapping any switches the active context
- [ ] **LOC-02**: Location Sheet has a search entry point to find and add new locations
- [ ] **LOC-03**: Saved Locations Sheet (converted from full screen) allows viewing, editing, and deleting saved locations
- [ ] **LOC-04**: Add/Edit Location Sheet (converted from full screen) allows searching for a location, previewing its zone, and saving it
- [ ] **LOC-05**: Delete location shows Confirm Delete dialog before removing

### Other Sheets & Screens

- [ ] **ATMO-01**: Atmospherics Sheet shows detailed weather breakdown: cloud cover, seeing, transparency, humidity, wind — redesigned per Figma spec
- [ ] **SPLASH-01**: Splash screen shows Astr branding during initialization sequence — redesigned per Figma spec
- [ ] **TOS-01**: Terms of Service screen is accessible from Settings (not only on first launch) and is redesigned per Figma spec
- [ ] **TOS-02**: Red Mode Overlay is preserved and applies correctly across all redesigned screens

### Bug Fixes

- [ ] **BUG-01**: All home screen providers (weather, astronomy, zone, sky state, moon phase, visibility) fully refresh when the date is changed via `<`/`>` arrows — no stale data from previous date remains visible
- [ ] **BUG-02**: All providers fully refresh when the active location is switched — no stale data from the previous location remains on any screen
- [ ] **BUG-03**: Future date forecast tap (from Forecast screen tapping a day) correctly updates all home screen state for the selected date

### Testing

- [ ] **TEST-01**: Unit tests cover Astr Zone calculation formula — given input luminance values, correct zone is returned
- [ ] **TEST-02**: Unit tests cover skyglow diffusion calculation — given known inputs, diffusion output matches expected zenith brightness
- [ ] **TEST-03**: Unit tests cover sky state determination — given zone + cloud cover + moon illumination, correct sky state is returned
- [ ] **TEST-04**: Widget/integration tests verify all home screen providers update correctly when date changes (no stale reads)
- [ ] **TEST-05**: Widget/integration tests verify all providers refresh correctly when location switches
- [ ] **TEST-06**: Integration test covers core user flow: app launch → view home → switch location → browse forecast → return home with updated data

### App Store Submission

- [ ] **STORE-01**: Android release signing is configured: keystore generated, Gradle signing config set up, release APK/AAB builds correctly
- [ ] **STORE-02**: iOS release signing is configured: distribution certificate and provisioning profile set up, Xcode archive builds correctly
- [ ] **STORE-03**: Store metadata is written and finalized: app name, short description, full description, keywords, category, content rating
- [ ] **STORE-04**: Store screenshots are captured for all required device sizes (Android: phone + 7" tablet; iOS: 6.5" + 5.5" + iPad)
- [ ] **STORE-05**: Privacy policy is written covering: GPS location use, background sync, no data sold to third parties, Cloudflare data handling
- [ ] **STORE-06**: App passes Apple App Store Review Guidelines audit: no missing entitlements, privacy usage strings filled, no rejection-risk patterns
- [ ] **STORE-07**: App passes Google Play policy audit: permissions justified, background location declared, target SDK meets current requirements
- [ ] **STORE-08**: Release build pipeline is established: version code/name management, tagged release builds, reproducible release artifacts
- [ ] **STORE-09**: All required app icon sizes are present and correct for both platforms
- [ ] **STORE-10**: Background location permission use is justified in both stores' permission declarations

## v2 Requirements

### Future Enhancements

- **V2-01**: Onboarding flow for first-time users explaining zones and sky states
- **V2-02**: Push notifications for good observing windows ("Clear skies tonight at your saved location")
- **V2-03**: Observation log — user can record what they saw on a given night
- **V2-04**: Widget (home screen / lock screen) showing current sky state
- **V2-05**: Additional languages beyond English and Turkish

## Out of Scope

| Feature | Reason |
|---------|--------|
| MongoDB backend revival | Replaced by Cloudflare + Open-Meteo; archived not restored |
| Web platform target | Mobile-first; web build was incidental and not maintained |
| Social / sharing features | Not core to the stargazing use case |
| Video content | Not relevant |
| Real-time sky camera integration | Future milestone consideration |
| In-app purchases / subscriptions | Not planned for v1 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ARCH-01 | Phase 1 — Archive & Cleanup | Pending |
| ARCH-02 | Phase 1 — Archive & Cleanup | Pending |
| ARCH-03 | Phase 1 — Archive & Cleanup | Pending |
| ARCH-04 | Phase 1 — Archive & Cleanup | Pending |
| ARCH-05 | Phase 1 — Archive & Cleanup | Pending |
| ARCH-06 | Phase 1 — Archive & Cleanup | Pending |
| ZONE-01 | Phase 2 — Zone Data Validation | Complete |
| ZONE-02 | Phase 2 — Zone Data Validation | Complete |
| ZONE-03 | Phase 2 — Zone Data Validation | Complete |
| ZONE-04 | Phase 2 — Zone Data Validation | Pending |
| DS-01 | Phase 3 — Design System + Home Screen | Complete |
| DS-02 | Phase 3 — Design System + Home Screen | Pending |
| DS-03 | Phase 3 — Design System + Home Screen | Complete |
| HOME-01 | Phase 3 — Design System + Home Screen | Pending |
| HOME-02 | Phase 3 — Design System + Home Screen | Pending |
| HOME-03 | Phase 3 — Design System + Home Screen | Pending |
| HOME-04 | Phase 3 — Design System + Home Screen | Pending |
| HOME-05 | Phase 3 — Design System + Home Screen | Pending |
| HOME-06 | Phase 3 — Design System + Home Screen | Pending |
| HOME-07 | Phase 3 — Design System + Home Screen | Pending |
| HOME-08 | Phase 3 — Design System + Home Screen | Pending |
| HOME-09 | Phase 3 — Design System + Home Screen | Pending |
| OBJ-01 | Phase 4 — Objects Screen & Object Detail Sheet | Pending |
| OBJ-02 | Phase 4 — Objects Screen & Object Detail Sheet | Pending |
| OBJ-03 | Phase 4 — Objects Screen & Object Detail Sheet | Pending |
| OBJ-04 | Phase 4 — Objects Screen & Object Detail Sheet | Pending |
| OBJD-01 | Phase 4 — Objects Screen & Object Detail Sheet | Pending |
| OBJD-02 | Phase 4 — Objects Screen & Object Detail Sheet | Pending |
| OBJD-03 | Phase 4 — Objects Screen & Object Detail Sheet | Pending |
| BUG-01 | Phase 5 — Bug Fixes | Pending |
| BUG-02 | Phase 5 — Bug Fixes | Pending |
| BUG-03 | Phase 5 — Bug Fixes | Pending |
| FORE-01 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| FORE-02 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| FORE-03 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| FORE-04 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| SETT-01 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| SETT-02 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| SETT-03 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| LOC-01 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| LOC-02 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| LOC-03 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| LOC-04 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| LOC-05 | Phase 6 — Forecast, Settings & Location Sheets | Pending |
| ATMO-01 | Phase 7 — Atmospherics, Splash & Terms of Service | Pending |
| SPLASH-01 | Phase 7 — Atmospherics, Splash & Terms of Service | Pending |
| TOS-01 | Phase 7 — Atmospherics, Splash & Terms of Service | Pending |
| TOS-02 | Phase 7 — Atmospherics, Splash & Terms of Service | Pending |
| TEST-01 | Phase 8 — Comprehensive Testing | Pending |
| TEST-02 | Phase 8 — Comprehensive Testing | Pending |
| TEST-03 | Phase 8 — Comprehensive Testing | Pending |
| TEST-04 | Phase 8 — Comprehensive Testing | Pending |
| TEST-05 | Phase 8 — Comprehensive Testing | Pending |
| TEST-06 | Phase 8 — Comprehensive Testing | Pending |
| STORE-01 | Phase 9 — App Store Submission | Pending |
| STORE-02 | Phase 9 — App Store Submission | Pending |
| STORE-03 | Phase 9 — App Store Submission | Pending |
| STORE-04 | Phase 9 — App Store Submission | Pending |
| STORE-05 | Phase 9 — App Store Submission | Pending |
| STORE-06 | Phase 9 — App Store Submission | Pending |
| STORE-07 | Phase 9 — App Store Submission | Pending |
| STORE-08 | Phase 9 — App Store Submission | Pending |
| STORE-09 | Phase 9 — App Store Submission | Pending |
| STORE-10 | Phase 9 — App Store Submission | Pending |

**Coverage:**

- v1 requirements: 52 total
- Mapped to phases: 52
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-13*
*Last updated: 2026-06-13 — traceability updated to reflect 9-phase roadmap*
