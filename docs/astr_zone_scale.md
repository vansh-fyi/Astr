# Astr Zone Scale: Specification

**Version:** 2.0
**Status:** Adopted 2026-10-09 (decision D1). Supersedes v1.0, which was marked "LOCKED" but mixed units.
**Reference implementations:** `scripts/astr_zone.py` (Python), `lib/core/utils/astr_zone_scale.dart` (Dart)
**Test vectors:** `test/fixtures/astr_zone_scale.vectors.json`, run by `python3 scripts/test_astr_zone.py` and
`flutter test test/core/utils/astr_zone_scale_test.dart`

Items marked **(unverified)** were not checked against a primary source. Items marked **(proposal)** are
not yet decided.

---

## 1. What a zone is

A zone is a band of **artificial sky brightness relative to the natural sky**, at the zenith, on a clear
night with a standard atmosphere and no moon.

    r = L_artificial / L_natural

- `L_natural` = 174 µcd/m², which is 22.0 mag/arcsec² by convention (Falchi et al. 2016).
- `L_artificial` is the zenith luminance added by artificial light (satellite radiance plus skyglow, see §6).
- `r = 0` is a natural sky. `r = 1` means artificial light equals the natural background.

The scale is a doubling ladder. Each zone edge is twice the one before it, starting at `r = 0.32`.
Boundaries are **lower-inclusive**: a value on an edge belongs to the higher zone.

    zone(r) = 1                            if r < 0.32
            = 2 + floor(log2(r / 0.32))    if 0.32 <= r < 40.96
            = 9                            if r >= 40.96

Implementations compare against the edge list (below) rather than computing a logarithm, so values on an
edge never fall to the wrong side through rounding.

| Zone | r from | r to | L_art from (µcd/m²) | SQM at lower edge | NELM at lower edge |
|---|---|---|---|---|---|
| 1 | 0 | 0.32 | 0 | 22.00 | 6.62 |
| 2 | 0.32 | 0.64 | 56 | 21.70 | 6.48 |
| 3 | 0.64 | 1.28 | 111 | 21.46 | 6.37 |
| 4 | 1.28 | 2.56 | 223 | 21.11 | 6.17 |
| 5 | 2.56 | 5.12 | 445 | 20.62 | 5.89 |
| 6 | 5.12 | 10.24 | 891 | 20.03 | 5.52 |
| 7 | 10.24 | 20.48 | 1782 | 19.37 | 5.05 |
| 8 | 20.48 | 40.96 | 3564 | 18.67 | 4.51 |
| 9 | 40.96 | none | 7127 | 17.94 | 3.92 |

SQM and NELM are derived, not primary (§2). A doubling is 0.753 mag, so adjacent zones differ by about
three quarters of a magnitude of sky brightness.

### Why this ladder

1. It reproduces the production data. Converting the radiance thresholds that built `zones.db` into
   ratios gives 0.32, 0.60, 1.11, 2.76, 6.41, 11.5, 22.1 and 41.8, each within 0.87 to 1.25 times the
   ladder edge (see §5).
2. It matches the class edges of the Falchi et al. 2016 atlas, which are artificial/natural ratios
   `<0.01, 0.01-0.02, 0.02-0.04, 0.04-0.08, 0.08-0.16, 0.16-0.32 ...`, with the Milky Way lost at about
   1.28 to 2.56 and a top class above about 41 (>7130 µcd/m²).
   ([Falchi et al. 2016](https://pmc.ncbi.nlm.nih.gov/articles/PMC4928945/)) The doubling between the
   quoted values is inferred **(unverified: confirm against the paper's legend)**.
3. Consequences: **zone 4 is the Milky Way fading band** and **zone 9 is Falchi's top class**. Zone 1
   merges the six darkest Falchi classes, because below `r = 0.32` the sky is within a third of natural
   and the sky differences are below what a stargazer can use.

Zone names (such as "Bortle") are not used. Bortle may appear only in a note as a rough correspondence.

## 2. Conversions

| From | To | Formula |
|---|---|---|
| r | SQM (mag/arcsec²) | `SQM = 22.0 - 2.5 log10(1 + r)` |
| SQM | r | `r = 10^(0.4 (22.0 - SQM)) - 1`, floored at 0 |
| r | L_art (µcd/m²) | `L_art = 174 r` |
| SQM | NELM | `NELM = 7.93 - 5 log10(10^(4.316 - SQM/5) + 1)` |

The NELM relation is an empirical fit between SQM readings and observers' limiting magnitudes
([Unihedron/AAVSO](https://en.wikipedia.org/wiki/Limiting_magnitude)). It is informative: the zone
definition does not depend on it. A real SQM meter reading includes starlight above the 22.0 baseline, so
dark-site readings sit a little brighter than 22.0 (Falchi notes this) and measured values must be
adjusted before comparison (§7).

## 3. Edge cases

| Input | Result |
|---|---|
| `r < 0` | Treated as 0, zone 1 |
| `r` is NaN | Error (`ValueError` in Python, `ArgumentError` in Dart) |
| `r = +infinity` | Zone 9 |
| Cell absent from `zones.db` | Implicit zone 1 (`r < 0.32`), SQM treated as 22.0 |
| `sqm >= 22.0` | `r = 0` |

## 4. Data and API names (known debt)

The stored record is `(h3, zone, radiance, sqm)`, 20 bytes, sorted by H3 index, with a 16-byte
`ASTR` header. Only cells in zone 2 or above are stored.

Names are misleading today and will change with a new API version:

| Today | Holds | Should be |
|---|---|---|
| JSON `bortle` | the Astr zone | `zone` |
| JSON `ratio` (and `ZoneData.ratio`) | the **radiance** in nW/cm²/sr | `radiance`; `r` becomes the ratio |
| `bortleClass` (older code) | the Astr zone | `astrZone` (already renamed in Dart) |

## 5. Pipeline chains

**Legacy v2 (what built the current `zones.db`).** Radiance `R` is the VIIRS value plus modelled skyglow
(§6), in nW/cm²/sr. The zone comes from radiance thresholds, and SQM from a fit.

    zone thresholds (R):   0.25  0.5  1  3  9  20  50  125   (zones 2 to 9)
    SQM = 22.0 - 1.7 log10(1 + 2R)      (clamped to 16..22)
    implied r = (1 + 2R)^0.68 - 1

**Target v3 (after calibration, §7).** The zone is defined on `r` only.

    L_art = k * R_eff       (k fitted, µcd/m² per nW/cm²/sr)
    r = L_art / 174
    zone = zone(r)

Until v3 exists, a zone derived from the legacy chain with the ladder is the best available value.

### Impact of adopting the ladder on the current `zones.db`

Computed on all 37,528,537 stored cells (radiance to implied r to ladder zone, compared with the stored
zone):

- **86.4% of cells keep their zone. 13.6% (5,115,892 cells) move by exactly one zone.** None moves by more.
- 2,059,079 cells move up and 3,056,813 move down.
- The radiance bands that change zone under the legacy chain:

| Zone boundary | Legacy threshold R | Ladder edge as R | Band that changes |
|---|---|---|---|
| 2 | 0.25 | 0.252 | 0.25 to 0.252 |
| 3 | 0.50 | 0.535 | 0.50 to 0.535 |
| 4 | 1.0 | 1.18 | 1.0 to 1.18 |
| 5 | 3.0 | 2.74 | 2.74 to 3.0 |
| 6 | 9.0 | 6.68 | 6.68 to 9.0 |
| 7 | 20 | 17.0 | 17.0 to 20 |
| 8 | 50 | 45.0 | 45.0 to 50 |
| 9 | 125 | 121 | 121 to 125 |

- Of the 25 validation cities, only Anchorage changes (zone 8 to 9, radiance 124.66, right on the edge).

| Stored zone | Cells | Ladder zone |
|---|---|---|
| 2 | 8,202,608 | 110,553 move to 1, rest stay |
| 3 | 8,293,687 | 739,944 move to 2, rest stay |
| 4 | 12,642,073 | 2,206,316 move to 3, 767,996 move to 5, rest stay |
| 5 | 5,391,071 | 958,694 move to 6, rest stay |
| 6 | 1,649,166 | 252,612 move to 7, rest stay |
| 7 | 962,315 | 75,916 move to 8, rest stay |
| 8 | 336,408 | 3,861 move to 9, rest stay |
| 9 | 51,209 | all stay |

This analysis is not a validation of accuracy. It measures only how the new definition would change today's
data. Accuracy is §7.

## 6. Skyglow in the radiance (unchanged by this spec)

VIIRS looks down and measures upward light, but a ground observer sees light scattered through the air from
cities tens of kilometres away. `apply_skyglow.py` adds that with a Garstang-type kernel
(Garstang 1986, PASP 98, 364; [Cinzano et al. 2001](https://ar5iv.arxiv.org/html/astro-ph/0108052)).
See `docs/skyglow_propagation.md` for the parameters, which are the production values (fraction 0.06).

## 7. Calibration and validation protocol (proposal)

Goal: replace the legacy fit with a physical chain whose error is measured against ground data, and publish
the result.

**Data.**
- Calibration and validation use open ground measurements: Globe at Night (CC BY 4.0,
  [data](https://globeatnight.org/maps.php)) and other openly licensed SQM networks (to be found and checked
  one by one **(unverified)**).
- Falchi 2016 (CC BY-NC 4.0) and the Lorenz atlas are **comparison references only**. Neither is used to fit
  a parameter, and neither is redistributed.
- Select only readings taken in astronomical darkness, moonless, and clear.
- Convert SQM readings to artificial luminance by subtracting a natural baseline, as Falchi did, so a pristine
  site does not read as artificially lit.

**Model parameters to fit.** `k`; the kernel fraction, scale length, power and reference distance; optionally
a radius beyond 80 km. Falchi integrates to 195 km, so test whether 80 km truncates real skyglow.

**Procedure.**
1. Freeze a snapshot of the stations and the VNL composite, and record their hashes.
2. Split by region (leave-region-out), not by random station, because nearby stations see the same radiance
   field and would leak.
3. Fit on training regions by least squares on `SQM_meas - SQM_model` in magnitudes.
4. Report on held-out regions only.
5. Evaluate the legacy chain on the same stations as the baseline.

**Metrics, per stratum (zones 1-3, 4-6, 7-9 by model r) and overall.**
- Bias, MAE and RMSE in mag/arcsec².
- Zone confusion matrix and the share of stations within ±1 zone.
- Station count per stratum, so thin strata are visible.

**Adoption rule.** The calibrated chain replaces the legacy chain only if its held-out RMSE beats the
legacy baseline by a stated margin. Otherwise keep the legacy chain, with the ladder applied. Proposed
targets, to be set after the baseline is measured: absolute bias at most 0.10 mag/arcsec², RMSE at most
0.30. For reference, Falchi reports a residual of 0.15 mag/arcsec² for the atlas.

**Failure tags.** Every failing station gets a cause: aurora or polar noise, equatorial cloud, snow,
altitude, local lighting, or no data. The existing 25-city check already tags Reykjavik, Singapore and
Ushuaia this way.

**Known model issues to test during calibration (found by reading the code).**
- The kernel uses a fixed 5.55 km pixel. East-west pixel width shrinks with the cosine of latitude, so the
  skyglow footprint is distorted away from the equator.
- Self-scatter inside the 5.5 km coarse pixel is excluded, which may under-count near-field skyglow.
- The 80 km radius is shorter than Falchi's 195 km.
- No elevation, mountain screening, or aerosol variation is modelled.
- VIIRS is blind below 500 nm, so white LED lighting is under-counted. Clouds can amplify skyglow near
  cities by up to ten times (Falchi 2016).
- The accumulator keeps the maximum value per cell, so scatter parameters can only be lowered by resetting
  it, as the 0.12 to 0.06 retune did.

**Deliverables.** `scripts/calibrate_zones.py`, a validation report with the tables above, the station list
with attributions, and a website page that reproduces the headline numbers.

## 8. Changelog

- **2.0 (2026-10-09):** Zones defined on the artificial/natural ratio as a doubling ladder from 0.32. Natural
  luminance corrected to 174 µcd/m² and given its correct unit. Test vectors and Dart and Python references
  added. Calibration and validation protocol added. SQM and NELM become derived quantities.
- **1.0:** Defined `LPI = radiance / 0.171` with a factor of 2.5 per zone from 0.05. It applied a luminance
  constant (mcd/m²) to a radiance (nW/cm²/sr), so its edges did not match the production data.
