# Technical Research Report: Deep Sky & Constellation Algorithms

**Date:** 2025-12-03
**Prepared by:** Vansh
**Project Context:** Astr (Brownfield) - Mobile App (Flutter) + Backend (Python/Flask)

---

## Executive Summary

To overcome the limitations of the Swiss Ephemeris (which only supports Solar System objects), we recommend implementing a **Local Static Object Engine** in Dart. This engine will use a pre-packaged SQLite or Hive database containing Star and Deep Sky Object (DSO) catalogs and perform real-time coordinate conversions using standard astronomical algorithms (Meeus).

### Key Recommendation

**Primary Choice:** **Dart-based Local Engine with SQLite/Hive**

**Rationale:** Stars and DSOs have effectively fixed positions (Right Ascension/Declination). There is no need for a heavy external library to calculate their positions. We only need to convert these fixed coordinates to the user's local sky view (Altitude/Azimuth) using standard trigonometry, which Dart handles efficiently.

**Key Benefits:**

- **Offline Capable:** No internet connection required for sky charts.
- **High Performance:** optimized for mobile; no heavy C++ FFI overhead for simple star charts.
- **Full Control:** We own the data structure and rendering pipeline.

---

## 1. Research Objectives

### Technical Question

How can we accurately calculate the real-time positions (Alt/Az) of Stars, Constellations, and Deep Sky Objects (DSOs) to overcome the limitations of the Swiss Ephemeris, enabling a complete "Sky Map" feature in the Astr app?

### Project Context

The Astr app currently uses `sweph` (Swiss Ephemeris) for planets/sun/moon. We need a solution for the rest of the universe (Stars, Nebulae, Galaxies) that integrates with our Flutter frontend.

### Requirements and Constraints

- **Functional:** Support Stars (Hipparcos/Yale), Constellations (Stick figures), and DSOs (Messier/NGC).
- **Technical:** Must run on mobile (Flutter), ideally offline.
- **Performance:** Real-time rendering (60fps) for AR/Sky Map.

---

## 2. Technology Options Evaluated

1.  **Dart Native Implementation (Recommended):** Custom Dart service using standard algorithms and local databases.
2.  **Python Backend API:** Offload calculations to server (Flask + Astropy).
3.  **C++ FFI (`libnova`):** Bind a C++ astronomy library to Flutter.

---

## 3. Detailed Technology Profiles

### Option 1: Dart Native Implementation (Recommended)

**Overview:**
Implement the "Right Ascension/Declination to Altitude/Azimuth" conversion algorithm directly in Dart. Store star catalogs (Yale Bright Star, Hipparcos) in a local database (SQLite or Hive).

**Data Sources:**
-   **Stars:** Yale Bright Star Catalog (BSC) for naked-eye stars (~9,000 objects). Hipparcos for zooming (~100k objects).
-   **Constellations:** Open-source datasets (e.g., Stellarium's `constellationship.fab` or `dcf21` GitHub repo) providing Star ID pairs for lines.
-   **DSOs:** Messier Catalog (110 objects) and NGC (New General Catalog).

**Algorithm (Meeus):**
1.  Calculate **Local Sidereal Time (LST)** based on user longitude and time.
2.  Calculate **Hour Angle (HA)**: `HA = LST - RA`.
3.  Convert to **Alt/Az** using spherical trigonometry:
    -   `sin(Alt) = sin(Dec)*sin(Lat) + cos(Dec)*cos(Lat)*cos(HA)`
    -   `tan(Az) = sin(HA) / (cos(HA)*sin(Lat) - tan(Dec)*cos(Lat))`

**Pros:**
-   Zero external dependencies (pure Dart).
-   Fastest performance (no bridge/network latency).
-   Fully offline.

**Cons:**
-   Requires initial implementation of math formulas (approx. 1-2 days work).

### Option 2: Python Backend API

**Overview:**
Send user location/time to the Python backend. Backend uses `Astropy` or `SkyField` to calculate positions and returns a JSON list of visible objects.

**Pros:**
-   Access to powerful, verified libraries (`Astropy`).
-   Easy to update catalogs without app updates.

**Cons:**
-   **Latency:** Unusable for real-time AR (requires constant updates as phone moves).
-   **Offline:** Does not work without internet.

### Option 3: C++ FFI (`libnova`)

**Overview:**
Compile a C++ library like `libnova` or `Stellarium`'s core engine and access it via Dart FFI.

**Pros:**
-   High precision and verified algorithms.

**Cons:**
-   **Complexity:** High build complexity (NDK, CMake, iOS Frameworks).
-   **Overkill:** We don't need sub-arcsecond precision for a visual sky map.

---

## 4. Competitor Analysis (Market Research Context)

### Stellarium & SkySafari Approaches

**Stellarium:**
-   **Architecture:** C++ Core Engine.
-   **Data:** Uses custom binary catalog formats for efficiency.
-   **Constellations:** Uses `constellationship.fab` files which map "Star A" to "Star B" to draw lines.
-   **Rendering:** OpenGL for high-performance rendering of thousands of stars.

**SkySafari:**
-   **Architecture:** Native C/C++ engine optimized for mobile.
-   **Data:** Highly compressed proprietary databases.
-   **Key Insight:** Both apps rely on **static catalogs** for stars and **real-time math** for positioning. They do *not* query a server.

**Implication for Astr:**
We should mimic this architecture: **Static Data (Local DB) + Real-time Math (Dart).**

---

## 5. Recommendations

### Primary Recommendation: Dart Native Engine

We should build a `StarCalculator` service in Dart and import the **Yale Bright Star Catalog** (JSON/CSV converted to Hive/SQLite) for the initial implementation.

### Implementation Roadmap

1.  **Data Ingestion:**
    -   Download Yale Bright Star Catalog (JSON).
    -   Download Constellation Lines dataset (Star ID pairs).
    -   Script to convert these into a mobile-optimized `assets/stars.db` (SQLite) or Hive boxes.

2.  **Core Service (`StarCalculator`):**
    -   Implement `calculateLST(time, longitude)`.
    -   Implement `radecToAltAz(ra, dec, lat, lst)`.

3.  **UI Integration:**
    -   Create a `SkyMapWidget` using `CustomPainter`.
    -   On each frame (or location update), query visible stars from DB, calculate Alt/Az, and paint points on the canvas.

### Risk Mitigation

-   **Performance:** If `CustomPainter` struggles with >1000 stars, we can switch to `Flutter GPU` or `Flame` engine, or simply filter stars by magnitude based on zoom level (Level of Detail).

---

## 6. References

-   **Algorithms:** Jean Meeus, *Astronomical Algorithms*.
-   **Data:** [Yale Bright Star Catalog](http://tdc-www.harvard.edu/catalogs/bsc5.html)
-   **Constellations:** [Stellarium Data](https://github.com/Stellarium/stellarium/tree/master/skycultures)
