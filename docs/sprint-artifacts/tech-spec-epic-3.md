# Epic Technical Specification: Epic 3: Qualitative Conditions & Visual Polish ✨

Date: 2025-12-04
Author: Vansh
Epic ID: 3
Status: Draft

---

## Overview

Epic 3 focuses on refining the user experience of Astr by introducing a **Qualitative Condition Engine**, optimizing performance to achieve **60fps scrolling**, and polishing the visual identity with **Satoshi typography** and high-quality **WebP assets**. This epic bridges the gap between raw data and user-friendly advice while ensuring the app feels premium and responsive.

## Objectives and Scope

### In-Scope
*   **Qualitative Condition Engine:** Translating raw environmental data (Cloud, Moon, Bortle) into human-readable advice (e.g., "Milky Way Visible").
*   **Performance Optimization:** Refactoring `GlassPanel` and offloading heavy astronomy math to Isolates to ensure >55fps scrolling.
*   **Visual Polish:** Replacing Nunito with Satoshi font, updating icons to WebP, and implementing a custom Splash Screen.
*   **Production Readiness:** Addressing manual testing bugs and generating signed release builds.

### Out-of-Scope
*   **Layout Changes:** No structural changes to the UI layout are permitted.
*   **New Features:** No new functionality beyond the condition engine and visual updates.

## System Architecture Alignment

This epic aligns with the **Offline-First** and **Glass UI** architectural pillars:
*   **Qualitative Engine:** Operates entirely offline using local data sources (Weather, Astronomy Engine).
*   **Performance:** Enforces the "Isolate Boundary" rule defined in `architecture.md` for heavy calculations.
*   **Assets:** Follows the project structure for `assets/fonts` and `assets/images`.

## Detailed Design

### Services and Modules

| Module | Responsibility | Inputs | Outputs | Owner |
| :--- | :--- | :--- | :--- | :--- |
| `QualitativeConditionService` | Analyzes environmental factors to determine observing quality. | `CloudCover`, `MoonPhase`, `BortleZone` | `ConditionStatus` (Enum), `AdviceString` | Logic Layer |
| `GlassPanel` (Refactor) | Optimized UI component for glass effects. | `Child Widget`, `Opacity` | Rendered Widget | UI Layer |
| `SplashController` | Manages app initialization and splash animation. | App Start | Navigation to Home | UI Layer |

### Data Models and Contracts

**Enum: `ConditionQuality`**
```dart
enum ConditionQuality {
  excellent, // "Star Party Mode"
  good,      // "Great for Galaxies"
  fair,      // "Planets Only"
  poor,      // "Stay Inside"
  unknown
}
```

**Class: `ConditionResult`**
```dart
class ConditionResult {
  final ConditionQuality quality;
  final String shortSummary; // e.g., "Excellent"
  final String detailedAdvice; // e.g., "Milky Way Visible"
  final Color statusColor; // Derived from quality
}
```

### APIs and Interfaces

*   `IQualitativeConditionService.evaluate(Weather weather, Astronomy astro, LightPollution lp) -> ConditionResult`

### Workflows and Sequencing

1.  **App Start:** `SplashController` initializes -> Loads Assets/DB -> Navigates to Home.
2.  **Home Load:** `WeatherProvider` + `AstronomyProvider` -> `QualitativeConditionService` -> Updates Home Header UI.
3.  **Scrolling:** `GlassPanel` uses `RepaintBoundary` or optimized `BackdropFilter` to prevent rasterization spikes.

## Non-Functional Requirements

### Performance
*   **Frame Rate:** Scrolling must maintain >55fps on reference devices (iPhone 12, Pixel 6).
*   **Startup:** Cold start < 2s (excluding splash animation).

### Security
*   No new security requirements.

### Reliability/Availability
*   **Offline:** Condition engine must work 100% offline.

### Observability
*   Log initialization times for Splash Screen performance tracking.

## Dependencies and Integrations

*   **Fonts:** `google_fonts` (or local `.ttf` assets for Satoshi).
*   **Animation:** `lottie` or `flutter_svg` for Splash Screen.
*   **Isolates:** `flutter_isolate` or native Dart `Isolate` for math offloading.

## Acceptance Criteria (Authoritative)

1.  **Qualitative Feedback:**
    *   **Given** environmental factors (Bortle, Cloud, Moon), **When** the Home Screen loads, **Then** display a text-based condition summary (e.g., "Excellent - Great for Galaxies").
    *   **UI Update:** Replace the "66/100" text widget with this new descriptive text widget, keeping the same font size/weight hierarchy.
2.  **Scroll Performance:**
    *   **Given** a list with Glass cards, **When** scrolling, **Then** the frame rate remains >55fps on target devices.
3.  **Typography:**
    *   **Font:** Replace Nunito with **Satoshi** globally. Ensure weights/sizes map correctly to preserve hierarchy.
4.  **Assets:**
    *   **Icons:** Integrate high-quality WebP assets for Moon Phases and Sun, replacing current placeholders.
    *   **Splash:** Implement the new SVG/Lottie splash screen.
5.  **Production Build:**
    *   **Given** the codebase is stable, **When** the build pipeline runs, **Then** it produces a signed APK/AAB and IPA ready for store submission.

## Traceability Mapping

| AC ID | Story | Component | Test Idea |
| :--- | :--- | :--- | :--- |
| AC 1 | 3.1 | `QualitativeConditionService` | Unit test with various weather/moon combos |
| AC 2 | 3.2 | `GlassPanel` | Profile scrolling in Profile mode |
| AC 3 | 3.3 | `AppTheme` | Visual inspection of font rendering |
| AC 4 | 3.3 | `Assets` | Verify asset loading and resolution |
| AC 5 | 3.5 | `Build Pipeline` | Install release build on physical device |

## Risks, Assumptions, Open Questions

*   **Risk:** `BackdropFilter` is notoriously expensive on Android.
    *   *Mitigation:* Use `ImageFilter.blur` on a static background snapshot if dynamic blur is too slow, or reduce blur radius during scroll.
*   **Assumption:** Satoshi font license allows for free commercial use (Open Source/OFL).
    *   *Action:* Verify license before bundling.

## Test Strategy Summary

*   **Unit Tests:** comprehensive coverage for `QualitativeConditionService` logic.
*   **Performance Testing:** Use Flutter DevTools (Performance Overlay) to measure raster time during scrolling.
*   **Visual QA:** Manual verification of font weights and asset scaling on different screen sizes.
