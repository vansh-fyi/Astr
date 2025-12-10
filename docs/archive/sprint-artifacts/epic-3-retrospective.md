# Epic 3 Retrospective: Celestial Catalog & Visibility Graph

> **Date:** 2025-11-29
> **Epic Status:** Done
> **Participants:** Vansh (Project Lead), Bob (SM), Alice (PO), Charlie (Dev), Dana (QA), Elena (Dev)

## 1. Executive Summary
Epic 3 delivered the core "Deep Precision" features of Astr: the Celestial Catalog and the novel Universal Visibility Graph. Despite the team's unfamiliarity with Flutter, we successfully pivoted from a complex Rive implementation to a native `CustomPaint` solution for the graph, delivering a high-performance, responsive visualization that meets all design requirements.

## 2. Key Achievements
*   **Pragmatic Pivot:** Successfully switched from Rive to `CustomPaint` for the Visibility Graph (Story 3.3), simplifying the build process and improving developer velocity without sacrificing user value.
*   **Architecture Resilience:** The `IAstroEngine` interface (established in Epic 1) proved its worth, allowing seamless reuse of complex astronomical calculations for the new visibility logic.
*   **Quality Standard:** Maintained 100% test pass rate across all stories (3.1, 3.2, 3.3).
*   **Visual Consistency:** The "Glass Pattern" and "Deep Cosmos" theme were consistently applied, creating a cohesive UI.

## 3. What Went Well
*   **Architecture:** The "Result Pattern" (`Either<Failure, T>`) continued to prevent runtime crashes and enforce error handling.
*   **Testing:** Separation of logic (`VisibilityService`) from rendering (`VisibilityGraphPainter`) made unit testing straightforward and robust.
*   **Team Adaptation:** The team (and User) adapted quickly to Flutter paradigms, identifying `CustomPaint` as a superior tool for data-driven graphs compared to animation-focused Rive.

## 4. Challenges & Lessons Learned
*   **Visual Feedback Loop:** We realized that "passing tests" != "seeing the app". We lacked a consistent "Demo" step, leaving the User unsure of the visual progress.
    *   *Lesson:* Code completion is not product completion. We need to run the app more often.
*   **Test Fragility:** Some widget tests had to skip Rive-dependent components due to FFI limitations in the test environment.
    *   *Lesson:* Our test infrastructure has some fragile dependencies (Rive) that need monitoring.

## 5. Action Items
*   **[Process]** Update workflows to include a mandatory "Visual Verification" step (Run `flutter run`) to ensure the "product" is reviewed, not just the "code".
*   **[Documentation]** Maintain `docs/how-to-run.md` to help React-background developers navigate Flutter tooling.
*   **[Tech Debt]** Monitor performance of the Visibility Graph on older devices (heavy calculation load).
*   **[UX Polish]** Add haptic feedback to the graph scrubber in a future polish story (Story 5.3).

## 6. Metrics
*   **Stories Completed:** 3 (3.1, 3.2, 3.3)
*   **Tests Added:** ~30
*   **Pass Rate:** 100% (with 1 skipped test for env reasons)
*   **Critical Pivots:** 1 (Rive -> CustomPaint)

## 7. Conclusion
Epic 3 is complete. We have a working Catalog and a powerful Visibility Graph. The foundation is solid. The key takeaway for Epic 4 is to **visualize early and often** - running the app is as important as running the tests.
