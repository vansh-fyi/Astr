# Astr App Overview

**Version:** 1.0.0  
**Last Updated:** February 2026

---

## What is Astr?

Astr is a stargazing planner that helps you find the best times and places to observe the night sky. It combines satellite light pollution data, weather forecasts, and astronomical calculations to give you a complete picture of tonight's stargazing conditions.

---

## Screens & User Flows

### 1. Splash → Initialization
- Loads Swiss Ephemeris data files
- Initializes Hive encrypted storage
- Requests location permission
- Fetches initial zone + weather data
- Routes to TOS (first launch) or Dashboard (returning user)

### 2. Terms of Service
- One-time acceptance gate
- Persisted in Hive storage

### 3. Dashboard (Home)
- **Light Pollution Zone** — Zone 1–9 with color-coded display
- **Current Conditions** — Cloud cover %, transparency, seeing
- **Weather Cards** — Hourly breakdown with astro-relevant metrics
- **Prime Viewing Window** — Algorithm-selected best time slot tonight
- **Moon Phase** — Current phase and illumination %

### 4. Catalog
- Browse celestial objects by category (stars, planets, constellations, galaxies, nebulae, clusters)
- Each object shows: visibility status, rise/set times, altitude, magnitude
- Detail screen with extended information

### 5. Forecast
- Multi-day stargazing forecast
- Cloud cover timeline
- Astronomical twilight / darkness windows

### 6. Settings / Profile
- **Saved Locations** — Add, edit, delete locations (GPS or manual coordinates)
- **Red Mode** — Night-vision overlay (red filter on entire UI)
- **Background Sync** — Periodic weather updates via WorkManager (Android) / BGTaskScheduler (iOS)

---

## Data Sources

| Data | Source | Update Frequency |
|------|--------|-----------------|
| Light Pollution | VIIRS DNB VNL v2 (NOAA) + Skyglow model | Static (annual satellite composite) |
| Zone Lookup | Cloudflare D1 via Workers API | On-demand per location change |
| Weather | Open-Meteo API (direct, no API key) | Hourly with local cache |
| Celestial Positions | Swiss Ephemeris (sweph) | Real-time calculation |
| Geocoding | Open-Meteo Geocoding API | On location search |

---

## Zone Scale

Astr uses a custom 9-zone scale derived from VIIRS radiance data:

| Zone | Stars Visible | What You See |
|------|---------------|--------------|
| 1 | ~15,000 | Zodiacal light, gegenschein |
| 2 | ~10,000 | Milky Way with dark lanes |
| 3 | ~7,000 | Milky Way clearly visible |
| 4 | ~4,500 | Milky Way visible |
| 5 | ~2,500 | Milky Way barely visible |
| 6 | ~1,000 | No Milky Way |
| 7 | ~500 | Major constellations only |
| 8 | ~200 | Orion's belt visible |
| 9 | ~50 | Only planets + brightest stars |

See [astr_zone_scale.md](astr_zone_scale.md) for the formula and [skyglow_propagation.md](skyglow_propagation.md) for the atmospheric scatter model.

---

## Permissions

| Permission | Platform | Why |
|------------|----------|-----|
| Location (When In Use) | Both | Calculate celestial positions for your coordinates |
| Location (Always) | Both | Background weather sync |
| Internet | Both | API calls (weather, zones, geocoding) |
| Background Fetch | iOS | Periodic weather updates |
| Foreground Service | Android | WorkManager background sync |

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.32+ / Dart 3.0+ |
| State Management | Riverpod 2.6 + code generation |
| Immutable State | Freezed 3.0 |
| Navigation | GoRouter 16.2 (StatefulShellRoute) |
| Local Storage | Hive CE 2.11 (AES-256 encrypted) |
| HTTP Client | Dio 5.8 |
| Astronomy | sweph 3.2 (Swiss Ephemeris) |
| Geospatial | h3_flutter 0.7 (Uber H3) |
| Animations | Rive, Lottie, flutter_animate |
| Analytics | Microsoft Clarity |
| Backend | Cloudflare Workers + D1 (SQLite) |
| Data Pipeline | Python (VIIRS processing, skyglow convolution) |

---

## Web vs Native

| Feature | Native (Android/iOS) | Web (PWA) |
|---------|---------------------|-----------|
| Zone lookup | Cloudflare D1 API | Cloudflare D1 API |
| Offline data | Optional download | Not available |
| Background sync | WorkManager / BGTask | Not supported |
| Location | GPS via geolocator | Browser Geolocation API |
| Storage | Hive (file-based) | Hive (IndexedDB) |
| Desktop browsers | N/A | Shows "use phone" gate |
