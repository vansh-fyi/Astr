# System-Level Test Design

## Testability Assessment

- **Controllability**: **PASS**. The architecture uses `Riverpod` for state management, which allows easy overriding of providers for testing. The `IAstroEngine` interface (implied by naming conventions) enables mocking the complex Isolate-based engine for UI and logic tests. SQLite database is file-based and can be easily reset or seeded.
- **Observability**: **PASS**. Riverpod provides excellent state visibility. The architecture mandates error events from Isolates to the UI, making background failures observable.
- **Reliability**: **CONCERNS**. Testing Dart Isolates introduces complexity. We must ensure the `IAstroEngine` abstraction is strictly adhered to so that tests can run synchronously without spawning real isolates, which can be flaky or slow in test environments.

## Architecturally Significant Requirements (ASRs)

| ID | Requirement | Category | Risk Score | Driver |
|---|---|---|---|---|
| ASR-01 | **60fps Glass UI Performance** | PERF | 9 (High) | Heavy astronomy math on main thread causes jank. driven Isolate decision. |
| ASR-02 | **Offline-First Astronomy Engine** | REL | 9 (High) | Core value prop. Must work without network. Driven SQLite & Local Calc decision. |
| ASR-03 | **App Size < 100MB** | OPS | 6 (Med) | Large datasets (stars, LP map). Driven WebP & Optimized DB decision. |
| ASR-04 | **Hybrid Light Pollution Data** | DATA | 6 (Med) | Fallback logic complexity (API -> Local). Driven Hybrid Service decision. |

## Test Levels Strategy

Given the "Brownfield" nature and the "Offline-First" architecture, we recommend the following split:

- **Unit (60%)**: Focus on the `core/engine/algorithms` (Meeus implementation). These are pure functions and must be rigorously tested against verified data (e.g., Stellarium/NASA) to ensure astronomical accuracy.
- **Widget/Component (20%)**: Test the "Glass UI" components (`GlassPanel`, Graphs) in isolation to ensure they render correctly and handle state changes (loading, error, data) without visual regression.
- **Integration (15%)**: Focus on the `core/engine/database` (SQLite) and `core/engine/isolates` communication. Verify that data flows correctly from DB -> Engine -> UI. Test the Hybrid Light Pollution service switching logic.
- **E2E (5%)**: Critical user journeys only. 1. App Launch -> Location Fix -> Dashboard Load. 2. Search -> Object Detail -> Graph Interaction. 3. Offline Mode Verification.

## NFR Testing Approach

- **Performance (60fps)**:
    - **Tool**: Flutter DevTools & Integration Tests (Profile Mode).
    - **Approach**: Measure frame build times during heavy scrolling on the Catalog screen.
    - **Threshold**: 95th percentile build time < 16ms.
- **Offline Reliability**:
    - **Tool**: Integration Tests with mocked connectivity.
    - **Approach**: Simulate network failure and verify `HybridLightPollutionService` falls back to local assets without error. Verify `AstronomyEngine` functions without network.
- **Data Accuracy**:
    - **Tool**: Unit Tests (Data Driven).
    - **Approach**: Compare `calculatePosition()` outputs against a "Gold Standard" dataset (CSV of known positions) with a tolerance of < 1 degree.

## Test Environment Requirements

- **Local**: Standard Flutter test environment. SQLite support required (use `sqflite_common_ffi` for desktop/test running).
- **CI**: GitHub Actions. Needs to support Flutter, Python (for backend tests if any), and potentially an emulator for E2E if feasible (otherwise rely on Integration tests).

## Testability Concerns

- **Isolate Testing**: Spawning real isolates in unit tests can be slow and flaky.
    - **Mitigation**: Strictly use `IAstroEngine` interface. Create a `MockAstroEngine` that runs calculations synchronously on the main thread for Unit/Widget tests. Only use real Isolates in specific Integration tests.
- **Visual Regression**: Glass UI is sensitive to rendering changes.
    - **Mitigation**: Consider Golden Tests for key widgets (`GlassPanel`, `VisibilityGraph`) to catch visual regressions.

## Recommendations for Sprint 0

1.  **Define `IAstroEngine` Interface**: Immediately define the contract for the engine to enable parallel development and testing.
2.  **Setup `sqflite_common_ffi`**: Ensure the test environment can run SQLite tests on the host machine (macOS/Linux/Windows) without an emulator.
3.  **Create "Gold Standard" Data**: Generate or acquire a CSV of verified celestial positions (Time, Lat, Long -> RA, Dec, Alt, Az) to use as the truth source for Unit Tests.
