# Story 6.1: Secure API Proxy & Open-Meteo Exception

**Epic**: 6 - Security & Compliance
**Status**: review
**Priority**: High

## User Story
As a Developer, I want to proxy sensitive API calls while allowing direct calls for free/public APIs (like Open-Meteo), so that we balance security with cost/complexity for the MVP.

## Context
Originally, we planned to proxy *everything*. However, Open-Meteo is free, keyless, and allows 10,000 requests/day for non-commercial use. Proxying it adds unnecessary latency and complexity for the MVP. We will implement a "Hybrid" approach: Direct calls for Open-Meteo, Proxy for anything requiring a secret key (future).

## Acceptance Criteria

### AC 1: Hybrid API Configuration
- [ ] **Config**: Implement `ApiConfig` class that distinguishes between `direct` and `proxied` endpoints.
- [ ] **Switch**: Add a feature flag (compile-time or config) to easily switch Open-Meteo to proxy mode in the future.

### AC 2: Open-Meteo Direct Client (The Exception)
- [ ] **Implementation**: `WeatherRepository` and `GeocodingRepository` call `https://api.open-meteo.com` directly.
- [ ] **Justification**: Document in code why this is safe (Keyless, Free Tier).
- [ ] **Removal**: Remove existing proxy calls for Weather/Geocoding if they exist.

### AC 3: Cloudflare Worker (Infrastructure Prep)
- [ ] **Setup**: Initialize `astr-proxy` worker (Hono) as a placeholder for future keyed APIs.
- [ ] **Endpoint**: Create a simple `/health` or `/status` endpoint to verify connectivity.
- [ ] **Security**: Ensure it's ready to accept secrets when needed.

## Technical Implementation Tasks

### Flutter App
- [ ] Refactor `ApiConfig` to support direct URLs.
- [ ] Update `OpenMeteoWeatherService` to use direct URL.
- [ ] Update `GeocodingService` to use direct URL.
- [ ] Verify `WeatherRepository` works with direct calls.

### Backend (Worker)
- [ ] Keep existing `astr-proxy` project.
- [ ] (Optional) Comment out or deprecate the proxy routes for now to save worker requests.
- [ ] Ensure `wrangler.toml` is configured.

### Review Follow-ups (AI)
- [ ] [AI-Review][Low] Rename `_searchOSM` to `_searchLocations` in `AddLocationScreen` (AC #2)

## Dependencies
- `dio` or `http` (Flutter)
- `wrangler` (Backend)

## Dev Notes
- **Future Proofing**: We are NOT deleting the proxy concept. We are just bypassing it for Open-Meteo for now.
- **Security**: If we add a paid weather provider later, we MUST switch back to the proxy.

## Senior Developer Review (AI)
- **Reviewer**: Antigravity
- **Date**: 2025-12-01
- **Outcome**: Refactoring Approved

### Summary
Refactored to allow direct Open-Meteo calls. This simplifies the MVP and reduces latency.

## Senior Developer Review (AI)
- **Reviewer**: Antigravity
- **Date**: 2025-12-01
- **Outcome**: Approve

### Summary
The refactoring to implement the Hybrid API strategy has been executed correctly. The application now supports direct calls to Open-Meteo for weather and geocoding, while retaining the Cloudflare Worker proxy infrastructure for future use. All acceptance criteria and tasks have been verified.

### Key Findings
- **High/Medium Severity**: None.
- **Low Severity**:
    - `AddLocationScreen`: Method `_searchOSM` should be renamed to `_searchLocations` to reflect that it now uses the generic `GeocodingRepository` (Open-Meteo) instead of OSM Nominatim.

### Acceptance Criteria Coverage
| AC# | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| AC 1 | Hybrid API Configuration | **IMPLEMENTED** | `lib/core/config/api_config.dart` (Lines 8, 21-22) |
| AC 2 | Open-Meteo Direct Client | **IMPLEMENTED** | `OpenMeteoWeatherService` & `GeocodingService` use `ApiConfig` getters. |
| AC 3 | Cloudflare Worker Prep | **IMPLEMENTED** | `backend/wrangler.toml` & `backend/src/index.ts` (Health check at `/`) |

**Summary**: 3 of 3 acceptance criteria fully implemented.

### Task Completion Validation
| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Refactor `ApiConfig` | [x] | **VERIFIED** | `ApiConfig` class updated. |
| Update `OpenMeteoWeatherService` | [x] | **VERIFIED** | Uses `ApiConfig.weatherBaseUrl`. |
| Update `GeocodingService` | [x] | **VERIFIED** | Uses `ApiConfig.geocodingBaseUrl`. |
| Verify `WeatherRepository` | [x] | **VERIFIED** | Tests passed. |
| Ensure `astr-proxy` exists | [x] | **VERIFIED** | `backend/wrangler.toml` exists. |

**Summary**: 5 of 5 completed tasks verified.

### Test Coverage and Gaps
- `weather_repository_test.dart`: Verified.
- `atmospherics_sheet_test.dart`: Verified (fixed compilation error).
- `planner_provider.dart`: Verified (fixed compilation error).

### Architectural Alignment
- **Proxy Pattern**: The implementation correctly follows the "Exception" clause for Open-Meteo defined in the Architecture Document.
- **Layering**: `GeocodingRepository` correctly abstracts the data source.

### Security Notes
- Direct calls to Open-Meteo are safe as they are keyless and free for non-commercial use.
- Proxy infrastructure is in place for future keyed APIs.

### Action Items
**Code Changes Required:**
- [ ] [Low] Rename `_searchOSM` to `_searchLocations` in `AddLocationScreen` (AC #2) [file: lib/features/profile/presentation/screens/add_location_screen.dart:77]

**Advisory Notes:**
- Note: Ensure `ApiConfig.useProxy` remains `false` for the MVP release.

