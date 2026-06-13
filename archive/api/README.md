# Archive: api/ — Python/Vercel Serverless Function

This directory contains the former `api/` folder that was archived in Phase 1 (2026-06-13).

## What this was

A Python/Vercel serverless function (`api/index.py`) deployed to Vercel. It acted as a proxy that
received coordinate requests from the Flutter app and queried MongoDB for zone/light-pollution data.

**Stack:**
- Python 3.x with Flask 3.0.0
- `pymongo` 4.6.0 for MongoDB access
- `python-dotenv` 1.0.0 for environment variable loading
- Vercel serverless runtime — `vercel.json` configured the deployment

**Endpoints:**
- `GET /api/health` — health check with MongoDB connectivity status
- `GET /api/light-pollution?lat=<lat>&lon=<lon>` — returns MPSAS and Bortle class from MongoDB

The `index.py` file defined a standard Vercel serverless handler using Flask's WSGI app.

## Why it was archived (Phase 1, 2026-06-13)

This API died when the MongoDB backend was retired. The endpoint served light-pollution data
from a MongoDB collection that no longer exists. No active Flutter code references this endpoint.

The Vercel deployment was superseded entirely by the Cloudflare Worker approach — the Flutter
app now queries the Cloudflare Worker directly via HTTP for zone data, with no Python proxy
layer in between.

## What replaced it

Zone data is now served directly from **Cloudflare Workers** (see `cloudflare/`), reading binary
zone data from Cloudflare R2 and the D1 database. No Python proxy layer is needed.

The Flutter app calls the Cloudflare Worker URL directly via `H3Service` in:
`lib/features/data_layer/services/h3_service.dart`

Weather data comes from Open-Meteo directly via `OpenMeteoWeatherService` in:
`lib/features/dashboard/data/datasources/open_meteo_weather_service.dart`

## Note

The `vercel.json` at the repo root (if still present) may also be a dead artifact from this
Vercel deployment — check and remove if unreferenced by any active build process.
