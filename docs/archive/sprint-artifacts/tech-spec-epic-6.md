# Epic Technical Specification: Security & Compliance

Date: 2025-11-30
Author: Vansh
Epic ID: 6
Status: Draft

---

## Overview

This epic focuses on hardening the application's security and ensuring legal compliance. The primary technical objective is to implement a **Secure API Proxy** using Cloudflare Workers to shield third-party API keys (Open-Meteo, Geocoding) from client-side exposure. Additionally, it introduces a mandatory **Terms of Service (ToS)** acceptance flow to mitigate liability risks associated with suggesting remote stargazing locations.

## Objectives and Scope

### In-Scope
- **Cloudflare Worker Setup:** Initialize a Hono-based worker project.
- **API Proxy Endpoints:** Implement `GET /api/weather` and `GET /api/geocode`.
- **Security Controls:** Implement origin checks and basic rate limiting on the proxy.
- **ToS UI:** Create a modal/screen for Terms of Service acceptance.
- **Persistence:** Store ToS acceptance state locally using Hive.

### Out-Scope
- **User Authentication:** No user accounts are required for this epic.
- **Payment Processing:** No paid features in this scope.
- **Complex Analytics:** Basic request logging is sufficient.

## System Architecture Alignment

This implementation directly fulfills the **"Cloud Infrastructure (Edge)"** component and the **"Proxy Pattern"** defined in the Architecture Document.

- **Component:** Cloudflare Worker (Hono).
- **Pattern:** The mobile app will cease direct communication with `open-meteo.com` and instead route requests through `https://api.astr.app` (or the worker URL).
- **State:** ToS acceptance is stored in the existing `settings` Hive box.

## Detailed Design

### Services and Modules

| Module | Responsibility | Owner |
| :--- | :--- | :--- |
| **API Proxy (Worker)** | Intercepts client requests, injects API keys, calls upstream providers, and returns sanitized data. | Backend |
| **ToS Manager** | Manages the UI flow for ToS acceptance and checks persistence status on app launch. | Frontend |

### Data Models and Contracts

#### Local Storage (Hive - `settings` box)
```dart
// Key: 'tos_accepted'
bool tosAccepted; // true if user has agreed
```

### APIs and Interfaces

#### 1. Weather Proxy
- **Endpoint:** `GET /api/weather`
- **Params:** `lat` (double), `long` (double)
- **Upstream:** Calls Open-Meteo API.
- **Response:** JSON (Standardized Weather Data)

#### 2. Geocode Proxy
- **Endpoint:** `GET /api/geocode`
- **Params:** `q` (string)
- **Upstream:** Calls Geocoding Provider (e.g., Open-Meteo Geocoding).
- **Response:** JSON (List of Locations)

### Workflows and Sequencing

#### ToS Flow
1.  **App Launch:** `main.dart` checks `settingsBox.get('tos_accepted')`.
2.  **Condition:** If `false` or `null`, redirect to `ToSScreen`.
3.  **Action:** User taps "I Agree".
4.  **Persistence:** Save `true` to `settingsBox`.
5.  **Navigation:** Route to `HomeScreen`.

#### Proxy Flow
1.  **Client:** `WeatherRepository` calls `WorkerURL/api/weather?lat=...`.
2.  **Worker:** Validates request origin (if possible) or API token (future).
3.  **Worker:** Calls `open-meteo.com/v1/forecast?...`.
4.  **Worker:** Returns data to Client.

## Non-Functional Requirements

### Performance
- **Latency:** Proxy overhead should be < 50ms (Cloudflare Edge).
- **Cold Starts:** 0ms (Cloudflare Workers).

### Security
- **Key Protection:** Upstream API keys must be stored in Cloudflare Secrets (Environment Variables), NEVER in the code.
- **Rate Limiting:** Implement basic rate limiting (e.g., 10 requests/min per IP) to prevent abuse.

### Reliability/Availability
- **Fallback:** If the proxy fails, the app should handle the error gracefully (show "Offline" or "Service Unavailable").

### Observability
- **Logging:** Worker should log basic request metrics (status codes, latency) to Cloudflare Dashboard.

## Dependencies and Integrations

- **Backend Framework:** `hono` (TypeScript/JavaScript).
- **Deployment:** `wrangler` (Cloudflare CLI).
- **Frontend Storage:** `hive` (Dart).
- **Upstream APIs:** Open-Meteo (Weather & Geocoding).

## Acceptance Criteria (Authoritative)

1.  **Secure Proxy Setup:**
    - A Cloudflare Worker project is initialized with Hono.
    - Upstream API keys are stored as Secrets.
2.  **Weather Endpoint:**
    - `GET /api/weather` successfully returns weather data from upstream.
3.  **Geocode Endpoint:**
    - `GET /api/geocode` successfully returns location data from upstream.
4.  **ToS Modal:**
    - App displays a blocking ToS screen on first launch.
    - User cannot proceed without accepting.
5.  **ToS Persistence:**
    - Acceptance is saved to Hive.
    - Screen does not appear on subsequent launches.

## Traceability Mapping

| AC ID | Description | Spec Section | Component | Test Idea |
| :--- | :--- | :--- | :--- | :--- |
| AC1 | Secure Proxy Setup | Detailed Design | Cloudflare Worker | Verify `wrangler.toml` and Secrets presence. |
| AC2 | Weather Endpoint | APIs | Worker Route | `curl` request to worker returns weather JSON. |
| AC3 | Geocode Endpoint | APIs | Worker Route | `curl` request with query returns location list. |
| AC4 | ToS Modal | Workflows | Flutter UI | Fresh install -> Verify ToS screen blocks Home. |
| AC5 | ToS Persistence | Data Models | Hive | Restart app -> Verify ToS screen skipped. |

## Risks, Assumptions, Open Questions

- **Risk:** Cloudflare Worker free tier limits (100k requests/day).
  - *Mitigation:* Caching is already planned in Epic 7/Architecture.
- **Assumption:** Open-Meteo remains free for non-commercial use.
- **Question:** Do we need a custom domain for the worker immediately?
  - *Answer:* No, `*.workers.dev` is fine for MVP.

## Test Strategy Summary

- **Backend:** Unit tests for Hono routes (mocking upstream). Manual `curl` testing for deployment.
- **Frontend:** Widget test for `ToSScreen`. Integration test for the "First Launch" flow.
