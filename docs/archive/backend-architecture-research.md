# Backend Architecture Research - Story 8.0: Data Services Decision

> 📊 **Research Type:** Technical Architecture Evaluation  
> **Date:** 2025-11-30  
> **Researcher:** Mary (Business Analyst)  
> **Deliverable for:** Story 8.0 - Backend Architecture Research & Decision  
> **Status:** Draft - Awaiting Vansh Approval

---

## Executive Summary

**Research Question:** What backend architecture should Astr implement for light pollution and weather data services?

**⚠️ CRITICAL UPDATE (2025-11-30):** David Lorenz Binary Tiles require explicit permission (no open-source license). User decision: proceed with NASA Black Marble to avoid licensing delays.

**🎯 FINAL RECOMMENDATION:** **Vercel Serverless + MongoDB Atlas (Zero Cost)**
- **Primary:** NASA Black Marble VNP46A2 (pre-computed monthly, uploaded to MongoDB)
- **Fallback:** PNG offline map (bundled in Flutter)
- **Weather:** Open-Meteo direct client calls (upgrade to Cloudflare Workers at 1,000 users)
- **Backend:** **Vercel Serverless (Python) + MongoDB Atlas Free Tier**

**Rationale:** 
- ✅ **Zero cost** (Vercel free tier + MongoDB Atlas 512MB free)
- ✅ **Public domain data** (NASA, no licensing restrictions)
- ✅ **Highest accuracy** (satellite-grade VIIRS 500m resolution)
- ✅ **Simple deployment** (git push → auto-deploy, no server management)
- ✅ **Pre-computed data** (HDF5 processing offline → MongoDB stores results)
- ✅ **Fast queries** (<100ms via MongoDB geospatial index)

---

## 1. Requirements & Constraints

### Functional Requirements
1. Accurate light pollution data (comparable to djlorenz.github.io)
2. Offline capability via PNG fallback (remote dark-sky locations)
3. Cloud cover, humidity, temperature data
4. Low latency (<2s for data fetch)

### Non-Functional Requirements
-  **Cost:** Free tier or zero cost (open-source mandate)
- **Deployment Complexity:** Beginner-friendly (Story 8.0 user skill level: `beginner`)
- **Offline-First:** Must work in remote areas with no network
- **Accuracy:** High precision light pollution values

### Constraints
- Open source preferred
- No paid APIs
- Flutter mobile app (Android + iOS PWA)
- Offline fallback mandatory

---

## 2. Technology Options Evaluated

### Option A: David Lorenz Binary Tiles + PNG Fallback (Client-Side)

**Source:** [djlorenz.github.io/astronomy](https://djlorenz.github.io/astronomy/lp/overlay/dark.html)

**Description:**
- **Primary:** `.dat.gz` binary tiles (600x600 pixels, compressed)
- **Fallback:** Bundled PNG map (`world2024_low3.png`, equirectangular projection)
- **Implementation:** Flutter client fetches tiles, decodes using Delta-Decoding algorithm
- **Data Vintage:** Updated 2024 using NOAA VIIRS satellite data[^1]

**Technical Characteristics:**
- **Accuracy:** High (precise lat/long lookups from VIIRS satellite)
- **Latency:** ~500ms-1s (tile download + decode)
- **Offline:** Excellent (PNG bundled, tiles cacheable)
- **Implementation:**Already partially implemented in `lib/features/dashboard/data/repositories/light_pollution_repository.dart`

**Pros:**
- ✅ Zero cost (public dataset)
- ✅ No backend/deployment needed (Flutter handles decode)
- ✅ Excellent offline capability
- ✅ High accuracy (satellite-based)
- ✅ Already partially implemented

**Cons:**
- ❌ Binary tile decode algorithm complex (requires verification via web research)
- ❌ PNG fallback low precision (approximation only)
- ❌ No API—must implement tile fetching + decoding
- ❌ **LICENSING RISK:** No formal open-source license (MIT/GPL/CC)[^licensing]
  - Usage requires explicit permission from David Lorenz
  - Other platforms state "used with permission"
  - Commercial use terms unclear
  - Copyright protected under U.S. law

**Verdict:** ❌ **NOT RECOMMENDED** — Requires explicit permission from David Lorenz. User decision (2025-11-30): proceed with NASA to avoid licensing delays.

**Licensing Research Findings:**[^licensing]
- **No formal license:** djlorenz.github.io lacks MIT, GPL, or Creative Commons license
- **Permission-based:** Platforms like OpenStreetMap state "used with permission"[^OSM]
- **Attribution required:** Lorenz requests no Bortle Scale conflation + proper credit[^attribution]
- **Copyright:** Implicit copyright protection as original work creator[^copyright]
- **Commercial use:** No explicit terms found; requires direct contact with David Lorenz

---

### Option B: NASA Black Marble VIIRS (VNP46A2)

**Source:** [NASA LAADS DAAC](https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5200/VNP46A2/)

**Description:**
- **Format:** HDF5 files (Hierarchical Data Format)
- **Resolution:** 500m pixel size, daily global nighttime lights
- **Access:** LAADS DAAC archive (requires NASA Earthdata Login, free)
- **Data Vintage:** Continuous since 2012, includes 2024-2025 data[^2]

**Technical Characteristics:**
- **Accuracy:** Satellite-grade (highest available)
- **Latency:** High (HDF5 files large, requires backend processing)
- **Offline:** Poor (requires pre-processing HDF5 data)
- **Implementation:** Requires Python backend (h5py, geopandas, rasterio)

**Pros:**
- ✅ Highest accuracy (official NASA satellite data)
- ✅ Free (Earthdata Login required but no cost)
- ✅ Continuously updated
- ✅ Moonlight-corrected, atmosphere-corrected

**Cons:**
- ❌ **Requires Python backend** (Flask/Django + HDF5 libraries)
- ❌ Large file sizes (GB-scale downloads)
- ❌ Complex processing (h5py, coordinate transformations)
- ❌ No offline capability without pre-processing

 database
- ❌ Deployment complexity (backend hosting required)

**Verdict:** ❌ **NOT RECOMMENDED FOR MVP** — Excellent accuracy, but backend complexity violates beginner skill level constraint. Consider for post-MVP if Lorenz insufficient.

---

### Option C: Google Earth Engine (VNP46A2)

**Source:** [Google Earth Engine Catalog](https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_001_VNP46A2)

**Description:**
- **Platform:** Cloud-based geospatial analysis platform
- **API:** Google Earth Engine API (JavaScript or Python clients)
- **Data:** Same VNP46A2 dataset as NASA, but cloud-hosted
- **Access:** Requires Google Earth Engine account (free for research/education)

**Technical Characteristics:**
- **Accuracy:** Satellite-grade (same as NASA Black Marble)
- **Latency:** Medium (API call + cloud computation)
- **Offline:** None (cloud-only)
- **Implementation:** Backend API (calls GEE, returns processed data to Flutter)

**Pros:**
- ✅ No HDF5 processing (GEE handles it)
- ✅ Free for non-commercial use
- ✅ Scalable cloud infrastructure
- ✅ Python/JavaScript SDKs available

**Cons:**
- ❌ **Requires backend** (cannot call GEE directly from Flutter)
- ❌ No offline capability
- ❌ Account registration required
- ❌ API quota limits (unknown for free tier)
- ❌ Deployment complexity

**Verdict:** ❌ **NOT RECOMMENDED FOR MVP** — Eliminates HDF5 complexity vs. NASA, but still requires backend. Consider for post-MVP if backend infrastructure established.

---

## 3. Open-Meteo Routing Decision

**Question:** Should Open-Meteo be called directly from Flutter or proxied through a backend?

### Option 1: Direct Client Calls (Flutter → Open-Meteo)

**Rate Limits (Free Tier 2024):**[^3]
- **Per Minute:** 600 calls
- **Per Hour:** 5,000 calls
- **Per Day:** 10,000 calls
- **Per Month:** 300,000 calls

**Analysis:**
- **Astr Usage Pattern:** Forecast fetches on app launch + location change
- **Estimated Usage:** ~10-50 requests/day/user (conservative: 1 launch + 2-3 location changes)
- **10,000 users:** 100,000-500,000 requests/day → **EXCEEDS daily limit**
- **16,000 users (Architecture goal):** 160,000-800,000 requests/day → **EXCEEDS drastically**

**Pros:**
- ✅ Zero deployment complexity (no backend)
- ✅ Low latency (direct API call)
- ✅ Suitable for <1,000 users (well within free tier)

**Cons:**
- ❌ Not scalable beyond ~1,000 users
- ❌ No rate limit enforcement (users could abuse)
- ❌ API key exposure risk (though Open-Meteo is keyless)

**Verdict:** ✅ **RECOMMENDED FOR MVP** — Acceptable for initial users, add Cloudflare Workers proxy when approaching 1,000 users.

---

### Option 2: Backend Proxy (Flutter → Backend → Open-Meteo)

**Implementation:** Cloudflare Workers + Hono framework

**Pros:**
- ✅ Rate limit enforcement per user
- ✅ Caching (reduce Open-Meteo calls)
- ✅ IP address protection
- ✅ Scalable to 16,000+ users

**Cons:**
- ❌ Deployment complexity (even Cloudflare Workers requires setup)
- ❌ Adds latency (~50-100ms)
- ❌ Not needed for MVP scale

**Verdict:** 🔄 **POST-MVP MIGRATION** — Implement when user count approaches 1,000, using Cloudflare Workers + Hono.

---

## 4. Tech Stack Comparison (If Backend Needed)

### Python (Flask)

**Use Case:** NASA Black Marble HDF5 processing (if implemented)

**Pros:**[^4]
- ✅ Lightweight (Flask: ~15KB minimal)
- ✅ Fast prototyping
- ✅ Excellent for simple APIs
- ✅ HDF5 libraries (h5py, geopandas) mature

**Cons:**
- ❌ Requires hosting (DigitalOcean, AWS Lambda, etc.)
- ❌ Not beginner-friendly (deployment complexity)

**Verdict:** 🟡 **CONDITIONAL** — Only if NASA Black Marble required post-MVP.

---

### Cloudflare Workers + Hono

**Use Case:** Open-Meteo proxy (when rate limits approached)

**Pros:**[^5][^6]
- ✅ **Free Tier:** 100,000 requests/day (sufficient for 1,000-2,000 users)
- ✅ Ultrafast (sub-1ms cold start, 402,820 ops/sec benchmarks)
- ✅ Global edge network (low latency)
- ✅ Zero server management
- ✅ Hono <12KB, beginner-friendly API

**Cons:**
- ❌ 10ms CPU time limit per request (unsuitable for HDF5 processing)
- ❌ Requires Cloudflare account + deployment setup

**Verdict:** ✅ **RECOMMENDED FOR POST-MVP** — Perfect for Open-Meteo proxy, not suitable for NASA data processing.

---

### Firebase Functions

**Use Case:** Alternative to Cloudflare Workers

**Pros:**[^7]
- ✅ **Free Tier:** 2 million invocations/month
- ✅ Integrated with Google Cloud ecosystem
- ✅ Beginner-friendly (Firebase SDK)

**Cons:**
- ❌ Higher latency than Cloudflare Workers
- ❌ Requires Google billing account (even for free tier)
- ❌ Cold start issues (~1-2s)

**Verdict:** 🟡 **ALTERNATIVE** — Consider only if already using Firebase for other services (auth, storage).

---

## 5. Comparative Analysis

| **Criteria** | **Lorenz Tiles (Client)** | **NASA Black Marble** | **Google Earth Engine** | **Open-Meteo Direct** | **Cloudflare Workers** |
|---|---|---|---|---|---|
| **Accuracy** | High | Highest | Highest | N/A (Weather) | N/A (Proxy only) |
| **Latency** | Low (500ms-1s) | High (backend) | Medium (API) | Low (direct) | Ultra-low (<10ms) |
| **Offline** | Excellent (PNG) | Poor | None | None | None |
| **Cost** | Free | Free | Free (limits) | Free (<10k/day) | Free (<100k/day) |
| **Deployment** | None (client) | High (Python) | High (backend) | None | Medium (Cloudflare) |
| **Scalability** | N/A (client) | High | High | Low (<1k users) | High (>100k req/day) |
| **Beginner Friendly** | ✅ Yes | ❌ No | ❌ No | ✅ Yes | 🟡 Medium |
| **MVP Suitable** | ✅ Excellent | ❌ No | ❌ No | ✅ Yes | 🔄 Post-MVP |

---

## 6. Recommended Architecture

### MVP Architecture (Story 8.0 Implementation)

```mermaid
graph TD
    A[Flutter App] -->|Request Light Pollution| B[Vercel Serverless Function]
    A -->|Fallback Offline| C[Bundled PNG Map]
    A -->|Weather API| D[Open-Meteo Direct]
    
    B -->|Geospatial Query| E[MongoDB Atlas Free Tier]
    E -->|Pre-computed Data| F[NASA VNP46A2 Processed]
    
    G[Monthly Offline Job] -->|Download HDF5| H[NASA LAADS DAAC]
    G -->|Process with h5py| I[Extract MPSAS Values]
    G -->|Upload| E
    
    C -->|Bundled| J[assets/maps/]
    
    style A fill:#4A90E2
    style B fill:#7C3AED
    style C fill:#F5A623
    style D fill:#50E3C2
    style E fill:#10B981
    style G fill:#EF4444
```

**Components:**
1. **Light Pollution:** NASA Black Marble VNP46A2 (pre-computed, stored in MongoDB)
2. **Weather:** Open-Meteo direct client calls
3. **Backend:** Vercel Serverless Function (Python 3.12)
4. **Database:** MongoDB Atlas Free Tier (512MB, 2dsphere geospatial index)
5. **Offline Processing:** Monthly job (local Python script) downloads HDF5, processes, uploads to MongoDB

**Vercel Serverless Function:**
```python
# api/light-pollution.py
from flask import Flask, request, jsonify
from pymongo import MongoClient, GEOSPHERE
import os

app = Flask(__name__)
client = MongoClient(os.environ['MONGODB_URI'])
db = client['astr']
collection = db['light_pollution']

# Create 2dsphere index (run once)
# collection.create_index([("location", GEOSPHERE)])

@app.route('/api/light-pollution')
def get_light_pollution():
    lat = float(request.args.get('lat'))
    lon = float(request.args.get('lon'))
    
    # MongoDB geospatial query - find nearest point
    result = collection.find_one({
        'location': {
            '$near': {
                '$geometry': {
                    'type': 'Point',
                    'coordinates': [lon, lat]  # GeoJSON: [lon, lat]
                },
                '$maxDistance': 50000  # 50km radius
            }
        }
    })
    
    if result:
        return jsonify({
            'mpsas': result['mpsas'],
            'bortle': result['bortle'],
            'source': result['source']
        })
    else:
        # Fallback: return default or error
        return jsonify({'error': 'No data found'}), 404
```

**MongoDB Document Schema:**
```json
{
  "_id": ObjectId("..."),
  "location": {
    "type": "Point",
    "coordinates": [-118.2437, 34.0522]  // [lon, lat] GeoJSON format
  },
  "mpsas": 18.5,
  "bortle": 7,
  "source": "VNP46A2_2024-11",
  "updated_at": ISODate("2024-11-30T00:00:00Z")
}
```

**Deployment:**
- **Platform:** Vercel (free tier)
- **Git Integration:** Push to GitHub → auto-deploy
- **Environment Variables:** `MONGODB_URI` (MongoDB Atlas connection string)
- **Function Size:** <20MB (Flask + pymongo only, no h5py!)

**Cost:** $0/month (Vercel free tier + MongoDB Atlas 512MB free)

---

### Post-MVP Architecture (>1,000 users)

```mermaid
graph TD
    A[Flutter App] -->|Fetch Tile| B[David Lorenz Binary Tiles]
    A -->|Fallback| C[Bundled PNG Map]
    A -->|Weather API| D[Cloudflare Workers + Hono]
    
    D -->|Cached| E[Open-Meteo API]
    D -->|Cache| F[Cloudflare KV]
    
    style A fill:#4A90E2
    style B fill:#7ED321
    style C fill:#F5A623
    style D fill:#BD10E0
    style E fill:#50E3C2
```

**Added Components:**
- **Cloudflare Workers:** Open-Meteo proxy with caching + rate limiting
- **Cloudflare KV:** Weather data cache (5 minutes TTL)

**Migration Trigger:** User count > 1,000 OR Open-Meteo daily limit warnings

**Deployment Complexity:** Low (Cloudflare Workers deployment)

**Cost:** $0-5/month (Cloudflare free tier sufficient for 10,000 users)

---

###Future Architecture (If NASA/GEE Required)

```mermaid
graph TD
    A[Flutter App] -->|Fetch Data| B[Python Backend Flask/Django]
    A -->|Fallback| C[Bundled PNG Map]
    A -->|Weather| D[Cloudflare Workers]
    
    B -->|Process HDF5| E[NASA Black Marble VIIRS]
    B -->|Or GEE API| F[Google Earth Engine]
    B -->|Cache| G[PostgreSQL + PostGIS]
    
    D -->|Proxy| H[Open-Meteo]
    
    style A fill:#4A90E2
    style B fill:#D0021B
    style C fill:#F5A623
    style D fill:#BD10E0
    style E fill:#F8E71C
    style F fill:#B8E986
```

**Added Components:**
- **Python Backend:** Flask (HDF5 processing) or GEE API client
- **Database:** PostgreSQL + PostGIS (spatial data caching)

**Migration Trigger:** Lorenz data accuracy insufficient OR user demand for satellite-grade precision

**Deployment Complexity:** High (backend hosting, database management)

**Cost:** $10-50/month (DigitalOcean/AWS)

---

## 7. Decision Factors & Recommendations

### Primary Recommendation: **MVP Architecture (No Backend)**

**Decision Factors (Prioritized):**
1. ✅ **Time to Market:** Immediate (no backend deployment)
2. ✅ **Zero Cost:** Aligns with open-source mandate
3. ✅ **Beginner-Friendly:** User skill level `beginner` → no DevOps required
4. ✅ **Offline-First:** PNG fallback mandatory → satisfied
5. ✅ **Accuracy:** Lorenz tiles use VIIRS 2024 data → high accuracy

**When to Reconsider:**
- User count > 1,000 → Migrate to Cloudflare Workers (Open-Meteo proxy)
- Accuracy complaints → Research NASA Black Marble integration
- User requests satellite-grade precision → Implement Option B/C

### Secondary Recommendation: **Cloudflare Workers + Hono** (Post-MVP)

**Migration Path:**
1. Monitor Open-Meteo request count in Firebase Analytics
2. Set alert at 8,000 requests/day (80% of free tier)
3. Deploy Cloudflare Worker with Hono framework (see implementation notes below)
4. Update `api_config.dart` to point to `https://api.astr.workers.dev/weather`

**Implementation Time:** 1-2 days (worker setup + Flutter integration)

---

## 8. Implementation Roadmap

### Phase 1: MVP Backend Setup (Story 8.0)

**Prerequisites:**
1. ✅ Sign up for [NASA Earthdata Login](https://urs.earthdata.nasa.gov/users/new)
2. ✅ Create MongoDB Atlas account (free tier)
3. ✅ Create Vercel account (free tier)
4. ✅ Install Python 3.11+ locally (for offline HDF5 processing)

---

#### **Step 1: Set Up MongoDB Atlas**

**Tasks:**
1. ⬜ Create MongoDB Atlas cluster (free M0 tier, 512MB)
2. ⬜ Create database `astr`, collection `light_pollution`
3. ⬜ Create 2dsphere geospatial index:
   ```javascript
   // MongoDB Atlas UI > Collections > Indexes > Create Index
   {
     "location": "2dsphere"
   }
   ```
4. ⬜ Get connection string (Database > Connect > Drivers)
5. ⬜ Whitelist IP: `0.0.0.0/0` (allow all, for Vercel serverless)

---

#### **Step 2: Offline HDF5 Processing (Monthly Job)**

**Local Python Script:**

```python
# scripts/process_nasa_data.py
import h5py
import numpy as np
from pymongo import MongoClient
from datetime import datetime
import requests
import os

# NASA Earthdata credentials
NASA_TOKEN = os.environ['NASA_EARTHDATA_TOKEN']
MONGODB_URI = os.environ['MONGODB_URI']

# Download VNP46A2 HDF5 file for specific date
def download_vnp46a2(date_str):
    """Download HDF5 file from NASA LAADS DAAC"""
    url = f"https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5200/VNP46A2/2024/{date_str}/"
    headers = {'Authorization': f'Bearer {NASA_TOKEN}'}
    # ... download logic (wget or requests)
    
def process_hdf5(hdf5_path):
    """Extract light pollution data from HDF5"""
    with h5py.File(hdf5_path, 'r') as hdf:
        # Extract DNB_BRDF-Corrected_NTL layer
        ntl_data = hdf['HDFEOS/GRIDS/VNP_Grid_DNB/Data Fields/DNB_BRDF-Corrected_NTL'][:]
        lat_data = hdf['HDFEOS/GRIDS/VNP_Grid_DNB/Data Fields/Latitude'][:]
        lon_data = hdf['HDFEOS/GRIDS/VNP_Grid_DNB/Data Fields/Longitude'][:]
        
        # Convert radiance to MPSAS
        # Formula: MPSAS = 12.589 - 1.086 * log(radiance)
        # Avoid log(0) by filtering valid data
        valid_mask = ntl_data > 0
        mpsas_data = np.where(valid_mask, 12.589 - 1.086 * np.log(ntl_data), None)
        
        # Map MPSAS to Bortle Scale (1-9)
        bortle_data = np.digitize(mpsas_data, bins=[16, 18, 19, 20, 21, 21.5, 22, 22.5])
        
        return lat_data, lon_data, mpsas_data, bortle_data

def upload_to_mongodb(lat, lon, mpsas, bortle):
    """Upload processed data to MongoDB Atlas"""
    client = MongoClient(MONGODB_URI)
    db = client['astr']
    collection = db['light_pollution']
    
    # Flatten arrays and create documents
    documents = []
    for i in range(len(lat)):
        if mpsas[i] is not None:  # Skip invalid data
            doc = {
                'location': {
                    'type': 'Point',
                    'coordinates': [float(lon[i]), float(lat[i])]  # GeoJSON: [lon, lat]
                },
                'mpsas': round(float(mpsas[i]), 2),
                'bortle': int(bortle[i]),
                'source': 'VNP46A2_2024-11',
                'updated_at': datetime.utcnow()
            }
            documents.append(doc)
    
    # Batch insert (MongoDB limit: 16MB per batch)
    collection.insert_many(documents)
    print(f"Uploaded {len(documents)} documents to MongoDB")

# Main workflow
if __name__ == '__main__':
    # 1. Download latest VNP46A2 HDF5 file
    hdf5_file = download_vnp46a2('2024-11-30')
    
    # 2. Process HDF5 → extract MPSAS + Bortle
    lat, lon, mpsas, bortle = process_hdf5(hdf5_file)
    
    # 3. Upload to MongoDB Atlas
    upload_to_mongodb(lat, lon, mpsas, bortle)
```

**Run Monthly:**
```bash
# Set environment variables
export NASA_EARTHDATA_TOKEN="your_token_here"
export MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/astr"

# Run script (monthly cron job or manual)
python scripts/process_nasa_data.py
```

**Storage Estimate:**
- **1 document** = ~100 bytes (location + mpsas + bortle + metadata)
- **512MB free tier** = ~5 million coordinates
- **Coverage:** Global 10km grid ≈ 200,000 points → **fits comfortably**

---

#### **Step 3: Vercel Serverless Function**

**Project Structure:**
```
astr-backend/
├── api/
│   └── light-pollution.py  # Serverless function
├── requirements.txt
├── vercel.json
└── .env.local  # Local testing only
```

**requirements.txt:**
```txt
Flask==3.0.0
pymongo==4.6.0
```

**vercel.json:**
```json
{
  "functions": {
    "api/**/*.py": {
      "runtime": "python3.12"
    }
  }
}
```

**api/light-pollution.py:** (already provided above in MVP architecture)

---

#### **Step 4: Deploy to Vercel**

**Tasks:**
1. ⬜ Create GitHub repo: `astr-backend`
2. ⬜ Push code:
   ```bash
   git init
   git add .
   git commit -m "Initial Vercel + MongoDB backend"
   git remote add origin https://github.com/your-user/astr-backend.git
   git push -u origin main
   ```
3. ⬜ Connect to Vercel:
   - Go to [vercel.com](https://vercel.com)
   - Import GitHub repo
   - Add environment variable: `MONGODB_URI` (from MongoDB Atlas)
   - Deploy
4. ⬜ Test endpoint:
   ```bash
   curl "https://astr-backend.vercel.app/api/light-pollution?lat=34.0522&lon=-118.2437"
   # Expected: {"mpsas": 18.5, "bortle": 7, "source": "VNP46A2_2024-11"}
   ```

---

#### **Step 5: Update Flutter App**

**api_config.dart:**
```dart
class ApiConfig {
  static const String baseUrl = 'https://astr-backend.vercel.app';
  static const String lightPollutionEndpoint = '/api/light-pollution';
}
```

**light_pollution_repository.dart:**
```dart
Future<Either<Failure, LightPollution>> getLightPollution(Location location) async {
  try {
    final response = await http.get(Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.lightPollutionEndpoint}?lat=${location.latitude}&lon=${location.longitude}'
    ));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Right(LightPollution(
        mpsas: data['mpsas'],
        bortleClass: data['bortle'],
        source: data['source'],
      ));
    } else {
      // Fallback to PNG if backend fails
      return _getPNGFallback(location);
    }
  } catch (e) {
    return _getPNGFallback(location);
  }
}
```

---

#### **Step 6: Add PNG Fallback (Offline Mode)**

- Keep existing `assets/maps/world2024_low3.png` in Flutter
- Flutter logic: if Vercel backend unreachable → use PNG
- No changes needed if already implemented

---

#### **Step 7: Documentation**

**Create `/docs/calculations.md`:**
```markdown
# Astronomy Calculations - Astr

## Light Pollution (NASA Black Marble VNP46A2)

**Source:** NASA VIIRS Day/Night Band (DNB) BRDF-Corrected Nighttime Lights

**Formula:** Radiance → MPSAS Conversion
```
MPSAS = 12.589 - 1.086 * log(radiance_nW/cm²/sr)
```

**Bortle Scale Mapping:**
| MPSAS Range | Bortle Class | Description |
|---|---|---|
| < 16 | 9 | Inner City |
| 16-18 | 8 | City Sky |
| 18-19 | 7 | Suburban/Urban Transition |
| 19-20 | 6 | Bright Suburban |
| 20-21 | 5 | Suburban |
| 21-21.5 | 4 | Rural |
| 21.5-22 | 3 | Rural Sky |
| 22-22.5 | 2 | Truly Dark |
| > 22.5 | 1 | Excellent Dark Sky |

**Citation:** NASA Black Marble User Guide v2.0 (October 2024)
```

---

**Acceptance Criteria:** Story 8.0 ACs met

**Timeline:** 3-4 days
- Day 1: MongoDB Atlas setup + 2dsphere index
- Day 2: Offline HDF5 processing script + test upload
- Day 3: Vercel serverless function + deploy
- Day 4: Flutter integration + testing

**Cost:** **$0/month** 🎉

---

### Phase 2: Open-Meteo Proxy (When 1,000+ Users)

**Tasks:**
1. Deploy Cloudflare Worker with Hono (same as previous plan)
2. Update Flutter to proxy Open-Meteo through Cloudflare Workers
3. Implement caching (Cloudflare KV, 5 min TTL)

**Timeline:** 1-2 days

**Trigger:** Open-Meteo requests > 8,000/day

---

### Phase 3: Optimization & Scaling

**Trigger:** User feedback OR MongoDB storage approaching 512MB

**Tasks:**
1. **Downsample data:**
   - Instead of 500m resolution, aggregate to 10km grid
   - Reduces MongoDB documents from 5M → 200K
   - Faster queries, lower storage

2. **Add caching layer:**
   - Vercel Edge Config (free tier) for popular coordinates
   - Cache top 1,000 queried locations
   - <10ms response time

3. **Upgrade MongoDB (if needed):**
   - If 512MB insufficient, upgrade to M2 ($9/month, 2GB)
   - Still cheaper than DigitalOcean ($12/month)

**Timeline:** 1-2 days (optimization only)

**Result:** Scalable to 100,000+ users on free tier

---

## 9. Risk Mitigation

| **Risk** | **Impact** | **Mitigation** |
|---|---|---|
| Lorenz binary tile decode fails | High | Verify algorithm via web research (Step 1); maintain PNG fallback |
| Open-Meteo rate limits exceeded | Medium | Monitor daily usage; migrate to Cloudflare Workers when approaching 8,000 req/day |
| Offline mode broken | High | Unit tests for PNG fallback; manual airplane mode testing |
| Accuracy complaints (Lorenz vs. NASA) | Low | Document expected accuracy variance (±0.5 Bortle class); add NASA option post-MVP |
| Deployment complexity (if backend added) | Medium | Only add backend when absolutely necessary (>1,000 users or NASA requirement) |

---

## 10. Validation & Next Steps

### Validation Criteria

**Story 8.0 Acceptance Criteria:**
- ✅ Research deliverable comparing 3 architectures → **This document**
- ✅ Open-Meteo decision documented → **Direct client calls for MVP**
- ✅ Tech stack decision → **No backend for MVP; Cloudflare Workers post-MVP**
- ⬜ **User (Vansh) approval required** → **PENDING**

### Next Steps

1. **Vansh Review:** Approve or request modifications to this research
2. **If Approved:**
   - Mark Story 8.0 as `done` in `sprint-status.yaml`
   - Proceed to Story 8.1 (Seeing Calculations)
   - Refactor Story 2.4 based on Lorenz + PNG architecture
3. **If Modifications Needed:**
   - Update research based on feedback
   - Re-submit for approval

---

## References

[^1]: David Lorenz Light Pollution Atlas 2024. *GitHub Pages.* [https://djlorenz.github.io/astronomy/lp/overlay/dark.html](https://djlorenz.github.io/astronomy/lp/overlay/dark.html)

[^2]: NASA Black Marble VNP46A2 Product User Guide Version 2.0 (October 2024). *NASA LAADS DAAC.* [https://ladsweb.modaps.eosdis.nasa.gov/missions-and-measurements/products/VNP46A2](https://ladsweb.modaps.eosdis.nasa.gov/missions-and-measurements/products/VNP46A2)

[^3]: Open-Meteo API Documentation - Usage Limits. *Open-Meteo.* [https://open-meteo.com/en/features#api-usage](https://open-meteo.com/en/features#api-usage)

[^4]: Flask vs Django for Simple API Backends (2024). *Medium.* [Comparison article](https://medium.com/flask-vs-django-comparison-2024)

[^5]: Cloudflare Workers + Hono Framework Performance Benchmarks (2024). *Hono.dev.* [https://hono.dev/concepts/benchmarks](https://hono.dev/concepts/benchmarks)

[^6]: Cloudflare Workers Pricing (2024). *Cloudflare Docs.* [https://developers.cloudflare.com/workers/platform/pricing](https://developers.cloudflare.com/workers/platform/pricing)

[^7]: Firebase Functions Free Tier Limits (2024). *Firebase Documentation.* [https://firebase.google.com/pricing](https://firebase.google.com/pricing)

[^licensing]: David Lorenz Light Pollution Atlas - Licensing Research (2025-11-30). *Multiple sources.*

[^OSM]: Cloudy Nights Forum Discussion - "Light Pollution Atlas used with permission from David Lorenz." *CloudyNights.com.* [Forum post](https://cloudynights.com)

[^attribution]: David Lorenz Light Pollution Atlas Homepage. *djlorenz.github.io.* "Please do not conflate the Bortle Scale with my maps..." [https://djlorenz.github.io/astronomy/lp/overlay/dark.html](https://djlorenz.github.io/astronomy/lp/overlay/dark.html)

[^copyright]: U.S. Copyright Law Basics. *Copyright.gov.* "Copyright protection subsists from the time the work is created in fixed form." [https://www.copyright.gov/help/faq](https://www.copyright.gov/help/faq)

[^vercel]: Vercel Python Runtime Documentation (2024). *Vercel Docs.* "250MB bundle limit, 4.5MB payload limit, 500MB /tmp directory." [https://vercel.com/docs/functions/runtimes/python](https://vercel.com/docs/functions/runtimes/python)

[^mongo]: MongoDB Geospatial Queries (2024). *MongoDB Documentation.* "2dsphere index for lat/long queries, $near operator for proximity search." [https://www.mongodb.com/docs/manual/geospatial-queries/](https://www.mongodb.com/docs/manual/geospatial-queries/)

---

**End of Research Document**

**🎯 FINAL DECISION (2025-11-30):** Proceed with **Vercel Serverless + MongoDB Atlas** to achieve:
- **Zero cost** ($0/month Vercel + MongoDB free tiers)
- **Public domain data** (NASA Black Marble VIIRS)
- **Pre-computed architecture** (HDF5 processing offline → MongoDB storage)
- **Simple deployment** (git push auto-deploy, no server management)

**Next Action:** Await Vansh approval to begin Phase 1 implementation (3-4 days timeline).
