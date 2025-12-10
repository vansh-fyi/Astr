# Astr - Product Requirements Document

**Author:** Vansh
**Date:** 2025-11-28
**Version:** 1.0

---

## Executive Summary

Astr is a stargazing planner application designed to simplify the astronomy experience. It adopts a **Direct Answer philosophy** (delivering quick, clear answers), while retaining a distinct, premium stargazing aesthetic. Astr provides a clean, visual dashboard that answers the core question: "Is tonight good for stargazing?" It leverages Flutter for high-performance visuals and adopts a hybrid distribution strategy (Android Native + iOS Web PWA) to maximize reach while minimizing costs.

### What Makes This Special

**Emotional Dual-Core:**
*   **For Beginners:** A sense of **Relief and Clarity**. "I don't need to be an astrophysicist to know if I can see stars tonight."
*   **For Beginners:** A sense of **Relief and Clarity**. "I don't need to be an astrophysicist to know if I can see stars tonight."
*   **For Enthusiasts:** A sense of **Awe**. Deep, information-rich data presented with immersive, premium visuals.
*   **For Pros & Photographers:** A sense of **Precision**. Accurate ephemeris data, cloud layers, and visibility windows for planning the perfect shot.

**Key Differentiator:** The **Visual Dashboard** (Bortle Scale, Cloud Bars) & Progressive Disclosure. We hide the math to show the magic.

---

## Project Classification

**Technical Type:** mobile_app
**Domain:** consumer_scientific
**Complexity:** medium

**Project Type Analysis:**
*   **Mobile App (Flutter):** Native Android + Web PWA for iOS.
*   **Consumer Focus:** Needs extreme usability and polish.
*   **Scientific Data:** Requires accurate astronomical calculations (Swiss Ephemeris) and weather data.

### Domain Context

*   **Astronomy:** Requires precision (ephemeris data), location awareness (GPS/Bortle), and clear handling of complex terminology (Magnitude, Phase, Azimuth).
*   **Weather:** Real-time and forecasted cloud cover is critical.

---

## Success Criteria

*   **User Clarity:** A beginner can open the app and know "Is tonight good?" within 5 seconds.
*   **Visual Engagement:** Users describe the app as "beautiful" or "immersive" (qualitative).
*   **Performance:** Star map/visuals render at 60fps on mid-range devices (Flutter Impeller).
*   **Retention:** Users return to plan trips or check the moon phase weekly.

### Business Metrics

*   **Conversion to PWA:** % of iOS web visitors who "Add to Home Screen".
*   **CAC (Customer Acquisition Cost):** Kept low via organic search (HTML landing page) and word-of-mouth.
*   **Freemium Conversion:** (Future) % of users upgrading for "Best Nearby Spots".

---

## Product Scope

### MVP - Minimum Viable Product

**The "Is Tonight Good?" Dashboard**
*   **Visual Dashboard:**
    *   **Visibility Scale:** 5-segment visual bar with Zone indicator card (e.g., "Zone 4 - Rural") showing light pollution quality.
    *   **Cloud Cover Bar:** Visual representation of cloudiness.
    *   **Moon Phase:** Visual indicator.
    *   **"Good/Bad" Status:** Instant text summary based on conditions.

**Trip Planner Mode**
*   **Dedicated Planning Flow:** A screen/mode to check conditions for a *specific* future trip.
*   **Location Picker:** Search and select remote locations (e.g., "Joshua Tree", "Cherry Springs").
*   **Date Slider:** Check conditions for upcoming dates (up to 7 days).
*   **Save Trip:** (Optional for MVP) Save a location as a "Favorite" for quick checking.

**Basic Data:**
*   Visible Planets/Stars list (Click to reveal details).
*   **Platform:**
    *   Android (Play Store).
    *   iOS (Web PWA).
    *   SEO Landing Page (HTML).

### Growth Features (Post-MVP)

*   **Interactive Star Map:** Full AR-style navigation using device sensors (Gyroscope, Magnetometer, Accelerometer) to overlay stars on the real sky.
*   **Smart Location Suggestions:** "Best Nearby Spots" feature that actively suggests optimal dark-sky locations based on the user's current position and light pollution maps.
*   **Notifications:** "ISS Passing", "Meteor Shower Tonight".

### Vision (Future)

*   **Smart Telescope Integration:** Control hardware.
*   **Real-time Light Pollution:** Live satellite data.
*   **Community:** Spot reviews and social sharing.

---

## Domain-Specific Requirements

*   **Accuracy:** Ephemeris data must be precise. Users will travel based on this info.
*   **Location Privacy:** Location data is used for calculation but must be handled securely.
*   **Offline Capability:** Stargazing often happens in remote areas with poor signal. Core data (stars/planets) should work offline if possible; weather needs connection.

---

## Innovation & Novel Patterns

*   **Visual Bortle Scale:** Transforming a technical scale (1-9) into an intuitive visual gradient/bar.
*   **Weather + Astro Fusion:** Contextual display of clouds *over* star visibility.
*   **Custom Canvas Graphs:** High-performance, pixel-perfect rendering of the "Interference Graph" using Flutter's `CustomPainter`.
*   **Custom Canvas Rendering:** High-performance graphs (Visibility Graph, Cloud Cover Graph) use Flutter's `CustomPainter` for pixel-perfect control.

### Validation Approach

*   **TypeScript Prototype:** User will provide a high-fidelity interactive prototype built in TypeScript (exported from Figma/Design tool).
*   **Migration Strategy:** The development phase must analyze this TypeScript code to extract design tokens, animations, and logic, then port them pixel-perfectly to Flutter widgets.
*   **User Testing:** Ask beginners "Is tonight good?" and time their response.

---

## mobile_app Specific Requirements

### Platform Support

*   **Android:** Native App (APK/AAB). Min SDK 24+.
*   **iOS:** Progressive Web App (PWA). Must support "Add to Home Screen" and offline caching.
*   **Web:** Responsive design for the PWA to work on desktop/mobile browsers.
*   **Development Source:** Primary UI/UX reference will be the provided TypeScript prototype. Code migration (vanilla HTML JS -> Dart) is required for the initial build.

### Device Capabilities

*   **GPS:** Required for accurate location-based astronomy.
*   **Sensors:** Compass/Gyroscope (Future for Star Map AR).
*   **GPU:** Impeller engine usage for smooth rendering.

---

## User Experience Principles

*   **Instant Clarity:** Instant answers. No digging.
*   **Deep Cosmos Atmosphere:** Interface uses a persistent "Deep Cosmos" (Dark) theme globally to reflect the night sky and preserve night vision.
*   **Red Mode (Night Vision):** An optional, toggleable "Red Filter" overlay that turns the entire UI red to preserve the user's dark adaptation during stargazing.
*   **Premium Aesthetic:** Vibrant, neon/space accents. Glassmorphism.
*   **Progressive Disclosure:**
    *   Level 1: "Good/Bad" + Visual Bars.
    *   Level 2: List of objects.
    *   Level 3 (Click): Detailed Object Page with interactive graphs (Altitude vs. Time, Visibility Window).

### Key Interactions

*   **Dashboard Load:** Smooth animation of bars filling up.
*   **Date Change:** Swipe or easy picker to see future predictions.
*   **Object Detail:** Bottom sheet or modal expansion for technical data.

---

## Navigation & App Structure

The app utilizes a persistent **Bottom Navigation Bar** with four core sections:

1.  **Home:** The "Is Tonight Good?" dashboard.
    *   **Highlights:** Lists the **Top 3** best celestial bodies visible tonight.
    *   **Dashboard:** Visual Bortle, Cloud Cover, and Moon Phase indicators.
2.  **Celestial Bodies:** A comprehensive catalog of the night sky.
    *   **Categories:** Sub-categorized into Planets, Galaxies, Star Clusters, and Constellations.
    *   **Detail View:** Tapping an object opens a full detail page (see "Universal Visibility Graph" below).
3.  **7-Day Forecast:** Weekly planning view.
    *   **List View:** High-level forecast for the next 7 days.
    *   **Day Detail:** Tapping a day opens a detailed dashboard for that specific date (mirroring the Home screen layout).
4.  **Profile:** User personalization (Optional).
    *   **Data:** Save settings and favorite locations.
    *   **Privacy:** Completely optional; app works fully without it.

### Universal Visibility Graph (The "Interference Logic")
A core feature of the **Object Detail Page**.
*   **Concept:** Visualizes *when* an object is best seen by plotting its **Altitude** against **Moon Interference**.
*   **Moon Logic:** The Moon's graph is always overlaid to show when its light washes out the object.
*   **Result:** Clearly highlights the "Prime Viewing Window" where the object is high and the moon is low/dim.

---

## Functional Requirements

**Navigation & Structure**
*   FR1: Users can navigate between Home, Celestial Bodies, 7-Day Forecast, and Profile via a persistent bottom navigation bar.
*   FR2: The currently selected Location and Date context persists across all tabs.

**Home Screen (Dashboard)**
*   FR3: Users can view the "Top 3" best celestial objects visible for the selected night.
*   FR4: Users can view the "Good/Bad" stargazing summary, Bortle Scale, Cloud Cover, and Moon Phase.

**Celestial Bodies (Catalog)**
*   FR5: System uses a persistent "Deep Cosmos" (Dark) theme globally to preserve night vision and brand identity.
*   FR6: Users can browse celestial objects categorized by Type (Planets, Galaxies, Star Clusters, Constellations).
*   FR7: Users can tap an object to view its **Object Detail Page**.
*   FR8: **Object Detail Page** displays the "Universal Visibility Graph":
    *   Plots Object Altitude vs. Time.
    *   Plots Moon Altitude/Phase vs. Time (Interference).
    *   Highlights the optimal viewing window.
*   FR9: Moon Detail Page specifically highlights its phase and rise/set times (as it is the interference source).

**7-Day Forecast**
*   FR10: Users can view a 7-day weather/visibility forecast list.
*   FR11: Users can tap a specific day to view a detailed dashboard (same layout as Home) for that future date.

**Profile & Settings**
*   FR11: Users can optionally create a profile to sync data.
*   FR12: Users can save settings and favorite locations locally (default) or to the profile (if signed in).
*   FR13: Users can switch between Metric and Imperial units.
*   FR14: Users can toggle a "Red Filter" (Night Mode) to preserve night vision.

**System & Data**
*   FR15: System calculates celestial positions and moon interference using accurate ephemeris data.
*   FR15.1: **Light Pollution Data Sources** — System supports multiple light pollution data sources with fallback strategy:
    *   **Primary:** David Lorenz Binary Tiles (`.dat.gz` from `djlorenz.github.io/astronomy/lp/overlay/dark.html`) — High precision, cacheable
    *   **Fallback (Offline):** PNG Map (`world2024_low3.png`) — Bundled, equirectangular projection, low precision
    *   **Future Alternatives:** NASA Black Marble VIIRS (HDF5, Python backend), Google Earth Engine (VNP46A2 collection, cloud API)
    *   **Acceptance:** App attempts Binary Tiles first, falls back to PNG if network unavailable
*   FR15.2: **Location Permission Enforcement** — App MUST request location permission on first launch. If denied, prompt manual location entry.
*   FR15.3: App functions fully offline for catalog and ephemeris data (weather requires connection).
*   FR16: Android users can install the app natively.
*   FR17: iOS users can add the web app to their home screen (PWA).

---

### Data Sources & APIs (Cost Constraint)

*   **Mandate:** All data sources, libraries, and APIs must be **Open Source** and **Free of Cost** to ensure sustainability and zero operating costs for the MVP.
*   **Location:** Use free geocoding services (e.g., Open-Meteo Geocoding API, OpenStreetMap).
*   **Weather:** Use free weather APIs (e.g., Open-Meteo).
*   **Ephemeris & Astronomy:** Use open-source calculation libraries (e.g., Swiss Ephemeris, VSOP87 implementation in Dart) rather than paid APIs.
*   **Catalogs:** Use open public datasets for Messier objects, stars, and galaxies (e.g., NGC, Yale Bright Star Catalog).

---

## Non-Functional Requirements

### Performance

*   **App Launch:** < 2 seconds to dashboard.
*   **Animation:** 60fps for all visual scales and graphs (Impeller/CustomPainter).
*   **Battery:** Minimal drain (GPS only when needed).

### Math Transparency

*   **Requirement:** All astronomical calculations must be documented with formulas and authoritative sources.
*   **Implementation:**
    *   Inline code comments cite formulas (e.g., "Pickering Seeing Scale: S = k * (FWHM)^-0.6")
    *   README or `/docs/calculations.md` documents complex algorithms
    *   Unit tests validate against known reference values (Stellarium, JPL Horizons)
*   **Rationale:** User has astronomy background; must verify calculation accuracy.

### Security

*   **Location:** Request "While Using App". Do not store history unless user saves a "Favorite Spot".
*   **API Protection:** All third-party API keys (Weather, Maps, etc.) must be stored securely on the backend (server-side). The client (app) must NEVER directly access these APIs using keys; it should proxy requests through our secure backend to prevent key theft and quota abuse.

### Legal & Liability

*   **Risk Disclaimer:** The app must include a mandatory "Terms of Service" acceptance flow upon first launch.
*   **Location Safety:** For the "Best Nearby Spots" feature, the app must display a prominent warning: *"Astr provides location suggestions based on light pollution data only. We do not verify the safety, accessibility, or legality of these locations. Users are solely responsible for their own safety and must exercise caution."*
*   **No Liability:** The Terms of Service must explicitly state that Astr and its developers are not liable for any accidents, injuries, or damages occurring at suggested locations.

### Scalability

*   **Weather API:** Caching strategy to minimize API calls (cost control).

### Accessibility

*   **Contrast:** High contrast text (white on black).
*   **Text Size:** Respect system font scaling.

---

_This PRD captures the essence of Astr - A beautiful, simple stargazing planner._

_Created through collaborative discovery between Vansh and AI facilitator._
