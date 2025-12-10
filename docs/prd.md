# Astr - Product Requirements Document

**Author:** Vansh
**Date:** 2025-12-03
**Version:** 1.0

---

## Executive Summary

Astr is a stargazing planner app designed to be the ultimate companion for astronomers and enthusiasts. This project is a comprehensive **Brownfield Overhaul** of the existing Flutter application. The primary goal is to transition from a "loosely functioning" prototype to a polished, responsive, and scientifically accurate tool.

The overhaul focuses on three pillars:
1.  **Stability & Performance:** Resolving scroll jank, web freezing, and ensuring 60fps performance.
2.  **Data Integrity:** Fixing cross-platform inconsistencies in Weather and Light Pollution data (specifically the "Rural vs Urban" bug).
3.  **Deep Sky Capabilities:** Expanding the astronomy engine beyond the Solar System to include Stars, Constellations, and Deep Sky Objects (DSOs) with a local, offline-first architecture.

### What Makes This Special

**Offline-First Precision with Premium Aesthetics.**
Unlike competitors that rely heavily on server connections or clunky interfaces, Astr combines a **Dart Native Local Astronomy Engine** with a high-fidelity **"Glass UI"**. It features a unique **Qualitative Condition Engine** that translates complex data (Bortle, Cloud Cover, Moon Phase) into human-readable advice (e.g., "Milky Way Visible"), making astronomy accessible without sacrificing depth.

---

## Project Classification

**Technical Type:** mobile_app
**Domain:** scientific
**Complexity:** medium

**Project Structure:** Multi-part System
-   **Mobile:** Flutter (iOS/Android/Web) - Primary Interface
-   **Backend:** Python/Flask (Vercel) - Data Aggregation & High-Precision Fallbacks

---

## Success Criteria

1.  **Scientific Accuracy:**
    *   **Prime View:** The "Atmospherics Graph" correctly identifies and highlights the optimal viewing window (lowest cloud cover + lowest moon interference) instead of defaulting to the middle.
    *   **Bortle Zones:** Light pollution data matches reality (e.g., Urban users see "Urban" zone), validated against the offline map fallback.
    *   **Object Tracking:** Rise/Set times and Altitude graphs for DSOs match astronomical standards (within reasonable visual tolerance).

2.  **Performance & Stability:**
    *   **Scroll Performance:** 60fps scrolling on all lists (Home, Catalog) despite "Glass UI" effects.
    *   **Web Stability:** Zero freezes/crashes during navigation on the web platform.
    *   **Asset Optimization:** App size remains under 100MB despite high-res assets.

3.  **User Experience:**
    *   **Qualitative Feedback:** Users receive clear, descriptive advice (e.g., "Milky Way Visible") rather than abstract scores.
    *   **Visual Consistency:** Graphs correctly display the "Sunset to Sunrise" window for the selected date.
    *   **First Impression:** High-quality Splash Screen replaces the default loading indicator.

---

## Product Scope

### MVP - Minimum Viable Product

#### 1. Core Astronomy Engine (Offline First)
*   **Local Database:** SQLite/Hive DB containing Yale Bright Star Catalog, Constellations, and Messier Objects.
*   **Calculations:** Dart-based implementation of Meeus algorithms for RA/Dec to Alt/Az conversion.
*   **Timeframe Logic:** Unified "Sunset (Day N) to Sunrise (Day N+1)" logic for all calculations and graphs.

#### 2. Dynamic Graphing System
*   **Atmospherics Graph (Global):**
    *   Displays Cloud Cover and Moon Position.
    *   **Prime View Logic:** New algorithm to calculate and highlight the specific time window where conditions are optimal.
*   **Visibility Graph (Per Object):**
    *   Displays Cloud Cover, Moon Position, and **Object Altitude**.
    *   Dynamic curve based on the object's real-time position in the sky.
    *   **Real-Time Indicator:** Restore the "Current Position" indicator (White circle with Blue/Orange stroke) that moves along the altitude curve to show the object's exact position at the current time.

#### 3. Qualitative Condition Engine
*   **Inputs:** Cloud Cover (%), Moon Phase/Alt, Light Pollution (Bortle).
*   **Outputs:** Human-readable tags (e.g., "Poor", "Fair", "Good", "Excellent") and descriptive text (e.g., "Stars Visible", "Planets Only").
*   **Removal:** Deprecate the arbitrary "66/100" numeric score.

#### 4. Data & Environment
*   **Hybrid Light Pollution:** Online (MongoDB) with accurate Offline Fallback (PNG Map algorithm).
*   **Weather:** Reliable mobile fetching.

#### 5. Visuals & Polish
*   **Splash Screen:** Custom, high-quality splash screen (SVG/Lottie) to replace default loader.
*   **Font:** Satoshi.
*   **Illustrations:** WebP assets for Moon Phases and Sun.
*   **Glass UI Optimization:** Refactor blur/glass effects to ensure 60fps on mobile devices.
*   **Graph Color Logic:**
    *   **Highlights (Home Screen):** Visibility graphs use **Orange** shades.
    *   **Standard (Catalog/Details):** Visibility graphs use **Blue** shades.

#### Non-Functional Requirements

### Performance
*   **NFR1:** Application size must not exceed 100MB.
*   **NFR2:** Cold start time (to Home Screen) should be under 2 seconds (excluding Splash animation duration).
*   **NFR3:** Scroll frame rate must stay above 55fps on mid-range devices (e.g., iPhone 12, Pixel 6).

### Reliability
*   **NFR4:** Offline Astronomy Engine must function with 100% feature parity for calculations (Alt/Az, Rise/Set) without internet.
*   **NFR5:** Light Pollution fallback must match the Online API classification (e.g., Urban vs Rural) with >90% consistency.

### Compatibility
*   **NFR6:** Application must support iOS 15+ and Android 10+.
*   **NFR7:** Web version must be fully responsive and functional on mobile browsers (Safari/Chrome).

### Growth Features (Post-MVP)
*   **AR Sky View:** Augmented reality overlay using device sensors.
*   **Social Sharing:** Share observation plans or "Prime View" alerts.
*   **Telescope Control:** INDI/ASCOM integration.

### Vision (Future)
To become the "Operating System for Stargazing," integrating hardware control, community logs, and advanced astrophotography planning into a single, beautiful glass interface.

---
