# Astr - Architecture Decision Document

**Status:** Approved
**Date:** 2025-12-03
**Version:** 1.0

---

## 1. Executive Summary
This architecture defines the technical strategy for the **Astr Brownfield Overhaul**. The core shift is moving from a dependency-heavy, online-reliant model to a **Dart Native, Offline-First** architecture. We introduce a local SQLite database for celestial objects, Isolate-based background calculations for performance, and a hybrid Light Pollution system using WebP assets.

## 2. Architectural Decisions

| Category | Decision | Rationale |
| :--- | :--- | :--- |
| **Database** | **SQLite (`sqflite`)** | Relational queries are required for filtering stars by magnitude/type. **Constraint:** Raw CSV sources will NOT be bundled; only the optimized `.db` file will be shipped to keep app size low. |
| **Concurrency** | **Dart Isolates** | Heavy Meeus algorithms (trigonometry for 9000+ objects) must run off the main thread to guarantee the **60fps Glass UI** target. |
| **LP Map Format** | **WebP (Lossless)** | WebP offers superior compression over PNG while maintaining exact pixel values needed for the Bortle scale lookup, minimizing app size. |
| **State Mgmt** | **Riverpod** | Continue using existing Riverpod implementation (as seen in `pubspec.yaml`) for consistent state management. |
| **Backend** | **Python/Flask (Vercel)** | Keep existing backend for API-based high-precision data, serving as the "Online" component of the hybrid system. |

---

## 3. Project Structure (Brownfield Adaptation)

We will maintain the existing structure but add specific directories for the new engine.

```text
lib/
├── main.dart
├── core/
│   ├── engine/                 # [NEW] The Dart Native Astronomy Engine
│   │   ├── algorithms/         # Meeus implementation (pure Dart)
│   │   ├── database/           # SQLite database manager
│   │   ├── isolates/           # Background calculation manager
│   │   └── models/             # CelestialObject, Coordinates, etc.
│   ├── services/
│   │   ├── light_pollution/    # [NEW] Hybrid Service (API + WebP Fallback)
│   │   └── weather/            # Weather fetching service
│   └── utils/
├── data/                       # Data Layer
│   ├── models/
│   └── repositories/
├── ui/                         # Presentation Layer
│   ├── common/                 # Shared widgets (GlassPanel, etc.)
│   ├── features/
│   │   ├── home/
│   │   ├── catalog/
│   │   └── settings/
│   └── theme/                  # [UPDATE] Add Satoshi font, update colors
└── assets/
    ├── db/                     # [NEW] Pre-populated astr.db
    ├── images/
    │   └── light_pollution/    # [NEW] world_lp.webp
    └── fonts/                  # [NEW] Satoshi font files
```

---

## 4. Implementation Patterns

### Naming Conventions
*   **Classes:** `PascalCase` (e.g., `CelestialCalculator`)
*   **Variables/Functions:** `camelCase` (e.g., `calculateAltitude`)
*   **Files:** `snake_case` (e.g., `celestial_calculator.dart`)
*   **Interfaces:** Prefix with `I` (e.g., `IAstroEngine`) to clearly distinguish contracts.

### Error Handling
*   **Result Pattern:** Use a `Result<T>` type (or `fpdart` if available, otherwise simple custom class) for Engine operations to handle failures gracefully without unchecked exceptions crashing the UI.
*   **UI Feedback:** Errors in background isolates must be caught and sent as "Error Events" to the main thread to show user-friendly toasts/snackbars.

### Performance Rules
*   **Isolate Boundary:** Any calculation taking >16ms (1 frame) MUST move to an Isolate.
*   **Asset Loading:** Large assets (LP Map, DB) must be loaded asynchronously during the Splash Screen.

---

## 5. Data Architecture

### Local Database Schema (SQLite)
**Table: `stars`**
*   `id` (INTEGER PK)
*   `hip_id` (INTEGER) - Hipparcos ID
*   `ra` (REAL) - Right Ascension
*   `dec` (REAL) - Declination
*   `mag` (REAL) - Magnitude
*   `name` (TEXT) - Common name (e.g., "Sirius")
*   `bayer` (TEXT) - Bayer designation
*   `constellation` (TEXT)

**Table: `dso`**
*   `id` (INTEGER PK)
*   `messier_id` (TEXT)
*   `ngc_id` (TEXT)
*   `type` (TEXT) - Galaxy, Nebula, Cluster
*   `ra` (REAL)
*   `dec` (REAL)
*   `mag` (REAL)

---

## 6. Integration Points

*   **Engine -> UI:** The UI subscribes to a `Stream<EngineState>` provided by a Riverpod `StateNotifier`. The Engine pushes updates (new Alt/Az positions) every X seconds (configurable).
*   **Backend -> Mobile:** Mobile app calls Python backend endpoints `/api/light-pollution` and `/api/weather`. Failures trigger the local fallback logic immediately.

---

## 7. Security & Privacy
*   **Location Data:** User location is used strictly for local calculations and ephemeral API calls. It is NOT stored permanently on the backend.
*   **Offline Mode:** App must function 100% without network permissions after initial install (except for map tiles if using external map provider).

---

## 8. Deployment
*   **Mobile:** Standard Flutter build process (IPA/APK).
*   **Backend:** Vercel Serverless Functions (Python runtime).
