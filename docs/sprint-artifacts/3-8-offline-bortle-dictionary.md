# Story 3.8: Offline Bortle Dictionary

Status: review

## Story

As a user,
I want accurate Light Pollution (Bortle) data for my city even when offline,
so that I don't get misleading information (e.g., "Class 4" for a bright city like Delhi).

## Acceptance Criteria

1. **Hybrid City Database:**
   - **Given** the app initializes, **When** loading light pollution data, **Then** it must load a compact "City Dictionary" (KD-Tree) containing ~15,000 major cities with confirmed Bortle values.
   - **Constraint:** The dictionary asset file must be < 2MB.

2. **Offline Lookup Logic (Nearest Neighbor):**
   - **Given** a user location, **When** checking Bortle Class, **Then**:
     1. Query the KD-Tree for the *nearest* city within 10km.
     2. **If Found (<10km):** Return that city's stored Bortle value (High Precision).
     3. **If Not Found (>10km):** Fallback to the existing "World Map" pixel-lookup (Rural/fallback logic).

3. **Accuracy Validation:**
   - **Given** urban coordinates (e.g., Delhi, NYC), **When** queried offline, **Then** the logic MUST return the dictionary value (e.g., Class 8/9).
   - **Given** rural coordinates (e.g., Sahara Desert), **When** queried, **Then** it must fallback to the map (Class 1/2).

4. **Performance:**
   - The KD-Tree lookup must be instant (< 50ms) and non-blocking.

## Tasks / Subtasks

- [x] Data Preparation
  - [x] Create `scripts/generate_city_db.py` to merge WorldCities Dataset with Light Pollution Atlas.
  - [x] Generate `assets/db/cities.json` (or compact binary format).
- [x] KD-Tree Implementation
  - [x] Create `algorithms/kd_tree.dart` (or use `kdtree` package if available and lightweight).
  - [x] Implement `nearestNeighbor(lat, lon)` search.
- [x] Service Integration
  - [x] Modify `OfflineLPDataSource` to load the KD-Tree on startup.
  - [x] Implement the "Dictionary First, Map Second" fallback logic.
- [x] Testing
  - [x] Unit Test: `KDTree.search` with known points.
  - [x] Integration Test: `getBortleClass` returns correct values for test cities vs rural points.

## Dev Notes

- **Architecture:** `core/services/light_pollution`.
- **Data Structure:** KD-Tree is O(log n) for search, perfect for static point data.
- **Optimization:** Store Lat/Lon as doubles. Bortle as int.
- **Asset Split:** Keep the KD-tree separate from the Image Map to allow independent updates.

### Context Reference

- [Context XML](3-8-offline-bortle-dictionary.context.xml)

### References

- [Source: docs/epics.md#Story 1.3](#story-13-hybrid-light-pollution-logic) - Enhances the fallback logic defined in Story 1.3.

---

## Senior Developer Review (AI)

**Reviewer:** Vansh  
**Date:** 2025-12-09  
**Outcome:** 🚫 **BLOCKED**

### Summary

The code implementation is **architecturally sound and correctly structured**. KD-Tree algorithm (`kd_tree.dart`) is well-implemented with Haversine distance. The `OfflineLPDataSource` correctly integrates "Dictionary First, Map Second" fallback logic. All 24 unit tests pass. **HOWEVER, the `cities.json` data file contains only ~16 cities (287 bytes), far below the required ~15,000 cities (<2MB).** The generation script exists but must be successfully executed to produce production data.

---

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
|-----|------------|--------|----------|
| AC 1 | Hybrid City Database (~15,000 cities, <2MB) | **NOT MET** | `cities.json` is 287 bytes with only 16 cities. Script `generate_city_db.dart` exists but download failed, leaving fallback data only. |
| AC 2 | Offline Lookup (Nearest Neighbor, 10km fallback) | **IMPLEMENTED** | `offline_lp_data_source.dart:62-120` implements KD-Tree lookup with 10km max, falls back to map. `kd_tree.dart:64-76` implements `nearest()` with Haversine. |
| AC 3 | Accuracy Validation (Delhi/NYC vs Sahara) | **PARTIAL** | Unit tests exist for Delhi/NYC (`kd_tree_test.dart:65-79`), integration tests exist (`offline_lp_data_source_test.dart:27-53`). However, production accuracy cannot be validated until full city DB is generated. |
| AC 4 | Performance (<50ms, non-blocking) | **IMPLEMENTED** | KD-Tree is O(log n) algorithm. No async/await blocks in search. Lazy loading with simple mutex (`offline_lp_data_source.dart:65-77`). |

**Summary:** 2 of 4 ACs implemented, 1 partial, 1 NOT MET (blocker).

---

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
|------|-----------|-------------|----------|
| Create `generate_city_db.py` | `[ ]` (Incomplete) | **DONE** | `scripts/generate_city_db.dart` exists (Dart, not Python) |
| Generate `assets/db/cities.json` | `[ ]` (Incomplete) | **PARTIAL** | File exists but contains only fallback data (287 bytes) |
| Create `kd_tree.dart` | `[ ]` (Incomplete) | **DONE** | `lib/core/engine/algorithms/kd_tree.dart` (177 lines) |
| Implement `nearestNeighbor` search | `[ ]` (Incomplete) | **DONE** | `kd_tree.dart:64-168` with Haversine distance |
| Modify `OfflineLPDataSource` | `[ ]` (Incomplete) | **DONE** | `offline_lp_data_source.dart:56-89` integrates KD-Tree |
| Implement fallback logic | `[ ]` (Incomplete) | **DONE** | "Dictionary First, Map Second" in `getBortleClass()` |
| Unit Test: KDTree.search | `[ ]` (Incomplete) | **DONE** | `kd_tree_test.dart` (5 tests, all pass) |
| Integration Test: getBortleClass | `[ ]` (Incomplete) | **DONE** | `offline_lp_data_source_test.dart` (19 tests, all pass) |

**Summary:** 7 of 8 tasks verified complete but NOT MARKED. 1 task (data generation) is PARTIAL.

---

### Test Coverage and Gaps

**Covered (24 tests pass):**
- ✅ KDTree construction from flat list
- ✅ Exact match lookup
- ✅ Nearest neighbor within range
- ✅ Null return when out of range
- ✅ Delhi fallback verification
- ✅ NYC/London/Sahara integration tests
- ✅ Cache behavior tests
- ✅ Service fallback logic

**Gaps:**
- ❌ No test verifying city count matches ~15,000
- ❌ No test verifying asset size is <2MB
- ❌ No performance benchmark test (though O(log n) is inherently fast)

---

### Architectural Alignment

✅ **Compliant with Architecture:**
- Pure Dart KD-Tree implementation (no external GIS dependencies)
- Lazy loading on first use (no startup blocking)
- Graceful degradation (map fallback if KD-Tree fails)
- File structure: `core/engine/algorithms/kd_tree.dart` ✓
- Service location: `core/services/light_pollution/` ✓

---

### Security Notes

No security concerns. Local data only, no external API calls in offline path.

---

### Best-Practices and References

- [SimpleMaps World Cities Database](https://simplemaps.com/data/world-cities) - Data source for city generation
- [KD-Tree Algorithm](https://en.wikipedia.org/wiki/K-d_tree) - O(log n) nearest neighbor search

---

### Action Items

**BLOCKERS (Must Fix):**
- [ ] [CRITICAL] Run `dart scripts/generate_city_db.dart` successfully OR manually download WorldCities CSV and regenerate `cities.json` with ~15,000 cities
- [ ] [HIGH] Verify regenerated `cities.json` is <2MB and contains 10,000+ cities

**Code Changes Required:**
- [ ] [Low] Update task checkboxes to `[x]` for completed tasks [file: docs/sprint-artifacts/3-8-offline-bortle-dictionary.md]
- [ ] [Low] Add asset size validation test (verify <2MB)

**Advisory Notes:**
- Note: The generation script uses Python URL but is actually Dart (`generate_city_db.dart` not `.py`)
- Note: Consider adding a CI step to validate city count on asset changes

---

## Change Log

| Date | Version | Description |
|------|---------|-------------|
| 2025-12-09 | 1.1 | Senior Developer Review notes appended |
