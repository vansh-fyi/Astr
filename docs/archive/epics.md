# Epics & Stories: Astr

> **Status:** Draft
> **Based on:** PRD v1.0, Design Spec (Astr Aura)
> **Focus:** User Value & Incremental Delivery

---

## Epic Summary

| Epic | Title | Goal | FR Coverage |
| :--- | :--- | :--- | :--- |
| **1** | **Foundation & Core Data Engine** | Establish the app shell, navigation, and the "Brain" (Astronomy Engine) that powers everything. | FR1, FR2, FR14 (Calc), FR15 (Offline), FR16, FR17 |
| **2** | **The Dashboard ("Is Tonight Good?")** | Deliver the immediate "Good/Bad" answer and visual summary for the current night. | FR3, FR4, FR5 (Theme), FR6, FR7, FR8, FR9 |
| **3** | **Celestial Catalog & Visibility Graph** | Enable deep exploration of objects with the core "Interference Graph" innovation. | FR5 (Catalog), FR6, FR7 (Graph), FR8 (Moon), FR12, FR13 |
| **4** | **Planning & Forecast** | Allow users to look ahead and plan trips for the next 7 days. | FR9, FR10, FR11 (Forecast) |
| **5** | **Profile & Personalization** | Enable customization, night vision protection, and data persistence. | FR11 (Profile), FR12, FR13, FR14 (Red Mode) |
| **6** | **Security & Compliance** | Ensure user safety, legal compliance, and secure API usage. | Security FRs, Legal FRs, Open Source Mandate |

---

## Epic 1: Foundation & Core Data Engine
**Goal:** Establish the app shell, navigation, and the "Brain" (Astronomy Engine) that powers everything.
**Value:** Users have a working app shell that can calculate where stars are, even if the UI is empty.

### Story 1.1: Project Initialization & Navigation Shell
**As a** User,
**I want** to open the app and navigate between the main sections,
**So that** I can access different features easily.

*   **Acceptance Criteria:**
    *   Given the app is launched, then the "Home" tab is active.
    *   When I tap "Celestial Bodies", "Forecast", or "Profile" in the bottom nav, then the view switches instantly.
    *   The Bottom Navigation Bar persists across all views.
    *   The app uses the "Deep Cosmos" (`#020204`) background globally.
    *   **UX Note:** Use `GlassPanel` style for the nav bar (blur effect).
*   **Technical Notes:**
    *   Initialize Flutter project.
    *   Setup `go_router` or equivalent for navigation.
    *   Implement "Astr Aura" theme colors.

### Story 1.2: Astronomy Engine Integration (Swiss Ephemeris)
**As a** System,
**I want** to calculate the precise position of celestial objects for any given time and location,
**So that** the app displays accurate data.

*   **Acceptance Criteria:**
    *   Given a location (Lat/Long) and Time, the system returns Altitude/Azimuth for Sun, Moon, and Planets.
    *   Calculations are performed locally (Offline capable).
    *   **Constraint:** Must use an **Open Source** library (e.g., `sweph` Dart bindings or VSOP87 implementation). NO paid APIs.
*   **Technical Notes:**
    *   Integrate `swisseph` or equivalent Dart package.
    *   Verify accuracy against a known source (e.g., Stellarium).

### Story 1.3: Location & Date Context Manager
**As a** User,
**I want** the app to know my location and the date I'm checking,
**So that** the astronomy data is relevant to me.

*   **Acceptance Criteria:**
    *   Given the app launches, it requests Location Permission ("While Using").
    *   If granted, it detects current GPS coordinates.
    *   If denied, it defaults to a fallback (e.g., Null Island or last known) and prompts for manual entry.
    *   The "Current Date" is set to Now by default.
    *   This Context (Location + Date) is accessible globally by all other widgets.
*   **Technical Notes:**
    *   Use `geolocator` package.
    *   Use `riverpod` or `provider` for global state management.
    *   Use `riverpod` or `provider` for global state management.
    *   **Constraint:** Use OpenStreetMap (Nominatim) for search (implemented in `AddLocationScreen`).
    *   **Constraint:** Allow manual coordinate entry (implemented).

---

## Epic 2: The Dashboard ("Is Tonight Good?")
**Goal:** Deliver the immediate "Good/Bad" answer and visual summary for the current night.
**Value:** Users get the core value ("Can I see stars?") in < 5 seconds.

### Story 2.1: Visual Bortle & Cloud Bars
**As a** User,
**I want** to see the light pollution and cloud cover as visual bars,
**So that** I can understand conditions without reading numbers.

*   **Acceptance Criteria:**
    *   **Bortle Bar:** Visual gradient (1-9). Shows current location's Bortle class.
    *   **Cloud Bar:** Visual fill based on cloud %.
    *   **UX:** Bars animate (fill up) on load (`animate-slide-up`).
    *   **Data:** Fetch Cloud Cover from **Open-Meteo** (Free API).
*   **Technical Notes:**
    *   Proxy Open-Meteo requests through backend (see Epic 6) or use direct client if API key not required (Open-Meteo is free without key for low volume, but check PRD mandate). *Correction: PRD mandates backend proxy for keys, Open-Meteo is keyless for non-commercial, but good practice to wrap.*

### Story 2.2: "Good/Bad" Summary Logic
**As a** User,
**I want** a clear text summary (e.g., "Excellent", "Poor"),
**So that** I don't have to interpret the data myself.

*   **Acceptance Criteria:**
    *   System evaluates: Cloud Cover, Moon Phase, and Bortle Scale.
    *   Returns a simple string: "Excellent", "Good", "Fair", "Poor".
    *   **UI:** Displayed prominently in "Starlight" white font.
    *   **UX:** Text uses `animate-pulse-glow` if "Excellent".

### Story 2.3: Top 3 Highlights Feed
**As a** User,
**I want** to see the top 3 best objects to look at tonight,
**So that** I have an immediate goal.

*   **Acceptance Criteria:**
    *   System filters visible objects (Planets > Stars).
    *   Selects top 3 based on Altitude and Magnitude.
    *   Displays them as cards on the Home screen.
    *   Displays them as cards on the Home screen.
    *   Tapping a card is a placeholder (until Epic 3).

### Story 2.4: Real Bortle Data Integration
**As a** User,
**I want** accurate light pollution data for my exact location,
**So that** the "Stargazing Quality" assessment is reliable.

*   **Acceptance Criteria:**
    *   System fetches real Bortle Scale class (1-9) based on Lat/Long.
    *   **Data Source:** Use a reputable Light Pollution Map API or a compressed local lookup table.
    *   **Fallback:** If offline or API fails, fall back to a reasonable default or cached value.
    *   Updates `BortleProvider` to use this real data source instead of the placeholder.

---

## Epic 3: Celestial Catalog & Visibility Graph
**Goal:** Enable deep exploration with the core "Interference Graph" innovation.
**Value:** Enthusiasts get the deep, accurate data they need to plan specific observations.

### Story 3.1: Celestial Objects Catalog List
**As a** User,
**I want** to browse a list of Planets, Stars, and Constellations,
**So that** I can see what's out there.

*   **Acceptance Criteria:**
    *   Displays list of objects categorized by type (Tabs/Chips).
    *   List items show: Icon, Name, Rise/Set time.
    *   **Data:** Sourced from internal offline database (Open Source catalogs).

### Story 3.2: Object Detail Page Shell
**As a** User,
**I want** to tap an object to see its full details,
**So that** I can learn more about it.

*   **Acceptance Criteria:**
    *   Tapping an object opens a full-screen page.
    *   **UX:** Page background matches the "Astr Aura" theme.
    *   Shows large Title, Type, and basic Magnitude/Distance data.

### Story 3.3: The Universal Visibility Graph (The Core Feature)
**As a** User,
**I want** to see a graph of the object's altitude vs. the moon's interference,
**So that** I can find the "Prime View" window.

*   **Acceptance Criteria:**
    *   **Graph X-Axis:** Time (Now to +12h).
    *   **Graph Y-Axis:** Altitude (0 to 90 deg).
    *   **Curve A:** Object Altitude (Line).
    *   **Curve B:** Moon Altitude/Brightness (Gradient Overlay).
    *   **Logic:** Highlight time ranges where Object > 30° AND Moon is < Horizon (or low phase).
    *   **UX:** Use **CustomPainter** for the graph rendering.
    *   **Interaction:** Touch-drag to scrub time.

    **Graph Spec: `ConditionsGraph` & `AltitudeGraph`**
    *   **ConditionsGraph:** Cloud Cover (Area Chart) + Moon Interference (Block).
    *   **AltitudeGraph:** Object Altitude (Parabola) overlaid on Cloud Cover.
    *   **Design:** Must match `Details.html` pixel-perfectly.
    *   **Current State:** UI implemented (`VisibilityGraphWidget`), logic mocked for Mercury. Needs full implementation.

### Story 3.4: Moon Position Calculations
**As a** User,
**I want** to see Moon altitude, transit, and set times,
**So that** I can plan around moonrise/moonset.

*   **Acceptance Criteria:**
    *   System calculates Moon Altitude (degrees above horizon) for current time.
    *   System calculates Transit time (highest point in sky).
    *   System calculates Set time (when Moon drops below horizon).
    *   Calculations use Swiss Ephemeris (local, offline).
    *   Formula verified against Stellarium or JPL Horizons.
    *   Displayed in Moon card or Object Detail page.
*   **Technical Notes:**
    *   Use existing Swiss Ephemeris integration (Story 1.2).
    *   Research Moon altitude/transit/set calculation (likely `sweph` API methods).

---

## Epic 4: Planning & Forecast
**Goal:** Allow users to look ahead and plan trips.
**Value:** Users can plan for the weekend, not just tonight.

### Story 4.1: 7-Day Forecast List
**As a** User,
**I want** to see a list of the next 7 days with summary conditions,
**So that** I can pick the best night.

*   **Acceptance Criteria:**
    *   Fetches 7-day weather forecast (Open-Meteo).
    *   Calculates Moon Phase for each day.
    *   Displays list: Date + Weather Icon + Star Rating (1-5 stars).

### Story 4.2: Future Date Context Switching
**As a** User,
**I want** to tap a future date to see the full dashboard for that day,
**So that** I can see exactly what will be visible then.

*   **Acceptance Criteria:**
    *   Tapping a day in Forecast switches the Global Date Context to that date.
    *   Navigates user to "Home" (or a Day Detail view) populated with that date's data.
    *   "Top 3" and "Bortle/Cloud" bars update to reflect the future date.

### Story 4.3: Atmospheric Drawer - Cloud Cover Graph
**As a** User,
**I want** to see cloud cover forecast for next 12 hours as a graph,
**So that** I can identify clear windows for observation.

*   **Acceptance Criteria:**
    *   Graph displays Cloud Cover % (0-100) on Y-axis, Time on X-axis.
    *   Data fetched from Open-Meteo hourly forecast (architecture from Story 8.0).
    *   Graph renders using `CustomPainter` (no Rive).
    *   Displayed in Atmospherics sheet/drawer.
    *   Updates when location or date changes.
*   **Technical Notes:**
    *   Open-Meteo endpoint: `/v1/forecast?hourly=cloudcover`.
    *   Use `fl_chart` package or custom painter.

---

## Epic 5: Profile & Personalization
**Goal:** Enable customization and safety.
**Value:** Users can save their spots and protect their eyes.

### Story 5.1: Red Mode (Night Vision)
**As a** User,
**I want** to toggle a red filter over the screen,
**So that** I don't ruin my night vision while stargazing.

*   **Acceptance Criteria:**
    *   Toggle button available in Profile (or global header).
    *   When active, a pure red (`#FF0000`) overlay with `Multiply` or `Overlay` blend mode is applied to the entire app.
    *   **Constraint:** Must persist across navigation.

### Story 5.2: Saved Locations
**As a** User,
**I want** to save my favorite dark sky spots,
**So that** I can check their conditions quickly.

*   **Acceptance Criteria:**
    *   User can "Save" the current manual location.
    *   Profile displays list of "Saved Locations".
    *   Tapping a saved location switches the Global Location Context.
    *   Data stored locally in **Hive** (`locations` box).

---

## Epic 6: Security & Compliance
**Goal:** Ensure safety and legal compliance.
**Value:** Protects the user from harm and the developers from liability.

### Story 6.1: Secure API Proxy (Cloudflare Workers)
**As a** Developer,
**I want** to proxy all third-party API calls through a secure backend,
**So that** API keys are never exposed in the client code.

*   **Acceptance Criteria:**
    *   Setup a **Cloudflare Worker** using **Hono** framework.
    *   Endpoint `GET /api/weather` calls Open-Meteo (or other provider).
    *   Endpoint `GET /api/geocode` calls Geocoding provider.
    *   App points to this backend, not directly to providers.
    *   **Security:** Backend enforces rate limiting and origin checks.
    *   **Error Handling:** Returns standard error format for `Result` type parsing.

### Story 6.2: Terms of Service & Liability Disclaimer
**As a** User,
**I want** to see a disclaimer upon first launch,
**So that** I understand the risks of visiting remote locations.

*   **Acceptance Criteria:**
    *   **First Launch:** Show a mandatory modal/screen.
    *   **Content:** "Astr is not liable for accidents...", "Locations are suggestions only...".
    *   **Action:** User must tap "I Agree" to proceed.
    *   **Persistence:** Store acceptance locally in **Hive** (`settings` box); do not show again.

---

## Epic 8: Calculation Accuracy & Math Transparency
**Goal:** Implement missing calculations with documented formulas and authoritative sources, establish backend architecture for data services.
**Value:** Users trust data accuracy; developer can verify/debug math easily; sustainable backend infrastructure.

### Story 8.0: Backend Architecture Research & Decision ✅ COMPLETED
**As a** Development Team,
**I want** to research and select optimal backend architecture for light pollution and weather data,
**So that** we implement scalable, cost-effective, accurate data services.

*   **Acceptance Criteria:**
    *   ✅ **Research Deliverable:** Document comparing 3 architectures (saved to `docs/backend-architecture-research.md`):
        *   **Option A:** Lorenz Binary Tiles (❌ licensing risk - requires permission)
        *   **Option B:** NASA Black Marble VIIRS (✅ public domain, satellite-grade)
        *   **Option C:** Google Earth Engine (⚠️ requires backend, cloud-only)
    *   ✅ **Comparison Criteria:** Accuracy, latency, cost, offline capability, implementation complexity, maintenance burden
    *   ✅ **Open-Meteo Decision:** Direct client calls for MVP (free tier: 10,000 req/day). Migrate to Cloudflare Workers proxy when >1,000 users.
    *   ✅ **Tech Stack Decision:** **Vercel Serverless (Python 3.12) + MongoDB Atlas (512MB free tier)**
    *   ✅ **Approval:** User (Vansh) approved Vercel + MongoDB architecture (2025-11-30)
*   **Final Architecture Decision:**
    *   **Backend:** Vercel Serverless Functions (Python 3.12, Flask 3.1.2)
    *   **Database:** MongoDB Atlas Free Tier (512MB, 2dsphere geospatial index)
    *   **Data Processing:** Offline monthly job (local Python: h5py 3.15.1, pymongo 4.15.4)
        - Downloads NASA VNP46A2 HDF5 from LAADS DAAC
        - Processes radiance → MPSAS (formula: `12.589 - 1.086 * log(radiance)`)
        - Uploads to MongoDB (pre-computed global 10km grid ~200K coordinates)
    *   **API Endpoint:** `GET /api/light-pollution?lat={lat}&lon={lon}`
    *   **Deployment:** GitHub → Vercel auto-deploy (zero-cost, git push workflow)
    *   **Fallback:** PNG offline map (`assets/maps/world2024_low3.png`) for remote areas
*   **Technical Notes:**
    *   **Cost:** $0/month (Vercel free tier + MongoDB Atlas 512MB free)
    *   **Timeline:** 3-4 days implementation (Phase 1 roadmap in research doc)
    *   **Dependencies:** Flask==3.1.2, pymongo==4.15.4, h5py==3.15.1, numpy


### Story 8.1: Seeing Calculations (Pickering Scale)
**As a** Stargazer,
**I want** to see atmospheric "Seeing" quality,
**So that** I know if conditions are stable for planetary observation.

*   **Acceptance Criteria:**
    *   System calculates Seeing using Pickering scale (web research formula).
    *   Formula documented in code comments with citation.
    *   Unit test validates against known reference value.
    *   UI displays Seeing as 1-10 scale with label (e.g., "Excellent").
*   **Technical Notes:**
    *   Research Pickering Seeing scale formula (likely involves humidity, wind, temperature).
    *   Data sources: Open-Meteo (humidity, wind speed, temperature).

### Story 8.2: Darkness Quality (r^6 Calculation)
**As a** Advanced user,
**I want** to see "Darkness" metric based on r^6 formula,
**So that** I understand combined light pollution + moon interference.

*   **Acceptance Criteria:**
    *   System calculates r^6 Darkness (web research: likely David Lorenz's website implementation).
    *   Formula reverse-engineered from `djlorenz.github.io/astronomy/lp/overlay/dark.html`.
    *   Documented in code with citation.
    *   UI displays as 0-100 scale or qualitative label.

### Story 8.3: Humidity & Temperature Display
**As a** User,
**I want** to see current humidity and temperature,
**So that** I know if dew/frost will form on my equipment.

*   **Acceptance Criteria:**
    *   System fetches Humidity + Temperature from Open-Meteo (architecture from Story 8.0).
    *   Displayed in Atmospheric drawer or Dashboard.
    *   Unit: °C and % (user preference for °F in future).

### Story 8.4: Math Documentation & Validation
**As a** Developer,
**I want** all formulas documented and validated,
**So that** I can verify accuracy and debug issues.

*   **Acceptance Criteria:**
    *   Create `/docs/calculations.md` with all astronomy formulas.
    *   Each formula includes:
        *   Mathematical notation
        *   Code implementation reference (file + line)
        *   Authoritative source (Stellarium, JPL, academic paper)
    *   Unit tests compare outputs to known reference values.

---

## Epic 9: Astronomy Engine & Data Integration (The "Brain" Implementation)
**Goal:** Fill the "Hollow Shell" of the UI with real astronomy calculations and live data.
**Value:** The beautiful UI actually works.

### Story 9.0: Astronomy Engine & Math Research
**As a** Developer,
**I want** to verify the mathematical formulas and libraries for celestial calculations,
**So that** we don't implement incorrect physics.

*   **Acceptance Criteria:**
    *   **Research Deliverable:** `docs/astronomy-engine-research.md`.
    *   **Evaluate Libraries:** Compare `swisseph` (C++ bindings) vs `calc` (Pure Dart) vs `hrk_nasa_apis`.
    *   **Define Formulas:**
        *   Rise/Set/Transit time algorithm.
        *   Altitude/Azimuth calculation (Ra/Dec + Time + Lat/Long).
        *   Parabolic Curve generation for the Visibility Graph.
    *   **Data Mapping:** Map Open-Meteo fields to `DailyForecast` UI requirements.

### Story 9.1: Universal Rise/Set & Altitude Engine
**As a** User,
**I want** accurate Rise, Set, and Transit times for ANY object,
**So that** the "Details" page isn't empty.

*   **Acceptance Criteria:**
    *   Implement `AstronomyEngine` class (Singleton/Provider).
    *   **Input:** Lat, Long, DateTime, Object Coordinates (RA/Dec).
    *   **Output:** Altitude, Azimuth, Rise Time, Set Time, Transit Time.
    *   **Math:** Use `swisseph` (Swiss Ephemeris) or high-accuracy VSOP87 algorithms.
    *   **Integration:** Connect to `ObjectDetailScreen` to replace `-- : --` placeholders.

### Story 9.2: Visibility Graph Math (The Parabola)
**As a** User,
**I want** the Visibility Graph to show the *actual* path of the object tonight,
**So that** I can plan my observation.

*   **Acceptance Criteria:**
    *   Calculate Object Altitude every 15 minutes for the next 12 hours.
    *   Calculate Moon Altitude & Phase for the same intervals.
    *   **Logic:** Generate `List<GraphPoint>` for the `VisibilityGraphPainter`.
    *   **Integration:** Replace the "Mercury Mock" in `VisibilityGraphNotifier` with real engine calls.

### Story 9.3: Forecast Data Wiring
**As a** User,
**I want** the 7-Day Forecast to show real weather and moon phases,
**So that** I can trust the "Excellent/Good/Poor" ratings.

*   **Acceptance Criteria:**
    *   Connect `ForecastScreen` to `WeatherRepository`.
    *   Fetch 7-day forecast from Open-Meteo API.
    *   Calculate Moon Phase for each day.
    *   Apply "Good/Bad" logic (Story 2.2) to generate Star Ratings (1-5).
    *   **UI:** Ensure the "Segmented Bar" rating UI is populated correctly.

### Story 9.4: Location Persistence & Global Context
**As a** User,
**I want** my manually added locations to be saved and selectable,
**So that** I can switch contexts easily.

*   **Acceptance Criteria:**
    *   Refactor `AddLocationScreen` to save to `Hive` (via `SavedLocationsProvider`).
    *   Ensure `AstrContextProvider` listens to the selected location.
    *   Verify that changing location updates the Home Dashboard and Forecast immediately.


---

## Epic 10: Production Polish & Launch
**Goal:** Finalize the app for store release, addressing UX gaps, logic accuracy, backend infrastructure, and performance.
**Value:** Transforms the "Prototype" into a "Product" ready for real users.

### Story 10.1: UX Refinements
**As a** User,
**I want** a polished, frustration-free experience,
**So that** I enjoy using the app without annoyances.

*   **Acceptance Criteria:**
    *   **Delete Location:** "Saved Locations" list has a delete button/swipe action.
    *   **Location Name:** App displays the actual city/place name (Reverse Geocoding via OpenStreetMap/Nominatim) instead of just coordinates.
    *   **Night-Only Mode:** All graphs and lists filter data to show ONLY Dusk to Dawn (Sunset to Sunrise). 24h view is removed or hidden.
    *   **Constraint:** Reverse geocoding must use a free/open API (Nominatim) with proper attribution.

### Story 10.2: Logic Overhaul & Deep Sky
**As a** Stargazer,
**I want** accurate, relevant data including Deep Sky Objects,
**So that** I can plan serious observation sessions.

*   **Acceptance Criteria:**
    *   **Cloud Cover:** Remove "Average" logic. Display **Current** condition. Add a manual "Reload" button to refresh data.
    *   **Stargazing Quality:** Implement weighted formula: `Score = (Bortle * 0.4) + (Cloud * 0.4) + (Moon * 0.2)`.
    *   **Deep Sky Objects:** Calculate and display visibility for Galaxies, Stars, and Constellations (previously missing).
    *   **Validation:** Verify calculations against Stellarium.

### Story 10.3: Backend Implementation (Vercel + MongoDB)
**As a** Developer,
**I want** the actual backend infrastructure running,
**So that** the app stops relying on client-side mocks or direct API calls where inappropriate.

*   **Acceptance Criteria:**
    *   **Repo:** Create `astr-backend` (or `backend` folder) with Python/Flask project.
    *   **Infrastructure:** Deploy Vercel Serverless Functions. Setup MongoDB Atlas (Free Tier).
    *   **Data:** Implement offline Python script to process NASA VNP46A2 HDF5 data and populate MongoDB.
    *   **API:** Expose `GET /api/light-pollution` endpoint.
    *   **Verification:** Verify Story 2.4's client integration against this real backend. Verify PNG fallback works when backend is unreachable.

### Story 10.4: Performance Optimization
**As a** User,
**I want** the app to be light and fast,
**So that** it runs smoothly on my device without draining battery.

*   **Acceptance Criteria:**
    *   **Bundle Size:** Analyze and reduce app size (target < 50MB Android, < 100MB iOS).
    *   **Rendering:** Profile `CustomPainter` performance. Ensure consistent 60fps.
    *   **Optimization:** Implement tree-shaking and asset optimization.

### Story 10.5: Buy Me a Coffee Integration
**As a** Developer,
**I want** to allow users to support the project,
**So that** I can cover basic hosting costs.

*   **Acceptance Criteria:**
    *   **Settings:** "Buy Me a Coffee" button is functional.
    *   **Action:** Opens external link or in-app browser to donation page.
    *   **Style:** Unobtrusive, fits "Astr Aura" theme.

### Story 10.6: Production Release Prep
**As a** Team,
**I want** to prepare the artifacts for store submission,
**So that** we can launch.

*   **Acceptance Criteria:**
    *   **Screenshots:** Generate high-quality store screenshots for Android/iOS.
    *   **Versioning:** Bump version in `pubspec.yaml` (e.g., 1.0.0).
    *   **Build:** Generate Release App Bundle (`.aab`) and IPA.
    *   **QA:** Pass final "Pre-Flight" QA checklist.
