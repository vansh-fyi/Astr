# Product Brief: Astr

**Date:** 2025-12-03
**Project:** Astr (Brownfield Overhaul)

---

## Executive Summary

Astr is a stargazing planner app that aims to be the ultimate companion for astronomers. This project is a comprehensive **Brownfield Overhaul** to address critical stability issues, fix cross-platform data inconsistencies (Weather/Light Pollution), and significantly expand capabilities to include Deep Sky Objects (Stars, Constellations, Nebulae). The goal is to move from a "loosely functioning" prototype to a polished, responsive, and scientifically accurate tool that provides qualitative, human-readable advice (e.g., "Milky Way visible") rather than arbitrary scores.

---

## 1. Problem Statement

The current iteration of Astr faces three core challenges:

1.  **Performance & Stability:** The app suffers from scroll jank, navigation bugs, and severe freezing on the web version. It feels "heavy" (77MB) and unresponsive.
2.  **Data Inconsistency:** Critical data (Weather, Light Pollution/Bortle zones) works on the web/simulator but fails or returns incorrect values on native mobile devices. The "fallback" algorithms for light pollution are inaccurate (showing "Rural" for "Urban" areas).
3.  **Limited Astronomy Engine:** The app currently relies on the Swiss Ephemeris, limiting it to Solar System objects (Planets, Sun, Moon). It lacks data for Stars, Constellations, and Deep Sky Objects (DSOs), making the "Sky Map" and visibility graphs incomplete and static.
4.  **Poor UX on "Conditions":** The current "Visibility Score" (e.g., "66/100") is arbitrary and confusing. Users don't know what it means practically.

---

## 2. Proposed Solution

We will rebuild the core engines of Astr while preserving its unique "Glass UI" aesthetic, with a strict **Offline First** philosophy:

1.  **Dart Native Astronomy Engine:** Implement a local, offline-capable engine (using Yale/Hipparcos catalogs) to calculate real-time positions for Stars, Constellations, and DSOs.
2.  **Robust Hybrid Data Layer:**
    *   **Online:** Fetch high-precision Light Pollution data from the MongoDB/NASA backend.
    *   **Offline Fallback:** Fix the "PNG Fallback" algorithm that calculates light pollution from a local world map (`assets/maps/world2024_low3.png`) to ensure it matches the accuracy of the online source, resolving the "Rural vs Urban" discrepancy.
3.  **Descriptive Visibility System:** Replace the numeric score with a **Qualitative Condition Engine**. It will analyze factors (Moon phase, Cloud cover, Bortle scale) and output human-readable statuses like *"Perfect for Deep Sky"*, *"Planets Only"*, or *"Milky Way Visible"*.
4.  **Optimized Assets:** Implement a strategy for high-quality illustrations (Moon phases, Sun, Stars) using optimized formats (WebP) to keep the app size manageable despite adding rich visuals.

---

## 3. Core Features (MVP Scope)

### A. Deep Sky Object (DSO) Tracking
*   **Database:** Local database of Stars, Constellations, Nebulae, Galaxies, and Clusters.
*   **Calculations:** Accurate Rise/Set times and Alt/Az coordinates for all objects.
*   **Dynamic Graph:** Update the existing `CustomPainter` visibility graph to dynamically reflect the changing visibility of objects based on Earth's rotation, fixing the static graph issue.

### B. Descriptive Conditions UI
*   **Input:** Cloud Cover, Moon Phase/Rise-Set, Light Pollution (Bortle).
*   **Logic:** A formula that translates these inputs into specific viewing categories.
*   **Output:** Clear text labels (e.g., "Good for Clusters") instead of "Score: 66".

### C. Accurate Environment Data (Offline USP)
*   **Weather:** Reliable fetching on mobile devices.
*   **Light Pollution:** Correct Bortle scale identification using the hybrid Online/Offline (PNG Map) system.

### D. Visual Polish & Performance
*   **Typography:** Switch from Nunito to **Satoshi** font for a more modern, premium aesthetic.
*   **Illustrations:** Custom WebP illustrations for celestial bodies (Moon phases, Sun).
*   **Performance:** 60fps scrolling and navigation.
*   **Size Management:** Asset optimization to prevent bloat beyond 100MB.

---

## 4. Target Audience
*   **Amateur Astronomers:** Who need to know *what* they can see tonight.
*   **Astrophotographers:** Who need accurate dark sky predictions.
*   **Casual Stargazers:** Who want a beautiful, easy-to-understand guide to the sky.

---

## 5. Success Metrics
*   **Accuracy:** Bortle zone matches reality (e.g., User in city sees "Urban").
*   **Performance:** No UI freezes on scroll; Web version runs smoothly.
*   **Completeness:** App correctly displays Rise/Set times for non-solar system objects.
*   **Usability:** Users understand the "Conditions" without needing to interpret a number.

---
