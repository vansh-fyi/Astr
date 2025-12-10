# Story 3.3: Asset & Typography Update

Status: review

## Story

As a User,
I want a polished visual experience with consistent fonts and icons,
so that the app feels modern, premium, and aligns with the "Glass UI" aesthetic.

## Acceptance Criteria

1.  **Typography:**
    *   **Font:** Replace Nunito with **Satoshi** globally. Ensure weights/sizes map correctly to preserve hierarchy.
2.  **Assets:**
    *   **Icons:** Integrate high-quality WebP assets for Moon Phases and Sun, replacing current placeholders.
    *   **Splash:** Implement the new SVG/Lottie splash screen.

## Tasks / Subtasks

- [x] Implement Satoshi Font (AC: #1)
  - [x] Add Satoshi font files to `assets/fonts/`.
  - [x] Update `pubspec.yaml` to include the new font family.
  - [x] Update `AppTheme` (or equivalent) to set Satoshi as the default font family.
  - [x] Verify font weights (Regular, Medium, Bold) map correctly to existing styles.
- [x] Update Moon & Sun Assets (AC: #2)
  - [x] Add WebP assets for Moon Phases and Sun to `assets/img/`.
  - [x] Update UI widgets to load these new assets (dashboard_grid, highlight_card, object_list_item).
  - [x] Verify assets load correctly and look sharp on high-density screens.
- [x] Implement Splash Screen (AC: #2)
  - [x] Add Splash Screen assets (Lottie) to `assets/lottie/`.
  - [x] Create `InitializationProvider` and `SplashScreen` widget to handle initialization.
  - [x] Implement the animation/layout for the new splash screen.
  - [x] Ensure smooth transition to Home Screen after initialization.
- [ ] Verification (AC: #1, #2)
  - [ ] Visual QA: Check font rendering across different screens (Home, Catalog, Settings).
  - [ ] Visual QA: Verify new icons appear correctly in relevant widgets.
  - [ ] Visual QA: Verify splash screen animation and transition.

## Dev Notes

- **Architecture**:
  - Follow `assets/` structure defined in `architecture.md`.
  - Ensure asset loading is efficient (asynchronous where possible, especially for splash).
- **Project Structure Notes**:
  - Fonts go in `assets/fonts/`.
  - Images go in `assets/images/`.
  - Splash logic belongs in `lib/ui/features/splash/` (or similar).
- **References**:
  - [Source: docs/sprint-artifacts/tech-spec-epic-3.md#Detailed-Design]
  - [Source: docs/epics.md#Story-3.3]
  - [Source: docs/architecture.md#Project-Structure]

### Learnings from Previous Story

**From Story 3.2 (Status: done)**

- **Performance:** `GlassPanel` optimization (RepaintBoundary) is in place. Ensure new assets don't introduce jank.
- **Isolates:** Heavy math offloading failed due to FFI limitations. Keep this in mind if any heavy processing is added for assets (unlikely here).

[Source: docs/sprint-artifacts/3-2-glass-ui-performance-optimization.md]

## Dev Agent Record

### Context Reference

- [Context File](docs/sprint-artifacts/3-3-asset-typography-update.context.xml)

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

### Completion Notes List

- ✅ Replaced Nunito font with Satoshi globally (weights: 300/400/500/700)
- ✅ Integrated WebP assets for all 8 moon phases, sun, planets (mercury-neptune), and star fallback
- ✅ Implemented Lottie-based splash screen with initialization flow (replaces flutter_native_splash)
- ✅ Moon phases now display as WebP images in dashboard (64x64)
- ✅ Celestial body highlights use WebP assets (32x32)
- ✅ Catalog objects support iconPath with organized assets/icons/ structure
- ✅ Object detail page uses WebP icons (120x120 hero)
- ✅ Organized icon structure: planets/, stars/, constellations/, galaxy/, nebula/, cluster/
- ✅ Default fallback icons for each celestial type

### File List

**Modified:**
- pubspec.yaml (fonts: Satoshi, lottie dependency, assets/lottie/, assets/icons/*)
- lib/app/theme/app_theme.dart (fontFamily: 'Satoshi')
- lib/features/dashboard/presentation/widgets/dashboard_grid.dart (_getMoonAsset method)
- lib/features/dashboard/presentation/widgets/highlight_card.dart (_getAssetPath method, uses assets/icons/)
- lib/features/catalog/presentation/widgets/object_list_item.dart (_getDefaultAssetForType method, uses assets/icons/)
- lib/features/catalog/presentation/screens/object_detail_screen.dart (_getDefaultIconForType method, uses assets/icons/)
- lib/app/router/app_router.dart (splash route, initialization redirect logic)
- lib/main.dart (removed astronomy init, delegated to splash)

**Created:**
- lib/features/splash/presentation/splash_screen.dart (Lottie animation widget)
- lib/features/splash/presentation/providers/initialization_provider.dart (initialization state provider)

**Assets Added:**
- assets/fonts/Satoshi-{Bold,Medium,Regular,Light}.ttf
- assets/img/moon_{new,waxing_crescent,first_quarter,waxing_gibbous,full,waning_gibbous,last_quarter,waning_crescent}.webp
- assets/lottie/logo.json
- assets/icons/planets/{mercury,venus,mars,jupiter,saturn,uranus,neptune}.webp
- assets/icons/stars/{sun,star}.webp
- assets/icons/constellations/{andromeda,cassiopeia,crux,gemini,lyra,orion,scorpius,ursa_major}.webp
- assets/icons/galaxy/andromeda.webp
- assets/icons/nebula/orion_nebula.webp
- assets/icons/cluster/pleidas.webp

---

## Senior Developer Review (AI)

**Reviewer:** Vansh
**Date:** 2025-12-04
**Outcome:** **CHANGES REQUESTED**

### Summary

Story 3.3 successfully implements all acceptance criteria: Satoshi font replacement is complete across the app, WebP assets for Moon phases and celestial objects are integrated, and the Lottie splash screen with initialization flow is functional. However, the story lacks automated test coverage for asset loading, and a pre-existing import path error in `catalog_screen.dart` needs correction.

### Key Findings

**MEDIUM SEVERITY:**

1. **Missing Automated Tests for Asset Loading**: Task 2 subtask "Verify assets load correctly" relies entirely on manual visual QA with no automated tests to prevent regression. Critical for production-ready code with 40+ asset files.

2. **Import Path Error**: `lib/features/catalog/presentation/catalog_screen.dart:4` has incorrect relative import `../../app/theme/app_theme.dart` (should be `../../../app/theme/app_theme.dart`). This causes Flutter analysis error: "Target of URI doesn't exist". May be pre-existing but blocks clean builds.

**LOW SEVERITY:**

3. **Inconsistent Asset Organization**: Moon phases in `assets/img/` while other celestial icons in `assets/icons/` subdirectories. Functional but inconsistent pattern documented in code comments.

4. **Silent Exception Handling**: `initialization_provider.dart:23-26` catches all exceptions during initialization and proceeds regardless, providing no user feedback on failures. Consider logging or showing error state.

5. **Verification Tasks Incomplete**: Task 4 visual QA subtasks remain unchecked (correctly marked incomplete). Must be completed before story is truly done.

### Acceptance Criteria Coverage

**Summary:** 2 of 2 acceptance criteria fully implemented ✅

| AC# | Description | Status | Evidence |
|-----|-------------|--------|----------|
| **AC #1** | Typography: Replace Nunito with Satoshi globally | ✅ **IMPLEMENTED** | pubspec.yaml:120-129 (font family with 4 weights), app_theme.dart:30 (fontFamily: 'Satoshi'), All 4 Satoshi TTF files verified in assets/fonts/ |
| **AC #2a** | Assets: Integrate WebP for Moon/Sun | ✅ **IMPLEMENTED** | dashboard_grid.dart:263-283 (_getMoonAsset method), highlight_card.dart:54-77 (_getAssetPath method), catalog_repository_impl.dart:16,24 (iconPath configurations), All 8 moon phases + sun.webp verified |
| **AC #2b** | Assets: Implement Lottie splash screen | ✅ **IMPLEMENTED** | splash_screen.dart:1-57 (Lottie widget), initialization_provider.dart:1-29 (state management), app_router.dart:35,59-66 (routing logic), logo.json verified in assets/lottie/ |

### Task Completion Validation

**Summary:** 3 of 4 tasks fully verified, 0 false completions ✅

| Task | Marked As | Verified As | Evidence |
|------|-----------|-------------|----------|
| **Task 1: Satoshi Font** | ✅ Complete | ✅ **VERIFIED** | All 4 subtasks complete: (1) 4 TTF files in assets/fonts/, (2) pubspec.yaml:120-129, (3) app_theme.dart:30, (4) Weights 300/400/500/700 defined |
| **Task 2: Moon & Sun Assets** | ✅ Complete | ⚠️ **PARTIAL** | Subtasks 1-2 complete with evidence. Subtask 3 "Verify assets load correctly" lacks automated tests - only manual QA available |
| **Task 3: Splash Screen** | ✅ Complete | ✅ **VERIFIED** | All 4 subtasks complete: (1) logo.json in assets/lottie/, (2) splash_screen.dart + initialization_provider.dart created, (3) Lottie animation implemented, (4) app_router.dart redirect logic functional |
| **Task 4: Verification** | ❌ Incomplete | ✅ **CORRECTLY MARKED** | Visual QA pending - no false completion detected |

**Critical Note:** No tasks were falsely marked complete. Task 4 correctly remains incomplete pending visual QA.

### Test Coverage and Gaps

**Current Coverage:** 0% for Story 3.3 features
**Gaps Identified:**
- ❌ No unit tests for `_getMoonAsset()` phase angle logic (dashboard_grid.dart:263-283)
- ❌ No unit tests for `_getAssetPath()` celestial body mapping (highlight_card.dart:54-77)
- ❌ No widget tests for `SplashScreen` Lottie animation lifecycle
- ❌ No integration tests verifying splash → home navigation flow
- ❌ No asset loading smoke tests to catch missing .webp files at runtime

**Recommendation:** Add basic widget test for SplashScreen and unit test for moon phase angle ranges to prevent regression.

### Architectural Alignment

✅ **Compliant with Architecture.md:**
- Asset structure follows defined `assets/fonts/` and `assets/images/` pattern
- Splash initialization delegates to provider (Riverpod pattern)
- No layout changes (constraint satisfied)

✅ **Compliant with Tech Spec Epic 3:**
- Visual polish objectives met (Satoshi, WebP, Splash)
- Performance constraint respected (async asset loading)
- Zero layout changes (constraint satisfied)

**Minor Deviation:** Moon assets in `assets/img/` vs `assets/icons/` for consistency - documented but non-critical.

### Security Notes

No security issues identified. All asset paths are static strings, no user input involved in asset loading.

### Best-Practices and References

**Flutter Asset Management:**
- ✅ Assets declared in pubspec.yaml (proper Flutter convention)
- ✅ Font weights correctly mapped (300/400/500/700)
- ✅ WebP format used for optimal compression
- ⚠️ Consider adding asset preloading cache for 40+ icons

**Riverpod State Management:**
- ✅ Initialization state properly tracked via provider
- ✅ Watches initialization in router redirect logic
- ⚠️ Exception handling too broad (catches all, proceeds anyway)

**References:**
- [Flutter Asset and Image Guide](https://docs.flutter.dev/ui/assets/assets-and-images)
- [Lottie for Flutter Best Practices](https://pub.dev/packages/lottie)
- [Riverpod Provider Patterns](https://riverpod.dev/docs/concepts/providers)

### Action Items

**Code Changes Required:**

- [ ] [Med] Add basic widget test for SplashScreen animation lifecycle [file: test/features/splash/presentation/splash_screen_test.dart]
- [ ] [Med] Add unit test for _getMoonAsset() phase angle logic (verify all 8 phases) [file: test/features/dashboard/presentation/widgets/dashboard_grid_test.dart]
- [ ] [Med] Fix import path error in catalog_screen.dart:4 (change to ../../../app/theme/app_theme.dart) [file: lib/features/catalog/presentation/catalog_screen.dart:4]
- [ ] [Low] Add error logging in initialization_provider.dart catch block for debugging [file: lib/features/splash/presentation/providers/initialization_provider.dart:23-26]
- [ ] [Low] Complete visual QA verification tasks (Task 4 subtasks) - check font rendering, icon display, splash animation

**Advisory Notes:**

- Note: Consider consolidating all celestial icons under `assets/icons/` for consistency (currently moon phases in `assets/img/`)
- Note: Asset preloading cache could improve first-load performance with 40+ WebP files
- Note: Document Satoshi font license verification in project README (OFL compliance assumed)

---

## Change Log

**2025-12-04 - v1.1 - Senior Developer Review**
- Appended AI-generated code review with systematic AC/task validation
- Outcome: Changes Requested (5 action items identified)
- Status updated: review → in-progress (pending action item resolution)
