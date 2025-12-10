# Product Brief: Astr

**Date:** 2025-11-28
**Author:** Vansh
**Context:** Personal/Startup

---

## Executive Summary

Astr is a stargazing planner application designed to simplify the astronomy experience. It adopts a **Direct Answer philosophy** (delivering quick, clear answers), while retaining a distinct, premium stargazing aesthetic. Astr provides a clean, visual dashboard that answers the core question: "Is tonight good for stargazing?" It leverages Flutter for high-performance visuals and adopts a hybrid distribution strategy (Android Native + iOS Web PWA) to maximize reach while minimizing costs.

---

## Core Vision

### Problem Statement

Existing stargazing applications, such as "Night Shift," often suffer from information overload. They dump complex technical data (cloud cover percentages, astronomical coordinates, deep sky object details) on the user all at once, making it difficult for casual users to quickly assess stargazing conditions. Users are overwhelmed and struggle to plan their stargazing trips effectively.

### Proposed Solution

Astr solves this by prioritizing **Progressive Disclosure** and **Visual Data**. 
*   **UX Philosophy:** We prioritize **Instant Clarity** (instant "Good/Bad" status, simple hierarchy).
*   **Visual Identity:** The design will be immersive and space-themed, not generic.
*   **Dashboard:** A clean interface with:
    *   **Visual Scales:** A graphical Bortle Scale bar (1-9) and Cloud Cover bar.
    *   **Instant Answers:** A clear status for the selected date and location.
    *   **Hidden Complexity:** Technical details are hidden by default.

### Key Differentiators

*   **UX Simplicity, Premium Look:** Combines instant usability with a stunning, niche-specific stargazing design.
*   **Visual Bortle Scale:** A unique UI element to instantly communicate sky quality.
*   **Hybrid Tech Stack:** Uses Flutter's Impeller engine for superior star map performance (future-proofing) while using a Web PWA strategy to bypass iOS App Store fees initially.

---

## Target Users

### Primary Users

**Casual Stargazers & Planners:** Individuals who enjoy the night sky but aren't professional astronomers. They want to plan a "date night" or a weekend trip.
**Astrophotographers & Professionals:** Serious users who need precise data (exact cloud cover, moon phase, object altitude) to plan imaging sessions and observation nights. They value the "Deep Cosmos" dark mode to preserve night vision.

### User Journey

1.  **Check Status:** User opens Astr and sees a big "Good" or "Bad" indicator for tonight.
2.  **Plan Trip:** User selects a future date and a location (e.g., a campsite).
3.  **Assess Conditions:** User sees the predicted Bortle scale (darkness) and cloud cover visuals for that specific time.
4.  **Explore:** If conditions are good, the user clicks to see which planets or stars are visible.

---

## Success Metrics

*   **User Retention:** Percentage of users who return to the app for planning multiple trips.
*   **Conversion to PWA:** Percentage of iOS web visitors who "Add to Home Screen".
*   **Performance:** Star map animation frame rate (target 60fps via Impeller).

---

## MVP Scope

### Core Features

*   **Visual Dashboard:**
    *   Visual Bortle Scale Bar (1-9).
    *   Visual Cloud Cover Bar.
    *   Moon Phase indicator.
*   **Core Planner:**
    *   Location selection (Auto + Manual).
    *   Date selection.
    *   "Good/Bad" stargazing condition logic.
*   **Basic Astronomy Data:**
    *   List of visible planets and major stars (with progressive disclosure for details).
*   **Distribution:**
    *   Android Native App (Play Store).
    *   iOS Web PWA (via custom HTML landing page).

### Out of Scope for MVP

*   **Interactive Star Map:** Full Stellarium-like navigation (deferred to Phase 2).
*   **"Best Nearby Spots":** Paid feature (deferred to Phase 2).
*   **Real-time Light Pollution Map:** Live satellite data integration.
*   **Community Features:** Social sharing or spot reviews.

### Future Vision

*   **Interactive Star Map:** A fully immersive, GPU-accelerated star map using Flutter's CustomPainter and Impeller engine.
*   **Monetization:** Premium subscription for "Best Nearby Spots" and advanced deep-sky object visibility charts.

---

## Technical Preferences

*   **Framework:** Flutter (Dart).
*   **Rendering:** Impeller (Mobile) / CanvasKit (Web).
*   **Data Sources:** `sweph` (Swiss Ephemeris) for astronomy data; OpenWeatherMap (or similar) for weather.

## Financial Considerations

*   **Budget:** Low. Avoiding $99/year Apple Developer fee initially by using Web PWA for iOS.
*   **Monetization:** Freemium model to fund future development and fees.

---

_This Product Brief captures the vision and requirements for Astr._

_It was created through collaborative discovery and reflects the unique needs of this Personal/Startup project._

_Next: Use the PRD workflow to create detailed product requirements from this brief._
