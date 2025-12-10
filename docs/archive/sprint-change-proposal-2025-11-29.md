# Sprint Change Proposal: Design System Unification & Rive Removal

**Date:** 2025-11-29
**Trigger:** User Feedback (Inconsistent UI, Rive performance issues)

## 1. Issue Summary
**Problem:** The application lacks a unified design system. The "Home Screen" aesthetic (Glassmorphism, Nebula, Deep Cosmos) is the desired standard, but other screens (Catalog, Details) deviate. Additionally, Rive has proven problematic for performance/implementation ease in the graphs, and the user requested its removal (except potentially for the future Star Map).

**Context:** User review of the current build revealed significant visual inconsistencies and dissatisfaction with the Rive workflow.

## 2. Impact Analysis
*   **Epics Affected:**
    *   **Epic 3 (Celestial Catalog):** Story 3.3 (Visibility Graph) explicitly mandates Rive. This needs to change to `CustomPainter`.
    *   **Epic 2 (Dashboard):** Needs to be the "Gold Standard" for design.
    *   **All Epics:** Must enforce the "Home Screen Aesthetic".
*   **Artifacts:**
    *   `PRD.md`: Remove Rive from core tech stack/innovations (except Star Map).
    *   `epics.md`: Rewrite Story 3.3 to remove Rive.
    *   `design-spec.md`: Explicitly define the Home Screen as the visual source of truth.

## 3. Recommended Approach
**Direct Adjustment (Batch):** Update all documentation immediately to reflect the new direction. This ensures future development (and current refactoring) aligns with the user's vision.

## 4. Detailed Change Proposals

### A. PRD.md Updates

#### [MODIFY] Section: Innovation & Novel Patterns
**OLD:**
> *   **Rive Animations:** Using Rive for high-performance, interactive vector animations (Graphs, Star Map) with real-time data binding.

**NEW:**
> *   **Custom Canvas Graphs:** High-performance, pixel-perfect rendering of the "Interference Graph" using Flutter's `CustomPainter`.
> *   **Rive Animations (Star Map Only):** (Future) Potential use of Rive for the AR Star Map, subject to performance review.

#### [MODIFY] Section: Non-Functional Requirements (Performance)
**OLD:**
> *   **Animation:** 60fps for all visual scales and future star maps (Rive).

**NEW:**
> *   **Animation:** 60fps for all visual scales and graphs (Impeller/CustomPainter).

### B. epics.md Updates

#### [MODIFY] Story 3.3: The Universal Visibility Graph
**OLD:**
> *   **UX:** Use **Rive** for the graph animation and interaction.
> *   **Data Binding:** Bind Time/Altitude values to Rive state machine inputs.
>
> **Rive Spec: `visibility_graph.riv`**
> ...

**NEW:**
> *   **UX:** Use **CustomPainter** for the graph rendering.
> *   **Interaction:** Touch-drag to scrub time.
>
> **Graph Spec: `ConditionsGraph` & `AltitudeGraph`**
> *   **ConditionsGraph:** Cloud Cover (Area Chart) + Moon Interference (Block).
> *   **AltitudeGraph:** Object Altitude (Parabola) overlaid on Cloud Cover.
> *   **Design:** Must match `Details.html` pixel-perfectly.

### C. design-spec.md Updates

#### [ADD] Section 1: Design Philosophy
**NEW:**
> *   **Unified Consistency:** The **Home Screen** is the visual source of truth. All drawers, sheets, and screens MUST use the exact same `GlassPanel`, `NebulaBackground`, and Typography as the Home Screen. No deviations.

#### [MODIFY] Section 5: Component Library
**OLD:**
> | `VisibilityChart` | `CustomPaint`. Layers: StarBG, CloudPath, MoonRect, ObjectPath. |

**NEW:**
> | `ConditionsGraph` | `CustomPaint`. Cloud Cover Area + Moon Block. (For Atmospherics). |
> | `AltitudeGraph` | `CustomPaint`. Object Parabola + Cloud Background. (For Celestial Details). |

## 5. Implementation Handoff
*   **Scope:** **Minor/Moderate**. The code changes are largely done (I already refactored the graphs to CustomPainter), but the documentation needs to catch up to prevent regression.
*   **Action:**
    1.  Apply edits to `PRD.md`, `epics.md`, and `design-spec.md`.
    2.  Continue development with strict adherence to the new Design System.

---
**Approval Request:**
Do you approve these changes to the project documentation?
