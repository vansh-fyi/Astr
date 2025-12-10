# Sprint Change Proposal: API Integration & Layout Recovery
**Date:** 2025-11-30
**Trigger:** User identified that stories are marked "Done" but APIs are missing and layout has issues.

## 1. Issue Summary
**Problem:** A disconnect exists between the tracked status ("Done") and the functional reality ("Mocked/Incomplete"). Specifically, the backend (Cloudflare Workers) and external data sources (Open-Meteo, Light Pollution) have not been integrated, leaving the app in a "shell" state. Additionally, layout regressions have been noted.

**Evidence:**
- User Report: "all stories have been marked complete but I did not get or added any APIs yet"
- Missing Code: No Cloudflare Worker deployment found.
- Missing Code: API clients likely using mock data.

## 2. Impact Analysis
- **Epic 2 (Dashboard):** Stories 2.1 (Bortle/Cloud) and 2.4 (Real Bortle) are functionally incomplete without live data.
- **Epic 4 (Forecast):** Story 4.1 (7-Day Forecast) requires live weather data.
- **Epic 6 (Security):** Story 6.1 (Secure Proxy) is the critical dependency for all above. It is marked done but likely not deployed.
- **Timeline:** Requires an immediate "Integration Phase" before proceeding to further features.

## 3. Recommended Approach
**Strategy:** **Status Correction & Focused Integration.**
Instead of moving forward, we will acknowledge the debt by reverting the status of affected stories to `in-progress` and explicitly adding the missing integration tasks. We will also add a specific story for layout polish.

**Rationale:**
- Honest tracking is essential for the "Done" definition.
- Prevents building on shaky foundations.
- Focuses immediate effort on making the app "Real" (Live Data).

## 4. Detailed Change Proposals

### A. Status Reversion (Sprint Status)
We will manually update `sprint-status.yaml` to reflect the true state:

| Story | Current | New Status | Reason |
| :--- | :--- | :--- | :--- |
| **6.1 Secure API Proxy** | `done` | **`in-progress`** | Backend not deployed/connected. |
| **2.1 Visual Bortle/Cloud** | `done` | **`in-progress`** | Using mocks, needs API integration. |
| **2.4 Real Bortle Data** | `done` | **`in-progress`** | Using mocks, needs API integration. |
| **4.1 7-Day Forecast** | `done` | **`in-progress`** | Using mocks, needs API integration. |

### B. New Story: Layout Polish
**Create Story 7.1: Visual Polish & Layout Fixes**
- **Goal:** Fix the "minor layout problems" reported.
- **Scope:** Review Home, Catalog, and Detail screens on target devices.
- **Status:** `ready-for-dev`

## 5. Implementation Handoff
- **Scope:** **Moderate** (Requires backlog adjustment and focused dev work).
- **Plan:**
    1.  **Approve** this proposal.
    2.  **Agent** updates `sprint-status.yaml` and creates `story-7-1-visual-polish.md`.
    3.  **Dev** starts with Story 6.1 (Backend) -> Then 2.1/4.1 (Frontend Integration).
