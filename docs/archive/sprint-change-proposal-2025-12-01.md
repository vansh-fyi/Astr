# Sprint Change Proposal: Production Polish & Launch (Epic 10)

**Date:** 2025-12-01
**Trigger:** User Feedback (UX gaps, missing backend, logic refinements, production readiness)

## 1. Issue Summary
The current app has a solid UI shell but lacks critical "production-ready" logic and backend infrastructure. Specifically:
- **Backend Missing:** The Vercel/MongoDB backend for light pollution was planned but not implemented in the repo.
- **Logic Gaps:** "Stargazing Quality" is generic; Cloud Cover uses a flawed "Average" logic; Deep Sky Objects (Galaxy/Stars) are missing.
- **UX Gaps:** No "Delete Location", missing Location Name, app shows 24h instead of Night-Only.
- **Performance:** App size and runtime performance need optimization.
- **Monetization:** "Buy Me a Coffee" integration is missing.

## 2. Impact Analysis
- **Epic 2 (Dashboard):** Story 2.4 (Backend Integration) is effectively incomplete without the actual backend code.
- **Epic 8 (Calculations):** Logic needs overhaul to be truly useful.
- **New Scope:** Significant new work required to bridge the gap from "Prototype" to "Product".

## 3. Recommended Approach
**Create New Epic 10: "Production Polish & Launch"**
This consolidates all remaining work into a focused "finishing sprint" to ensure the app is ready for the store.

## 4. Detailed Change Proposals

### New Epic 10: Production Polish & Launch

#### Story 10.1: UX Refinements
**Goal:** Fix specific UX annoyances and align with "Stargazing" context.
- **Tasks:**
  - [ ] Add "Delete" button to Saved Locations list.
  - [ ] Fix Location Name display (Implement OpenStreetMap/Nominatim reverse geocoding).
  - [ ] Implement "Night-Only" Display: Filter all graphs/lists to show only Dusk to Dawn (Sunset to Sunrise).

#### Story 10.2: Logic Overhaul & Deep Sky
**Goal:** Make the data accurate and relevant.
- **Tasks:**
  - [ ] **Cloud Cover:** Remove "Average" logic. Show **Current** condition + "Reload" button to refresh.
  - [ ] **Stargazing Quality:** Implement weighted formula: `(Bortle * 0.4) + (Cloud * 0.4) + (Moon * 0.2)`.
  - [ ] **Deep Sky Objects:** Implement calculations for Galaxies, Stars, and Constellations (currently missing).

#### Story 10.3: Backend Implementation (Vercel + MongoDB)
**Goal:** Build the actual backend infrastructure.
- **Tasks:**
  - [ ] Create `astr-backend` repo (or folder).
  - [ ] Implement Vercel Serverless Functions (Python/Flask).
  - [ ] Setup MongoDB Atlas (Free Tier).
  - [ ] Implement NASA Data Processing script (Offline).
  - [ ] Verify API endpoints (`/api/light-pollution`).

#### Story 10.4: Performance Optimization
**Goal:** Make the app lighter and faster without compromising visuals.
- **Tasks:**
  - [ ] Analyze app bundle size and reduce (asset optimization, tree shaking).
  - [ ] Profile rendering performance (Impeller) and optimize `CustomPainter`s.
  - [ ] Ensure smooth 60fps animations.

#### Story 10.5: Buy Me a Coffee Integration
**Goal:** Allow optional community support.
- **Tasks:**
  - [ ] Wire up the existing "Buy Me a Coffee" button in Settings.
  - [ ] Open In-App Browser or external link to donation page.

#### Story 10.6: Production Release Prep
**Goal:** Get ready for the Store.
- **Tasks:**
  - [ ] Generate Store Screenshots.
  - [ ] Update `version` in `pubspec.yaml`.
  - [ ] Build Release App Bundle (`.aab` / `.ipa`).
  - [ ] Final QA Checklist.

## 5. Implementation Handoff
- **Scope:** Major (New Epic).
- **Route To:** Scrum Master (to create Epic/Stories) -> Developer (to implement).
- **Process:** User will be involved in testing and validation for each story.

