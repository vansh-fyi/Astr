# Astr

**Your Personal Stargazing Planner**

*Real-time light pollution zones | Celestial object catalog | Weather forecasts | Astronomical calculations*

[![Flutter](https://img.shields.io/badge/Flutter-3.32+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#license)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-brightgreen)](#supported-platforms)

[Download on Google Play](https://play.google.com/store/apps/details?id=com.astr.app) |
[Download on App Store](https://apps.apple.com/app/astr) |
[Open Web App](https://astr.app)

</div>

---

## What is Astr?

Astr helps you plan the perfect stargazing session. It combines real-time light pollution data from VIIRS satellite imagery, accurate astronomical calculations via the Swiss Ephemeris, and weather forecasts to tell you **when and where** to look up.

---

## Features

### Dashboard
- **Tonight's Sky** -- at-a-glance stargazing conditions for your location
- **Light Pollution Zone** -- real-time zone rating (1-9 scale) using VIIRS satellite data with atmospheric skyglow propagation modeling
- **Weather Integration** -- hourly cloud cover, transparency, and seeing conditions via Open-Meteo
- **Prime Viewing Windows** -- algorithm that calculates optimal stargazing time slots factoring in moon phase, cloud cover, and darkness

### Celestial Catalog
- Browse stars, planets, constellations, galaxies, nebulae, and star clusters
- Visibility calculations based on your location and time
- Detailed object information with rise/set times

### 7-Day Forecast
- Multi-day stargazing forecast with star ratings
- Cloud cover predictions and astronomical twilight tracking

### Profile & Settings
- Multiple saved locations with GPS or manual entry
- Red mode (night vision) overlay to preserve dark adaptation
- Offline global zone data download (native apps only)
- Background weather sync

---

## Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | Supported | Min SDK 23 (Android 6.0), Target SDK 35 (Android 15) |
| **iOS** | Supported | iOS 16.0+ |
| **Web (PWA)** | Supported | Touchscreen mobile browsers. Installs as a PWA. |
| **Desktop browsers** | N/A | Shows a redirect to download the mobile app |

Astr is designed for **touchscreen devices**. Desktop browsers display a landing page with links to the app stores.

---

## Architecture

```
lib/
├── app/                   # Router, theme, navigation shell
├── core/
│   ├── engine/            # Astronomy engine (Swiss Ephemeris via sweph)
│   │   ├── algorithms/    # Celestial calculations, coordinate transforms
│   │   ├── database/      # Star & DSO catalogs (SQLite)
│   │   └── models/        # Astronomical data models
│   ├── platform/          # Background sync (WorkManager / BGTaskScheduler)
│   ├── services/          # Weather, location, qualitative conditions
│   └── widgets/           # Red mode overlay, glass panel, shared UI
├── features/
│   ├── astronomy/         # Core astronomical calculations & providers
│   ├── catalog/           # Celestial object browser
│   ├── context/           # Location context & zone display
│   ├── dashboard/         # Home screen, weather, prime viewing windows
│   ├── data_layer/        # H3 geospatial indexing, zone repository
│   ├── planner/           # 7-day forecast screen
│   ├── profile/           # Settings, locations, offline data
│   └── splash/            # Initialization, TOS, smart launch
└── hive/                  # Encrypted local storage (AES-256)
```

### Key Technologies

| Technology | Purpose |
|------------|---------|
| **Riverpod 2.6** | State management with code generation |
| **GoRouter** | Navigation with `StatefulShellRoute` bottom nav |
| **Hive CE** | AES-256 encrypted local storage |
| **Swiss Ephemeris (sweph)** | Precise planetary position calculations |
| **H3 (h3_flutter)** | Hexagonal geospatial indexing for zone lookups |
| **SQLite (sqflite)** | Star catalog and DSO database |
| **Cloudflare Workers + D1** | Zone data API backend |
| **Open-Meteo** | Weather forecast data |

---

## How Light Pollution Zones Work

Astr uses a custom 9-zone scale derived from VIIRS satellite nighttime lights data:

```
LPI  = Radiance / 0.171
Zone = clamp(ceil(1 + log(LPI / 0.05) / log(2.5)), 1, 9)
```

Raw satellite data only captures upward light. Astr applies a **Garstang-inspired skyglow propagation model** via FFT convolution to account for atmospheric scatter from cities up to 80 km away. This means a "dark" site 30 km from a city correctly shows as Zone 2-3 instead of Zone 1.

See [`docs/astr_zone_scale.md`](docs/astr_zone_scale.md) and [`docs/skyglow_propagation.md`](docs/skyglow_propagation.md) for the full specification.

---

## Getting Started

### Prerequisites

- Flutter 3.32+
- Dart 3.0+
- Xcode 16+ (for iOS, deployment target 16.0)
- Android Studio / Android SDK 35 (for Android)

### Setup

```bash
# Clone
git clone https://github.com/vansh-fyi/Astr.git
cd Astr

# Install dependencies
flutter pub get

# Generate code (Riverpod, Freezed, JSON serialization, Hive adapters)
dart run build_runner build --delete-conflicting-outputs

# Run on device
flutter run
```

### Building for Release

```bash
# Android (AAB for Play Store)
flutter build appbundle --release

# iOS (Archive via Xcode)
flutter build ios --release
# Then: Xcode -> Product -> Archive -> Distribute -> App Store Connect

# Web (PWA)
flutter build web --release
```

---

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run static analysis
flutter analyze
```

The test suite includes unit tests for astronomical calculations, widget tests for UI components, and integration tests for data repositories.

---

## Backend

The zone data API runs on Cloudflare Workers with D1 (SQLite):

```
Flutter App -> Cached Zone Repository -> Cloudflare Worker -> D1 Database
```

See [`cloudflare/README.md`](cloudflare/README.md) for deployment setup and [`docs/cloudflare_d1_setup.md`](docs/cloudflare_d1_setup.md) for the data import guide.

---

## Documentation

| Document | Description |
|----------|-------------|
| [`docs/app_overview.md`](docs/app_overview.md) | Full app feature documentation |
| [`docs/architecture_diagram.md`](docs/architecture_diagram.md) | System architecture and data flow |
| [`docs/astr_zone_scale.md`](docs/astr_zone_scale.md) | Light pollution zone formula |
| [`docs/skyglow_propagation.md`](docs/skyglow_propagation.md) | Atmospheric scatter model |
| [`docs/cloudflare_d1_setup.md`](docs/cloudflare_d1_setup.md) | Backend setup guide |

---

## Privacy

- **Location data** is used only for astronomical calculations and weather lookups. It is not shared with third parties.
- **No user accounts** are required. All preferences are stored locally on-device with AES-256 encryption.
- **Analytics**: Microsoft Clarity is used for anonymous usage analytics. No personal data is collected.
- **Network requests** go only to Open-Meteo (weather), Open-Meteo Geocoding (location search), and Cloudflare (zone data).

[Privacy Policy](https://astr.app/privacy) | [Terms of Service](https://astr.app/terms)

---

## Support

If you enjoy using Astr, consider supporting development:

[Support on Ko-fi](https://ko-fi.com/vanshgrover)

---

## License

Copyright (c) 2025-2026 Vansh Grover. All Rights Reserved.

The code, design, and content of this repository are the intellectual property of Vansh Grover. Unauthorized copying, modification, distribution, or use is strictly prohibited.

See [LICENSE](LICENSE) for details.

---

## Links

- [Contributing](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Cloudflare API](cloudflare/)
- [Data Pipeline Scripts](scripts/)
