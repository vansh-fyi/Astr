# Architecture Document: Astr

> **Status:** Approved
> **Date:** 2025-11-29
> **Author:** Vansh & Winston (Architect Agent)

## 1. Executive Summary

Astr is a **Flutter-based Stargazing Planner** designed for "Instant Clarity" and "Deep Precision". The architecture prioritizes **Offline-First** capability using a local Dart-based Astronomy Engine, ensuring the app works in remote dark-sky locations. It leverages a **Scale-Adaptive** backend using **Cloudflare Workers (Hono)** to securely proxy free APIs (Open-Meteo) and protect the application from quota abuse, ensuring zero-cost operation at scale.

## 2. Project Initialization

The project is initialized using the **Erengun Riverpod Template** to provide a production-ready foundation with built-in state management and routing.

**Initialization Command:**
```bash
# Clone the template as the starting point
git clone https://github.com/Erengun/Flutter-Riverpod-Quickstart-Template.git .
# Clean up git history to start fresh
rm -rf .git
git init
```

**Starter Decisions:**
*   **State Management:** Riverpod 2.0 (Code Generation)
*   **Navigation:** GoRouter (Type-safe routing)
*   **Local Storage:** Hive (Offline persistence)
*   **Networking:** Dio (Robust HTTP client)
*   **Architecture:** Clean Architecture (Domain/Data/Presentation layers)

## 3. Decision Summary

| Category | Decision | Version | Rationale |
| :--- | :--- | :--- | :--- |
| **Frontend Framework** | **Flutter** | 3.24+ | Single codebase for Android Native and iOS PWA. |
| **Astronomy Engine** | **Pure Dart (`swisseph`)** | Latest | "Plug & Play" stability across all platforms (Web/Mobile) without FFI complexity. |
| **Backend Proxy** | **Cloudflare Workers** | Latest | Global edge scaling for 16k+ users; zero cold starts; free tier. |
| **Backend Framework** | **Hono** | Latest | Lightweight, standard web standards API for Workers. Beginner friendly. |
| **Error Handling** | **Result Type** | `fpdart` | Forces explicit error handling. Prevents silent crashes. |
| **Logging** | **Logger** | `logger` | Structured, color-coded logs for easier debugging. |
| **Theme System** | **FlexColorScheme** | Latest | Robust theming engine to implement "Deep Cosmos" palette easily. |
| **Rendering Engine** | **Custom Canvas** | Flutter SDK | High-performance custom painters for graphs (Visibility, Cloud Cover). |

## 4. System Architecture

### High-Level Diagram
```mermaid
graph TD
    User[User Device] -->|Flutter App| AppShell
    
    subgraph "Mobile App (Offline First)"
        AppShell[App Shell]
        
        subgraph "Presentation Layer"
            UI[Widgets & Pages]
            State[Riverpod Providers]
        end
        
        subgraph "Domain Layer"
            Logic[Business Logic]
            Entities[Astronomy Models]
        end
        
        subgraph "Data Layer"
            Repo[Repositories]
            LocalDB[Hive Storage]
            AstroEngine[Dart Astro Engine]
        end
    end
    
    subgraph "Cloud Infrastructure (Edge)"
        Proxy[Cloudflare Worker (Hono)]
    end
    
    subgraph "External APIs"
        Weather[Open-Meteo API]
        Geo[Geocoding API]
    end
    
    Repo -->|Get Cached Data| LocalDB
    Repo -->|Calculate Position| AstroEngine
    Repo -->|Fetch Weather| Proxy
    Proxy -->|Secure Request| Weather
    Proxy -->|Secure Request| Geo
```

## 5. Project Structure

```
lib/
├── app/                        # App configuration
│   ├── theme/                  # "Astr Aura" theme definitions
│   └── router/                 # GoRouter configuration
├── core/                       # Shared utilities
│   ├── error/                  # Failure/Result classes
│   ├── services/               # Logger, Storage service
│   └── widgets/                # Shared UI (GlassPanel, etc.)
├── features/                   # Feature-based modules
│   ├── astronomy/              # The "Brain"
│   │   ├── data/               # Swiss Ephemeris implementation
│   │   ├── domain/             # Planet/Star entities
│   │   └── presentation/       # Visibility Graph widgets
│   ├── dashboard/              # Home screen
│   ├── planner/                # 7-Day Forecast
│   └── profile/                # Settings & Saved Locations
└── main.dart                   # Entry point
```

## 6. Implementation Patterns

### A. The "Result" Pattern (No Crashes)
**Rule:** Repositories MUST return `Future<Either<Failure, Type>>`.
**Why:** Forces the UI to handle the "Left" (Error) case.

```dart
// Bad
Future<Weather> getWeather() async {
  throw Exception("Network Error"); // Crashes app if not caught
}

// Good
Future<Either<Failure, Weather>> getWeather() async {
  try {
    return Right(weather);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

### B. The "Glass" Pattern (UI)
**Rule:** All container widgets should use the shared `GlassPanel` widget.
**Why:** Ensures consistent "Deep Cosmos" aesthetic and performance (one blur implementation).

### C. The "Proxy" Pattern (Security)
**Rule:** APIs requiring keys/auth MUST be proxied through Cloudflare Workers. Free/keyless APIs (Open-Meteo) may be called directly from Flutter.
**Why:** Protects API keys while allowing zero-cost free-tier usage.
**Exception:** Open-Meteo is keyless and free for non-commercial use → Direct client calls acceptable.
**Implementation:**
1.  Flutter calls `https://api.astr.app/weather` (for keyed APIs only)
2.  Cloudflare Worker receives request.
3.  Worker calls protected API.
4.  Worker returns data to Flutter.

### D. The "Backend Data Services" Pattern (NASA + Vercel + MongoDB)
**Rule:** Light pollution data must use pre-computed architecture with offline fallback.
**Why:** NASA Black Marble VIIRS is public domain (no licensing issues) + satellite-grade accuracy. Pre-computing data avoids real-time HDF5 processing overhead.
**Implementation:**

**Architecture:**
```
Flutter App → Vercel Serverless → MongoDB Atlas (2dsphere index)
                                        ↑
              Offline Monthly Job (Python + h5py) → NASA LAADS DAAC (VNP46A2 HDF5)
```

**Components:**
1. **Data Source:** NASA Black Marble VIIRS VNP46A2
   - Public domain (U.S. government data, no licensing restrictions)
   - 500m resolution, daily global nighttime lights
   - Downloaded from NASA LAADS DAAC (requires free Earthdata Login)

2. **Offline Processing (Monthly Job - Local Python):**
   ```python
   # scripts/process_nasa_data.py
   # Dependencies: h5py==3.15.1, pymongo==4.15.4, numpy
   
   # 1. Download VNP46A2 HDF5 file from NASA
   # 2. Extract DNB_BRDF-Corrected_NTL layer
   # 3. Convert radiance → MPSAS: 12.589 - 1.086 * log(radiance)
   # 4. Map MPSAS → Bortle Scale (1-9)
   # 5. Upload to MongoDB Atlas (GeoJSON Point documents)
   ```

3. **MongoDB Atlas (Free Tier: 512MB):**
   - Database: `astr`, Collection: `light_pollution`
   - **2dsphere geospatial index** on `location` field
   - Document schema:
     ```json
     {
       "location": {"type": "Point", "coordinates": [lon, lat]},
       "mpsas": 21.5,
       "bortle": 3,
       "source": "VNP46A2_2024-11"
     }
     ```
   - Storage: Global 10km grid (~200,000 coordinates) fits in 512MB free tier

4. **Vercel Serverless Function (Python 3.12):**
   ```python
   # api/light-pollution.py
   # Dependencies: Flask==3.1.2, pymongo==4.15.4
   
   @app.route('/api/light-pollution')
   def get_light_pollution():
       lat, lon = request.args.get('lat'), request.args.get('lon')
       
       # MongoDB $near query (finds closest pre-computed point)
       result = collection.find_one({
           'location': {
               '$near': {
                   '$geometry': {'type': 'Point', 'coordinates': [lon, lat]},
                   '$maxDistance': 50000  # 50km radius
               }
           }
       })
       return jsonify({'mpsas': result['mpsas'], 'bortle': result['bortle']})
   ```

5. **Flutter Integration:**
   ```dart
   // lib/features/dashboard/data/repositories/light_pollution_repository.dart
   Future<Either<Failure, LightPollution>> getLightPollution(Location loc) async {
     try {
       final response = await http.get(Uri.parse(
         'https://astr-backend.vercel.app/api/light-pollution?lat=${loc.lat}&lon=${loc.lon}'
       ));
       if (response.statusCode == 200) {
         return Right(LightPollution.fromJson(jsonDecode(response.body)));
       } else {
         return _getPNGFallback(loc);  // Offline fallback
       }
     } catch (e) {
       return _getPNGFallback(loc);
     }
   }
   ```

6. **Fallback (Offline):** PNG Map (`assets/maps/world2024_low3.png`)
   - Bundled in Flutter app
   - Equirectangular projection (lat/long → pixel coordinates)
   - Luminance heuristic for rough visibility estimate
*   **Inputs:** List of variables (Name, Type, Range/Description) required for data binding.
*   **Visual Requirements:** Specific design notes, colors (referencing "Astr Aura"), and animation behaviors (loops, triggers).
*   **Why:** Ensures the designer (User) creates exactly what the developer (Agent) needs to wire up.

## 7. Data Architecture

### Local Storage (Hive)
*   **Box: `settings`**
    *   `theme_mode` (Always Dark)
    *   `red_mode` (bool)
    *   `units` (metric/imperial)
*   **Box: `locations`**
    *   List of `SavedLocation` objects.
*   **Box: `cache`**
    *   `weather_data` (Cached for 1 hour to save API calls).

### API Contracts (Cloudflare)
*   `GET /weather?lat=x&long=y` -> Returns JSON (Cloud Cover, Seeing)
*   `GET /geocode?q=query` -> Returns JSON (Location Search)

## 8. Security & Privacy
*   **Location:** Only requested when needed. Not stored remotely.
*   **API Keys:** Stored in Cloudflare Secrets (Environment Variables). Not in code.
*   **Anonymity:** No user accounts required for core features.

## 9. Next Steps
1.  **Initialize Project:** Run the starter command.
2.  **Setup Cloudflare:** Create the Hono worker project.
3.  **Implement Epic 1:** Build the Shell and integrate the Dart Astronomy Engine.
