# Astr - Epics and Stories

**Status:** Draft
**Version:** 1.0

---

## Epic 1: Foundation & Offline Engine Overhaul 🏗️

**Goal:** Replace the limited `sweph` dependency with a robust, offline-first Dart Native Astronomy Engine and ensure data integrity for Weather and Light Pollution.

**Constraint:** **Preserve existing UI.** Changes should be strictly limited to the Data and Domain layers.

### Story 1.1: Dart Native Engine Implementation
**User Story:** As a developer, I want a pure Dart implementation of astronomical algorithms so that the app can calculate star/DSO positions offline without heavy external dependencies.
**Acceptance Criteria:**
*   **Given** a target celestial object (RA/Dec) and observer location, **When** `calculatePosition()` is called, **Then** it returns Altitude/Azimuth accurate to within 1 degree of verified sources (e.g., Stellarium).
*   **Given** a date, **When** `calculateRiseSet()` is called, **Then** it returns accurate Rise, Transit, and Set times.
*   **Technical Note:** Port Meeus algorithms. Remove `sweph` dependency. **Use Dart Isolates** for all heavy calculations to prevent UI jank. Implement **Result Pattern** for error handling.

### Story 1.2: Local Database Integration
**User Story:** As a user, I want access to a vast catalog of stars and deep sky objects even when offline.
**Acceptance Criteria:**
*   **Given** the app is offline, **When** I search for "Andromeda", **Then** the app retrieves data from the local SQLite/Hive database.
*   **Database Content:** Must include Yale Bright Star Catalog (>9000 stars), Constellations, and Messier Objects.
*   **Technical Note:** Use **SQLite (`sqflite`)**. Schema must include `stars` (id, hip_id, ra, dec, mag) and `dso` tables. Ship as pre-populated `assets/db/astr.db`.

### Story 1.3: Hybrid Light Pollution Logic
**User Story:** As a user, I want accurate light pollution data (Bortle Scale) regardless of my connection status.
**Acceptance Criteria:**
*   **Given** online connectivity, **When** location is updated, **Then** fetch Bortle data from the MongoDB API.
*   **Given** NO connectivity (or API failure), **When** location is updated, **Then** fallback to the "Pixel Map" algorithm using the local `world2024_low3.png`.
*   **Fix:** Ensure the fallback algorithm correctly maps Lat/Long to pixel coordinates. Use **WebP Lossless** format for `world_lp.webp` to minimize size while retaining exact pixel values.

### Story 1.4: Reliable Weather Fetching
**User Story:** As a user, I want to see accurate cloud cover and seeing data for my location.
**Acceptance Criteria:**
*   **Given** the app is open, **When** weather refreshes, **Then** it successfully fetches data on native mobile devices (iOS/Android).
*   **Fix:** Resolve any HTTP client issues causing failures on mobile (e.g., CORS, SSL, or background fetch restrictions).

---

## Epic 2: Dynamic Graphing System Enhancements 📈

**Goal:** Upgrade the existing `CustomPainter` graphs to support "Prime View" logic, real-time indicators, and correct timeframes, while maintaining the current visual style.

**Constraint:** **Preserve Graph UI Style.** Enhance the *logic* and *drawing parameters*, do not redesign the look.

### Story 2.1: Standardize Graph Timeframes
**User Story:** As a user, I want all graphs to show the relevant observing night (Sunset to Sunrise).
**Acceptance Criteria:**
*   **Given** a selected date (e.g., Dec 3), **When** any graph is rendered, **Then** the X-axis spans from Sunset on Dec 3 to Sunrise on Dec 4.
*   **Fix:** Ensure this logic is consistent across Atmospherics and Visibility graphs.

### Story 2.2: Atmospherics Graph & Prime View
**User Story:** As a user, I want to know the absolute best time to observe tonight.
**Acceptance Criteria:**
*   **Given** cloud cover and moon data, **When** the Atmospherics graph renders, **Then** calculate the "Prime View" window (Min Cloud + Min Moon).
*   **Visual:** Highlight this window on the graph using the existing style (e.g., subtle background highlight or distinct marker) without breaking the UI.
*   **Fix:** Ensure the "Now" indicator (Orange line) is accurate.

### Story 2.3: Visibility Graph Indicators
**User Story:** As a user, I want to see exactly where an object is in the sky right now on the graph.
**Acceptance Criteria:**
*   **Given** a Visibility Graph, **When** rendered, **Then** draw a "Current Position" indicator (White circle with colored stroke) on the altitude curve at the current time.
*   **Logic:** The indicator must move in real-time along the curve.
*   **Coloring:** Use **Orange** stroke for Home Screen highlights, **Blue** stroke for Catalog/Details views.

---

## Epic 3: Qualitative Conditions & Visual Polish ✨

**Goal:** Refine the user experience with descriptive conditions, optimized performance, and asset updates, strictly adhering to the "Glass UI" language.

**Constraint:** **Zero Layout Changes.** Optimizations must be internal. Asset swaps must fit existing containers.

### Story 3.1: Qualitative Condition Engine
**User Story:** As a user, I want clear advice like "Milky Way Visible" instead of a vague number.
**Acceptance Criteria:**
*   **Given** environmental factors (Bortle, Cloud, Moon), **When** the Home Screen loads, **Then** display a text-based condition summary (e.g., "Excellent - Great for Galaxies").
*   **UI Update:** Replace the "66/100" text widget with this new descriptive text widget, keeping the same font size/weight hierarchy.

### Story 3.2: Glass UI Performance Optimization
**User Story:** As a user, I want the app to scroll smoothly (60fps) on my phone.
**Acceptance Criteria:**
*   **Given** a list with Glass cards, **When** scrolling, **Then** the frame rate remains >55fps on target devices.
*   **Technical Note:** Refactor `BackdropFilter` usage. **Offload all heavy astronomy math to Isolates** (as per Story 1.1) to free up the UI thread for rendering.

### Story 3.3: Asset & Typography Update
**User Story:** As a user, I want a polished visual experience with consistent fonts and icons.
**Acceptance Criteria:**
*   **Font:** Replace Nunito with **Satoshi** globally. Ensure weights/sizes map correctly to preserve hierarchy.
*   **Icons:** Integrate high-quality WebP assets for Moon Phases and Sun, replacing current placeholders.
*   **Splash:** Implement the new SVG/Lottie splash screen.

### Story 3.4: Manual Testing Fixes
**User Story:** As a developer, I want to address issues found during manual testing to ensure a stable release.
**Acceptance Criteria:**
*   **Given** a list of bugs identified during manual testing, **When** fixes are implemented, **Then** they pass regression testing.
*   **Scope:** Includes UI glitches, edge case crashes, and minor usability tweaks found during the QA phase.

### Story 3.5: Production Build
**User Story:** As a release manager, I want to generate a signed production build for deployment.
**Acceptance Criteria:**
*   **Given** the codebase is stable, **When** the build pipeline runs, **Then** it produces a signed APK/AAB and IPA ready for store submission.
*   **Verification:** Build must be installed and verified on a physical device in Release mode.

---

## FR Coverage Matrix

| FR ID | Description | Epic | Story |
| :--- | :--- | :--- | :--- |
| FR1 | Local Database (Stars/DSOs) | Epic 1 | 1.2 |
| FR2 | Real-time Alt/Az Calc | Epic 1 | 1.1 |
| FR3 | Rise/Set/Transit Calc | Epic 1 | 1.1 |
| FR4 | Sunset-to-Sunrise Window | Epic 2 | 2.1 |
| FR5 | Atmospherics Graph | Epic 2 | 2.2 |
| FR6 | Prime View Logic | Epic 2 | 2.2 |
| FR7 | Visibility Graph | Epic 2 | 2.3 |
| FR8 | Real-Time Indicator | Epic 2 | 2.3 |
| FR9 | Context-aware Coloring | Epic 2 | 2.3 |
| FR10 | Qualitative Status | Epic 3 | 3.1 |
| FR11 | Descriptive Advice | Epic 3 | 3.1 |
| FR12 | "Now" Indicator | Epic 2 | 2.2 |
| FR13 | Weather Fetching | Epic 1 | 1.4 |
| FR14 | Hybrid Light Pollution | Epic 1 | 1.3 |
| FR15 | LP Offline Fallback | Epic 1 | 1.3 |
| FR16 | Splash Screen | Epic 3 | 3.3 |
| FR17 | Satoshi Font | Epic 3 | 3.3 |
| FR18 | WebP Illustrations | Epic 3 | 3.3 |
| FR19 | Home Screen Highlights | Epic 2 | 2.3 |
| FR20 | 60fps Performance | Epic 3 | 3.2 |
| FR21 | Glass UI Optimization | Epic 3 | 3.2 |
