# Sprint Change Proposal - Calculation Accuracy & UI Preservation

**Date:** 2025-11-30  
**Scrum Master:** Bob  
**Scope:** Major  
**Status:** Pending Approval

---

## 1. Issue Summary

### Problem Statement

Astr workflows are destroying manually-refined UI and implementing calculations without transparency or accuracy validation. Core issues:

1. **UI Preservation Failure** — Workflows repeatedly override user's 5-segment visibility bar and "Zone 4" card designs, forcing manual token-expensive fixes after every dev cycle
2. **Calculation Accuracy Unknown** — Lorenzo binary tiles logic questionable, no location permission enforcement, missing critical calculations (Moon altitude/transit/set, Seeing, Darkness r^6, Humidity, Temperature)
3. **Documentation Drift** — Obsolete Rive animation references, Open-Meteo routing through Cloudflare Workers inconsistent with free/keyless API status
4. **Process Gaps** — No mandate for web research on domain-specific astronomy formulas; agent implementing without math transparency

### Discovery Context

- **Triggering Story:** 2.4 ("Real Visibility Data") marked DONE but implementation incomplete
- **Evidence:**
  - App never requests location permission on launch → no weather/light pollution data possible
  - Visibility UI manually refined 3+ times (5-segment scale, Zone cards, glass panels) → workflows revert to outdated Rive-based design from stale docs
  - Missing calculations: Moon ALT/Transit/Set, Seeing (Pickering scale), Darkness quality (r^6), Humidity/Temp sources unclear
  - Data source confusion: Lorenzo binary tiles reverse-engineering may be broken, NASA Black Marble VIIRS & Google Earth Engine alternatives not documented

---

## 2. Impact Analysis

### Epic Impact

| Epic | Status | Impact Level | Required Changes |
|------|--------|--------------|------------------|
| **Epic 2** (Dashboard) | In-progress | **HIGH** | Update Stories 2.1, 2.4 — Remove Rive, add location permission, refactor data sources |
| **Epic 3** (Catalog) | Done | **HIGH** | Add Story 3.4 — Moon altitude/transit/set calculations missing |
| **Epic 4** (Planning) | In-progress | **MEDIUM** | Add Story 4.x — Cloud cover graph for Atmospheric drawer (Open-Meteo) |
| **Epic 5** (Profile) | Done | **LOW** | No changes |
| **Epic 6** (Security) | Review | **HIGH** | Modify Story 6.1 — Open-Meteo bypasses Cloudflare Workers (direct client OK) |
| **Epic 7** (Visual Polish) | Backlog | **MEDIUM** | Add UI preservation documentation requirements |
| **NEW Epic 8** | N/A | **CRITICAL** | Create "Calculation Accuracy & Math Transparency" epic |

### Artifact Conflicts

**PRD (`docs/PRD.md`):**
- **Conflict:** No mention of Light Pollution data source alternatives (Lorenzo, NASA, GEE)
- **Conflict:** Location permission not enforced as requirement
- **Conflict:** Rive animations listed (line 109) — obsolete
- **Conflict:** Bortle Scale described as "1-9 bar" — current UI is 5-segment scale
- **Required Fix:** Add FR15.1 (Data Sources), FR15.2 (Location Permission), NFR (Math Transparency); remove Rive; update UI descriptions

**Architecture (`docs/architecture.md`):**
- **Conflict:** "Rive Pattern" documented (lines 42, 144-150) — not used in project
- **Conflict:** Proxy Pattern mandates Cloudflare Workers for ALL external APIs — Open-Meteo is keyless/free, direct client acceptable
- **Conflict:** No Light Pollution Service architecture described
- **Required Fix:** Remove Rive Pattern, add Light Pollution pattern, modify Proxy Pattern for Open-Meteo exception, document NASA/GEE alternatives

**UI/UX Specifications:**
- **Conflict:** Epic/Story docs describe outdated Rive-based UI; current UI manually refined (5-segment bars, Zone cards)
- **Required Fix:** Create `docs/ui-design-system.md` capturing current component designs; update Epic 2 Story 2.1 ACs

**Tech Specs (Epic 2-6):**
- **Conflict:** Missing math formulas, data source alternatives
- **Required Fix:** Add calculation documentation (Seeing formula, r^6 Darkness, Moon ephemeris)

**Story Context XMLs:**
- **Conflict:** May reference Rive, old UI patterns
- **Required Fix:** Audit all contexts, remove Rive, update UI descriptions

---

## 3. Recommended Approach

### Selected Path: Option 1 - Direct Adjustment + Process Enhancements

**Rationale:**
1. **Effort vs. Value:** Medium effort (doc updates + Epic 8 creation) yields high value (fixes root causes without scope reduction)
2. **Technical Risk:** Low — Incremental story updates, no rollback needed
3. **Team Impact:** Positive — Addresses user's repeated UI fix frustration, establishes sustainable process
4. **Timeline:** MVP maintained — Issues are fixable within existing sprint capacity
5. **Long-term Sustainability:** Process improvements prevent future rework cycles

**Alternatives Considered:**
- **Option 2 (Rollback):** Rejected — No benefit from reverting completed work; doesn't address systemic issues
- **Option 3 (MVP Scope Reduction):** Rejected — Problems are solvable; reducing scope unnecessary

**Effort Estimate:** Medium (12-15 days across 3 phases)

**Risk Assessment:** Low
- **Risk:** Documentation updates may reveal additional gaps
- **Mitigation:** Incremental review with user approval at each phase

---

## 4. Detailed Change Proposals

### Phase 1: Documentation Fixes (1-2 days)

#### **Change 1.1: Update PRD**
**File:** `docs/PRD.md`

**Section:** Functional Requirements (after FR15)

**ADD:**
```markdown
### FR15.1: Light Pollution Data Sources
**Requirement:** System must support multiple light pollution data sources with fallback strategy.

**Supported Sources:**
1. **David Lorenz Binary Tiles** (Primary) — `djlorenz.github.io/astronomy/lp/overlay/dark.html`
   - Format: `.dat.gz` tiles (600x600)
   - Precision: High (precise lat/long lookups)
   - Offline: Cacheable
2. **NASA Black Marble VIIRS** (Alternative) — Requires Python backend (HDF5/h5py)
   - Format: HDF5 files
   - Precision: Satellite-grade
   - Auth: NASA Earthdata Login required
3. **Google Earth Engine** (Alternative) — VNP46A2 collection
   - Format: Cloud-based API
   - Precision: Satellite-grade
   - Auth: GEE account required
4. **PNG Fallback** (Offline) — Bundled `world2024_low3.png`
   - Format: Equirectangular projection
   - Precision: Low (approximation)
   - Offline: Fully offline-capable

**Acceptance:** App attempts Binary Tiles first, falls back to PNG if network unavailable.

### FR15.2: Location Permission Enforcement
**Requirement:** App MUST request location permission on first launch.

**Behavior:**
- **Granted:** Use GPS for accurate calculations
- **Denied:** Prompt manual location entry, default to last known or fallback coordinates

**Acceptance:** Location permission dialog appears within 3 seconds of app launch.
```

**Section:** Non-Functional Requirements (new section if missing)

**ADD:**
```markdown
### NFR: Math Transparency
**Requirement:** All astronomical calculations must be documented with formulas and authoritative sources.

**Implementation:**
- Inline code comments cite formulas (e.g., "Pickering Seeing Scale: S = k * (FWHM)^-0.6")
- README or `/docs/calculations.md` documents complex algorithms
- Unit tests validate against known reference values (Stellarium, JPL Horizons)

**Rationale:** User has astronomy background; must verify calculation accuracy.
```

**Section:** Line 109 (Rive Animations)

**OLD:**
```markdown
*   **Rive Animations (Star Map Only):** (Future) Potential use of Rive for the AR Star Map, subject to performance review.
```

**NEW:**
```markdown
*   **Custom Canvas Rendering:** High-performance graphs (Visibility Graph, Cloud Cover Graph) use Flutter's `CustomPainter` for pixel-perfect control.
```

**Section:** Line 64, 106 (Bortle Scale description)

**OLD:**
```markdown
*   **Visual Bortle Scale:** Graphical bar (1-9) showing light pollution.
```

**NEW:**
```markdown
*   **Visibility Scale:** 5-segment visual bar with Zone indicator card (e.g., "Zone 4 - Rural") showing light pollution quality.
```

**Rationale:** Aligns PRD with current UI implementation, removes obsolete Rive references, adds missing data source + math transparency requirements.

---

#### **Change 1.2: Update Architecture**
**File:** `docs/architecture.md`

**Section:** Line 42 (Decision Summary table)

**OLD:**
```markdown
| **Animation Engine** | **Rive** | Latest | Interactive vector animations for graphs and star maps. |
```

**NEW:**
```markdown
| **Rendering Engine** | **Custom Canvas** | Flutter SDK | High-performance custom painters for graphs (Visibility, Cloud Cover). |
```

**Section:** Lines 144-150 (Rive Pattern)

**REMOVE ENTIRELY**

**Section:** After Line 143 (add new Light Pollution Pattern)

**ADD:**
```markdown
### D. The "Light Pollution" Pattern (Data Sources)
**Rule:** System must attempt multiple data sources with graceful fallback.
**Why:** Ensures offline capability and resilience against API failures.
**Implementation:**
1. **Primary:** David Lorenz Binary Tiles (`.dat.gz` from `djlorenz.github.io`)
   - Download tile based on lat/long → tile coordinates
   - Cache locally using `path_provider`
   - Decode using Delta-Decoding + compressed2full algorithm
2. **Fallback (Offline):** PNG Map (`assets/maps/world2024_low3.png`)
   - Equirectangular projection (lat/long → pixel coordinates)
   - Luminance heuristic for rough visibility estimate
3. **Future Alternatives:**
   - **NASA Black Marble VIIRS:** Python backend (HDF5/h5py), satellite-grade precision
   - **Google Earth Engine:** VNP46A2 collection, cloud API

**Error Handling:** Return `LightPollution.unknown()` if all sources fail.
```

**Section:** Lines 136-142 (Proxy Pattern)

**OLD:**
```markdown
### C. The "Proxy" Pattern (Security)
**Rule:** NEVER call `open-meteo.com` directly from Flutter.
**Why:** We cannot secure the API usage if the client calls it directly.
```

**NEW:**
```markdown
### C. The "Proxy" Pattern (Security)
**Rule:** APIs requiring keys/auth MUST be proxied through Cloudflare Workers. Free/keyless APIs (Open-Meteo) may be called directly from Flutter.
**Why:** Protects API keys while allowing zero-cost free-tier usage.
**Exception:** Open-Meteo is keyless and free for non-commercial use → Direct client calls acceptable.
```

**Section:** Line 76-77 (External APIs diagram)

**ADD:**
```markdown
        LightPollution[David Lorenz Tiles]
        NASA[NASA Black Marble]
        GEE[Google Earth Engine]
```

**Rationale:** Documents actual rendering approach, adds Light Pollution architecture pattern, removes obsolete Rive references, clarifies Open-Meteo routing.

---

#### **Change 1.3: Create UI Design System Doc**
**File:** `docs/ui-design-system.md` (NEW)

**Content:**
```markdown
# UI Design System - Astr

> **Purpose:** Document current UI component designs to prevent workflow regressions.  
> **Status:** Approved  
> **Last Updated:** 2025-11-30

## Core Principle

**UI changes require explicit Acceptance Criteria approval.** Workflows must NOT modify component aesthetics (colors, padding, layout) unless story AC explicitly defines the change.

---

## Components

### 1. Visibility Bar (BortleBar)

**Current Design (AS-IS):**
- **Height:** 140px (matches Moon card)
- **Layout:**
  - **Top:** "VISIBILITY" label (small, grey text)
  - **Center:** Zone badge (e.g., "Zone 4" in glowy blue pill)
  - **Below badge:** Classification text (e.g., "Rural" in large white text)
  - **Bottom:** MPSAS value display
  - **Bottom:** 5-segment horizontal scale (blue gradient) showing active segment
- **Container:** `GlassPanel` (dark glass: `Color(0xFF121212).withAlpha(0.8)`)
- **Interaction:** `onTap` → opens `AtmosphericsSheet`

**DO NOT:**
- Change to 1-9 Rive animation
- Modify segment count (must remain 5)
- Alter zone badge styling (blue glow preserved)

### 2. Cloud Bar (CloudBar)

**Current Design (AS-IS):**
- **Layout:** Blue → Blue Accent gradient fill based on cloud %
- **Container:** `GlassPanel` (dark glass)
- **Label:** "Cloud Cover" with percentage display

**DO NOT:**
- Change gradient colors (Blue theme mandatory)

### 3. Glass Panel (GlassPanel)

**Current Design (AS-IS):**
- **Background:** `Color(0xFF121212).withAlpha(0.8)`
- **Blur:** Backdrop filter (20px)
- **Border:** 1px white (10% opacity)
- **Padding:** 16px default
- **Border Radius:** 16px

**Parameters:** `child`, `padding` only — NO custom `color`, `blur`, `borderColor` parameters

### 4. General Styling

- **Background:** `Color(0xFF020204)` (Deep Cosmos)
- **Text Colors:** White primary, white70 secondary
- **Accents:** Blue (`Colors.blue`) for active elements
- **Icons:** White default

---

## Enforcement

1. **Story ACs must explicitly define UI changes** (e.g., "AC: Visibility bar uses 7-segment scale")
2. **Workflows preserve existing UI** unless AC mandates change
3. **DoD includes:** "Existing UI styling preserved per `ui-design-system.md`"
```

**Rationale:** Provides authoritative reference for current UI; prevents future workflow regressions.

---

### Phase 2: Epic & Story Refactoring (2-3 days)

#### **Change 2.1: Update Epic 2 Story 2.1**
**File:** `docs/sprint-artifacts/2-1-visual-bortle-cloud-bars.md` (if exists) OR `docs/epics.md` Story 2.1

**Section:** Acceptance Criteria

**OLD:**
```markdown
*   **Bortle Bar:** Visual gradient (1-9). Shows current location's Bortle class.
*   **UX:** Bars animate (fill up) on load (`animate-slide-up`).
```

**NEW:**
```markdown
*   **Visibility Bar:** 5-segment horizontal scale with Zone badge (e.g., "Zone 4") and classification label (e.g., "Rural"). Height: 140px. Uses `GlassPanel` styling per `ui-design-system.md`.
*   **UX:** No animation on load (static display). `onTap` opens Atmospherics sheet.
```

**Rationale:** Matches current implemented UI, removes animation req.

---

#### **Change 2.2: Update Epic 2 Story 2.4**
**File:** `docs/sprint-artifacts/2-4-real-bortle-data.md`

**Section:** Acceptance Criteria

**ADD:**
```markdown
| **AC-2.4.7** | **Location Permission Enforcement:** App requests location permission on first launch. If denied, prompts manual entry. | Manual Test (fresh install). |
| **AC-2.4.8** | **Data Source Alternatives:** If Binary Tiles fail, system documents fallback options (NASA Black Marble, Google Earth Engine) for future implementation. | Code Review (comments/README). |
```

**Section:** Technical Tasks

**MODIFY Task 4.2.1:**

**OLD:**
```markdown
- [x] Implement `BinaryTileService` to fetch `.dat.gz` from `djlorenz.github.io`.
```

**NEW:**
```markdown
- [ ] **Refactor** `BinaryTileService`:
  - Verify Delta-Decoding algorithm via web research (compare against David Lorenz's JavaScript implementation)
  - Add comprehensive logging for debugging tile fetch/decode
  - Document algorithm in code comments with citation
- [ ] Add NASA Black Marble VIIRS option (Python backend stub, documented in README for Phase 2)
- [ ] Add Google Earth Engine option (document API approach in README for Phase 2)
```

**Rationale:** Adds missing location permission AC, mandates algorithm verification, documents alternative data sources.

---

#### **Change 2.3: Create Epic 8**
**File:** `docs/epics.md`

**Section:** After Epic 7

**ADD:**
```markdown
---

## Epic 8: Calculation Accuracy & Math Transparency
**Goal:** Implement missing calculations with documented formulas and authoritative sources.
**Value:** Users trust data accuracy; developer can verify/debug math easily.

### Story 8.1: Seeing Calculations (Pickering Scale)
**As a** Stargazer,
**I want** to see atmospheric "Seeing" quality,
**So that** I know if conditions are stable for planetary observation.

*   **Acceptance Criteria:**
    *   System calculates Seeing using Pickering scale (web research formula).
    *   Formula documented in code comments with citation.
    *   Unit test validates against known reference value.
    *   UI displays Seeing as 1-10 scale with label (e.g., "Excellent").
*   **Technical Notes:**
    *   Research Pickering Seeing scale formula (likely involves humidity, wind, temperature).
    *   Data sources: Open-Meteo (humidity, wind speed, temperature).

### Story 8.2: Darkness Quality (r^6 Calculation)
**As a** Advanced user,
**I want** to see "Darkness" metric based on r^6 formula,
**So that** I understand combined light pollution + moon interference.

*   **Acceptance Criteria:**
    *   System calculates r^6 Darkness (web research: likely David Lorenz's website implementation).
    *   Formula reverse-engineered from `djlorenz.github.io/astronomy/lp/overlay/dark.html`.
    *   Documented in code with citation.
    *   UI displays as 0-100 scale or qualitative label.

### Story 8.3: Humidity & Temperature Display
**As a** User,
**I want** to see current humidity and temperature,
**So that** I know if dew/frost will form on my equipment.

*   **Acceptance Criteria:**
    *   System fetches Humidity + Temperature from Open-Meteo (direct client call).
    *   Displayed in Atmospheric drawer or Dashboard.
    *   Unit: °C and % (user preference for °F in future).

### Story 8.4: Math Documentation & Validation
**As a** Developer,
**I want** all formulas documented and validated,
**So that** I can verify accuracy and debug issues.

*   **Acceptance Criteria:**
    *   Create `/docs/calculations.md` with all astronomy formulas.
    *   Each formula includes:
        *   Mathematical notation
        *   Code implementation reference (file + line)
        *   Authoritative source (Stellarium, JPL, academic paper)
    *   Unit tests compare outputs to known reference values.
```

**Rationale:** Addresses missing calculations identified by user, mandates math transparency.

---

#### **Change 2.4: Add Story 3.4 (Moon Calculations)**
**File:** `docs/epics.md` (Epic 3)

**Section:** After Story 3.3

**ADD:**
```markdown
### Story 3.4: Moon Position Calculations
**As a** User,
**I want** to see Moon altitude, transit, and set times,
**So that** I can plan around moonrise/moonset.

*   **Acceptance Criteria:**
    *   System calculates Moon Altitude (degrees above horizon) for current time.
    *   System calculates Transit time (highest point in sky).
    *   System calculates Set time (when Moon drops below horizon).
    *   Calculations use Swiss Ephemeris (local, offline).
    *   Formula verified against Stellarium or JPL Horizons.
    *   Displayed in Moon card or Object Detail page.
*   **Technical Notes:**
    *   Use existing Swiss Ephemeris integration (Story 1.2).
    *   Research Moon altitude/transit/set calculation (likely `sweph` API methods).
```

**Rationale:** Critical missing functionality identified by user.

---

#### **Change 2.5: Add Story 4.x (Cloud Cover Graph)**
**File:** `docs/epics.md` (Epic 4)

**Section:** After existing Epic 4 stories

**ADD:**
```markdown
### Story 4.x: Atmospheric Drawer - Cloud Cover Graph
**As a** User,
**I want** to see cloud cover forecast for next 12 hours as a graph,
**So that** I can identify clear windows for observation.

*   **Acceptance Criteria:**
    *   Graph displays Cloud Cover % (0-100) on Y-axis, Time on X-axis.
    *   Data fetched from Open-Meteo hourly forecast (direct client call).
    *   Graph renders using `CustomPainter` (no Rive).
    *   Displayed in Atmospherics sheet/drawer.
    *   Updates when location or date changes.
*   **Technical Notes:**
    *   Open-Meteo endpoint: `/v1/forecast?hourly=cloudcover`.
    *   Use `fl_chart` package or custom painter.
```

**Rationale:** Missing feature for Atmospheric drawer, clarifies Open-Meteo usage.

---

#### **Change 2.6: Modify Story 6.1**
**File:** `docs/sprint-artifacts/6-1-secure-api-proxy-cloudflare-workers.md` (if exists)

**Section:** Acceptance Criteria

**MODIFY:**

**OLD (implied):**
```markdown
All external API calls routed through Cloudflare Workers.
```

**NEW:**
```markdown
| **AC-6.1.1** | **API Key Protection:** APIs requiring authentication (none currently) MUST be proxied through Cloudflare Workers. | Code Review. |
| **AC-6.1.2** | **Open-Meteo Exception:** Open-Meteo is keyless/free → Direct client calls from Flutter are acceptable. | Code Review. |
| **AC-6.1.3** | **Future Proxy Readiness:** Cloudflare Worker infrastructure ready if paid/keyed APIs added later. | Architecture validation. |
```

**Rationale:** Clarifies Open-Meteo does NOT require Cloudflare proxy; aligns with PRD free-tier mandate.

---

### Phase 3: Implementation with Web Research (Ongoing)

**Process Changes (for Dev Agent):**

**NEW Rule:** When implementing domain-specific calculations (astronomy, meteorology):
1. **HALT if formula unknown** — Do NOT guess or use generic approximations
2. **Search web first:**
   - David Lorenz's website (`djlorenz.github.io`)
   - NASA documentation (Black Marble VIIRS, JPL Horizons)
   - Academic papers (cite in code comments)
   - Swiss Ephemeris docs (for Moon/planet calculations)
3. **Document in code:**
   - Formula in mathematical notation (e.g., `// Seeing = k * (FWHM)^-0.6`)
   - Source citation (e.g., `// Source: Pickering 1997, cited at pickering-scale-reference.com`)
4. **Validate:** Unit test against known reference (Stellarium, JPL)
5. **Ask user if uncertain** — User has astronomy background; can verify formulas

**Example:**
```dart
// Calculate atmospheric Seeing using Pickering scale
// Formula: S = k * sqrt(temperature_K / humidity_ratio)
// Source: David Lorenz (djlorenz.github.io/astronomy/seeing.html)
// Validated against: Stellarium 23.1 output for 2024-11-30, lat=40.7, temp=15C
double calculateSeeing(double tempCelsius, double humidityPercent) {
  // ... implementation
}
```

**Human Approval Required For:**
- Any calculation without authoritative source citation
- UI changes not explicitly defined in story AC
- Major architectural deviations (e.g., switching from Lorenz to NASA as primary)

---

## 5. Implementation Handoff

### Change Scope Classification: **Moderate**

**Rationale:**
- Significant documentation updates (PRD, Architecture)
- New Epic creation (Epic 8)
- Story rewrites (Epic 2, 3, 4, 6)
- Process rule additions (web research, UI preservation)
- BUT: No scope reduction, no rollbacks, implementable incrementally

### Handoff Recipients

| Role | Responsibility | Timeline |
|------|----------------|----------|
| **Scrum Master (Bob)** | Execute Phase 1 & 2 — Update docs, create Epic 8, rewrite stories | 3-5 days |
| **Developer (Amelia)** | Execute Phase 3 — Implement calculations with web research, math transparency | Ongoing (per story) |
| **User (Vansh)** | Review/approve Phase 1 deliverables, validate math formulas in Phase 3 | As needed |

### Success Criteria

1. **UI Preservation:** Zero UI regressions after workflow runs → `ui-design-system.md` enforced
2. **Location Permission:** App requests permission within 3 seconds of launch
3. **Calculation Transparency:** All formulas documented with citations in code + `/docs/calculations.md`
4. **Data Source Clarity:** Binary Tiles (primary), PNG (fallback), NASA/GEE (documented alternatives)
5. **Open-Meteo Integration:** Cloud cover, humidity, temperature fetched directly (no Cloudflare proxy)
6. **Missing Calculations Implemented:** Moon altitude/transit/set, Seeing, Darkness r^6, Humidity, Temperature

### High-Level Action Plan:

**Phase 1: Documentation Fixes** (1-2 days) ✅ COMPLETED
1. Update PRD (FR15.1, FR15.2, NFR Math Transparency, remove Rive)
2. Update Architecture (remove Rive Pattern, add Light Pollution pattern)
3. Create `ui-design-system.md` (document current 5-segment UI)
4. Audit all Story Context XMLs (remove Rive, update UI references)

**Phase 1.5: Backend Architecture Research & Decision** (2-3 days) 🔬 NEW
5. **Story 8.0 Execution** — Research & compare data source architectures:
   - **Light Pollution:** Lorenz Binary Tiles vs. NASA Black Marble vs. Google Earth Engine
   - **Criteria:** Accuracy, latency, cost, offline capability, complexity, maintenance
   - **Open-Meteo:** Direct client calls vs. backend proxy (rate limit analysis)
   - **Tech Stack:** If backend needed → Flask/Django vs. Cloudflare Workers vs. Firebase Functions
6. **Deliverable:** `docs/backend-architecture-research.md` with recommendation
7. **User Approval Required** — Vansh approves architecture before Story 8.1 begins

**Phase 2: Epic & Story Refactoring** (2-3 days)
8. Update Epic 2 Stories (2.1, 2.4 ACs)
9. Create Epic 8 + Stories (Seeing, Darkness, Humidity, Temp) ✅ DONE
10. Add Story 3.4 (Moon calculations)
11. Add Story 4.x (Cloud cover graph - Open-Meteo)
12. Update Story 6.1 (remove Cloudflare mandate for Open-Meteo)

**Phase 3: Implementation with Web Research** (Ongoing)
13. Dev agent MUST search web for:
    - NASA Black Marble VIIRS integration (HDF5, Python backend)
    - Pickering Seeing scale formula
    - Darkness r^6 calculation
    - Moon altitude/transit/set (Swiss Ephemeris docs)
14. Implement with math transparency (document formulas in code comments)

---

## 6. Next Steps

**Immediate Actions (Vansh):**
1. **Review this proposal** — Approve or request revisions
2. **If approved:** Bob begins Phase 1 documentation updates

**Timeline:**
- **Phase 1:** 1-2 days (doc updates)
- **Phase 2:** 2-3 days (Epic/story refactoring)
- **Phase 3:** Ongoing (per-story implementation)

**Risks & Mitigation:**
- **Risk:** Web research may reveal calculation complexity exceeds estimates
  - **Mitigation:** Ask Vansh for formula validation before implementation; defer to post-MVP if too complex
- **Risk:** Lorenz binary tiles may be incompatible despite refactoring
  - **Mitigation:** NASA Black Marble already documented as alternative; pivot if needed

---

**Prepared by:** Bob (Scrum Master)  
**Date:** 2025-11-30  
**Status:** Awaiting User Approval
