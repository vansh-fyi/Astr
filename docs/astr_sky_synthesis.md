# Astr Sky Synthesis: Specification

**Version:** 1.0 (draft for owner review)
**Status:** The method and the moonlight model are settled. The threshold values marked **(proposal)** are
starting points to tune. Decisions D1 (zone ladder) and D2 (hero shows the best window plus a "right now" chip)
are applied.
**Reference implementations:** `scripts/astr_sky.py` (Python), `lib/core/utils/astr_sky_model.dart` (Dart)
**Test vectors:** `test/fixtures/astr_sky_model.vectors.json`, run by `python3 scripts/test_astr_sky.py` and
`flutter test test/core/utils/astr_sky_model_test.dart`
**Depends on:** [astr_zone_scale.md](astr_zone_scale.md)

Items marked **(unverified)** were not checked against a primary source.

---

## 1. What this layer does

It turns four ingredients into a verdict for each hour and for the night:

- the **place**: how much artificial light there is (the zone ratio `r`, from the zone spec),
- the **sky**: cloud cover and air clarity from a forecast,
- the **moon**: how much scattered moonlight there is,
- the **Sun**: whether it is dark at all.

The verdict is one of six sky states, plus a plain statement of **what is limiting the sky** (cloud, moon, light
pollution or nothing). The same quantities feed the graphs, per-object visibility, and later the star map.

## 2. Units and the one equation

Everything is in **natural units**: 1.0 is the natural zenith sky brightness (22.0 mag/arcsec², 174 µcd/m²).

| Symbol | Meaning |
|---|---|
| `r` | artificial brightness / natural brightness (the zone quantity) |
| `b_moon` | scattered moonlight / natural brightness |
| `total` | `1 + r + b_moon` |

    SQM_eff  = 22.0 - 2.5 log10(1 + r + b_moon)
    NELM_eff = 7.93 - 5 log10(10^(4.316 - SQM_eff/5) + 1)

Luminances add, magnitudes do not, which is why the sum is taken in natural units and converted afterwards.
`NELM` is the empirical SQM-to-limiting-magnitude relation of the Unihedron/AAVSO fit
([source](https://en.wikipedia.org/wiki/Limiting_magnitude)).

The Sun's twilight contribution is not modelled in v1. The model is gated to astronomical night (§6).

## 3. Inputs per hour

| Input | Source | Used for |
|---|---|---|
| Sun altitude | ephemeris | `dark` = at or below -18° |
| Moon altitude, azimuth, illuminated fraction | ephemeris | `b_moon` |
| Total cloud cover | forecast (Open-Meteo `cloud_cover`) | cloud fraction `c` = percent / 100 |
| Aerosol optical depth at 550 nm | forecast (CAMS via Open-Meteo Air Quality) or none | extinction `k_V` |
| Elevation | forecast response or elevation model | extinction `k_V` |
| `r` | zone data: `ratio_from_sqm(cell.sqm)`, or `r` directly after calibration | artificial light |

Each sample stands for one hour. Cloud cover is **not calculated by Astr**: it is a model output, a grid-cell
fraction of sky covered (about 11 km cells), so it says how much of the sky is covered, not whether a given
star is hidden.

## 4. Moonlight

The scattered moonlight at a point of the sky follows Krisciunas & Schaefer (1991), "A model of the brightness
of moonlight" (PASP 103, 1033). The model is an empirical fit to 33 photometric measurements in the V band and
agrees with data at the 8% to 23% level, as reported by its authors. The formulas below were checked against the
published reference implementation
([specsim](https://specsim.readthedocs.io/en/latest/api/specsim.atmosphere.krisciunas_schaefer.html)).

Let `α` be the phase angle in degrees (0 at full moon, 180 at new), `ρ` the angular distance between the moon and
the sky position, `Z` and `Z_m` the zenith distances of the sky position and the moon, and `k` the V-band
extinction coefficient.

    m      = -12.73 + 0.026 |α| + 4e-9 α^4                       (eq. 9, moon magnitude)
    I*     = 10^(-0.4 (m + 16.57))                                (eq. 8, illuminance)
    f(ρ)   = 10^5.36 (1.06 + cos² ρ) + 10^(6.15 - ρ/40)           (eq. 21, scattering function)
    X(Z)   = (1 - 0.96 sin² Z)^(-1/2)                             (eq. 3, scattering airmass)
    B_moon = f(ρ) I* 10^(-0.4 k X(Z_m)) (1 - 10^(-0.4 k X(Z)))    (nanoLamberts)
    V      = (20.7233 - ln(B_moon / 34.08)) / 0.92104             (Garstang 1986, eq. 19, mag/arcsec²)
    b_moon = 10^(0.4 (22.0 - V))                                  (natural units; 0 when Z_m >= 90°)

The illuminated fraction `i` from the ephemeris converts to a phase angle with `α = acos(2 i - 1)`.

**Anchor.** The reference implementation documents one worked value: `Z = 20°`, `Z_m = 70°`, `ρ = 50°`, `α = 45°`,
`k = 0.15` gives **19.855 mag/arcsec²**. Both implementations reproduce it to 0.0005.

**Which sky position.** For the sky-quality verdict the position is the **zenith** (`Z = 0`, `ρ = Z_m`). For an
object's visibility graph it is the **object's direction**, with `ρ` from `angular_separation(alt, az)` between
the moon and the object.

**Caveats.** The fit is in the V band while an SQM meter is broader. It ignores moonlight reflected from
clouds, airglow variation, the zodiacal light, and the sky's dependence on the observer's altitude.

## 5. Extinction

    k_V = 0.1057 (P / P0) + 0.016 + 1.0857 AOD_550

The first term is Rayleigh scattering scaled by station pressure (`P / P0` from the international standard
atmosphere at the station elevation), the second ozone, the third aerosol (`1.0857 = 2.5 log10 e` converts an
optical depth to magnitudes). With no aerosol data, use `AOD = 0.05` **(proposal)**.

The two constants are not individually verified **(unverified)**. As a whole-formula check, a site at 2400 m with
an AOD of 0.03 gives `k_V = 0.127`, against a measured median of 0.130 mag per airmass for the Roque de los
Muchachos observatory on clear nights ([IAC](https://iac.es/en/observatorios-de-canarias/sky-quality/sky-quality-parameters/atmospheric-extinction-and-aerosol-optical-depth)).

## 6. Darkness

An hour is **dark** when the Sun is at or below -18°. Between sunset and that point the sky is still lit by the
Sun and the state is "no verdict" (the "right now" chip shows twilight or day). The brightness of the sky during
twilight is documented by Patat et al. 2006 ([UBVRI twilight sky brightness at ESO-Paranal](https://arxiv.org/pdf/astro-ph/0604128))
and is future work.

## 7. Per-hour quality and the best window

For each hour, with `c` the cloud fraction:

    usable  = dark  and  c <= 0.70  and  NELM_eff >= 3.5                       (proposal)
    utility = (1 - c) * 10^(0.48 (NELM_eff - NELM_natural))     when usable, else 0

`utility` is the expected number of naked-eye stars you can see relative to a natural clear sky: the clear fraction
times the star-count ratio. The slope 0.48 is the logarithmic slope of commonly cited all-sky star counts
**(unverified: recompute from the catalogue once the corpus exists)**.

**Best window.** Split the night into runs of consecutive usable hours. The best window is the run with the
greatest summed utility, and it must be at least **2 hours** long (proposal). Ties go to the earlier run. If no run
qualifies there is no window.

## 8. The six states

The state is a function of the cloud fraction `c`, the artificial ratio `r`, and `r_eff = r + b_moon`. The moon
pushes the sky into a worse **effective zone**, using the zone ladder from the zone spec.

| Order | Condition | State |
|---|---|---|
| 1 | `c > 0.70` | Cloudy |
| 2 | effective zone 9 **and** the artificial zone is 9 | Too much light |
| 3 | effective zone 8, or zone 9 caused only by the moon | Few stars |
| 4 | effective zone 6 or 7 | Planets visible |
| 5 | effective zone 4 or 5 | Starry sky |
| 6 | effective zone 1, 2 or 3 | Milky Way visible |

**Cloud caps.** Milky Way needs `c <= 0.30`, otherwise it becomes Starry sky. Starry sky needs `c <= 0.50`,
otherwise it becomes Planets visible. The cuts 0.30, 0.50 and 0.70 are the values already used in the app
**(proposal)**.

**Moon cannot create "Too much light".** That state describes light pollution. A moon-driven worst case is Few
stars.

**Why the bands are where they are.** With no moon and clear sky, zones 1 to 3 have a limiting magnitude of 6.2 or
better and the Milky Way is intact; zones 4 and 5 are Falchi's Milky Way fading band and beyond (limiting magnitude
5.5 to 6.2); zones 6 and 7 leave the brightest stars and planets (4.5 to 5.5); zone 8 leaves few stars (3.9 to
4.5); zone 9 is the top class (below 3.9). The state boundaries are zone boundaries, so the zone and the verdict never
disagree on a moonless night.

### What is limiting the sky

`why(c, r, r_eff)` returns the reason, so the app can say why and not only what:

| Primary cause | When |
|---|---|
| `cloud` | the state is Cloudy, or cloud capped the state |
| `moon` | otherwise, the moon costs at least 0.25 mag of limiting magnitude and more than light pollution does |
| `light` | otherwise, light pollution costs at least 0.25 mag against a natural sky |
| `none` | otherwise |

`light_loss` and `moon_loss` are the limiting-magnitude losses in magnitudes. The 0.25 mag cut is a proposal.

## 9. The night, the hero state and the "right now" chip (D2)

- **Night state.** The state of the best window, computed from the window's mean cloud and its mean `r_eff` (so a
  moon-up hour counts in luminance, not in magnitudes). If there is no window the state comes from the dark hours
  (so a cloudy night or a city sky still gets an honest label). If there is no dark hour at all (polar summer) there
  is no verdict.
- **Hero.** Shows the night state. The date arrows move the night.
- **Right now.** The same state function applied to the current hour. It is empty when the Sun is not below -18°.
  Because both use `sky_state`, the two can never disagree about the method.
- **Night window.** The night runs from sunset to the next sunrise, as the app computes today; dark hours inside it
  are the ones with the Sun at or below -18°.

### Moon time

The "total moon time" ingredient is two numbers over the dark hours: how many have the moon **up** and how many
have it **down**. The moon's cost is `ΔSQM = SQM(r) - SQM_eff`, in magnitudes, at the zenith or at an object. The
night state already includes it through `r_eff`.

## 10. Worked examples

Computed by the reference code with `c = 0.1` and `k = 0.15`. Each cell shows the state, the effective sky
brightness in mag/arcsec² and the limiting magnitude. Moon positions are altitude above the horizon.

| Site | No moon | 10% crescent, 40° | Half, 40° | Full, 20° | Full, 40° | Full, 70° |
|---|---|---|---|---|---|---|
| Zone 1 (r = 0.1) | Milky Way (21.9, 6.6) | Milky Way (21.7, 6.5) | Starry (20.7, 6.0) | Planets (19.0, 4.8) | Few stars (18.5, 4.4) | Few stars (17.7, 3.7) |
| Zone 3 (r = 0.9) | Milky Way (21.3, 6.3) | Milky Way (21.2, 6.2) | Starry (20.5, 5.8) | Planets (19.0, 4.7) | Few stars (18.5, 4.4) | Few stars (17.6, 3.7) |
| Zone 5 (r = 3) | Starry (20.5, 5.8) | Starry (20.5, 5.8) | Planets (20.0, 5.5) | Planets (18.8, 4.6) | Few stars (18.4, 4.3) | Few stars (17.6, 3.6) |
| Zone 7 (r = 12) | Planets (19.2, 4.9) | Planets (19.2, 4.9) | Planets (19.0, 4.8) | Few stars (18.4, 4.3) | Few stars (18.1, 4.0) | Few stars (17.4, 3.5) |
| Zone 8 (r = 30) | Few stars (18.3, 4.2) | Few stars (18.3, 4.2) | Few stars (18.2, 4.1) | Few stars (17.9, 3.8) | Few stars (17.7, 3.7) | Few stars (17.2, 3.3) |
| Zone 9 (r = 60) | Too much light (17.5, 3.6) | Too much light (17.5, 3.6) | Too much light (17.5, 3.5) | Too much light (17.3, 3.4) | Too much light (17.2, 3.3) | Too much light (16.9, 3.0) |

Reading it: a high full moon takes a pristine site to about the limiting magnitude of a zone 8 city, which matches
experience that a full moon wipes out the Milky Way. In a bright city the moon barely matters.

## 11. Graphs (definitions to implement)

| Graph | Definition |
|---|---|
| Cloud cover | The hourly `c` over the night, with the 0.30, 0.50 and 0.70 cuts |
| Moon | `ΔSQM_moon(t)` in mag/arcsec² at the zenith (replaces the unitless `altitude x illumination` curve) |
| Sky brightness | `SQM_eff(t)` over the night |
| Best window | The best window shaded on the time axis |
| Object altitude | Altitude over time; airmass shown on a second axis |
| Object windows | Hours where the object is at least 30° up and the moon adds at most 0.5 mag at the object's position **(proposal)** |

## 12. What this replaces

| Today | Becomes |
|---|---|
| `QualitativeConditionService.evaluate` (40/35/25 score, Bortle cut-offs) | `AstrSkyModel.skyState` |
| `DarknessCalculator.calculateDarkness` (`4 x phase x sin(alt)`) | `AstrSkyModel.sqmEffective` with `moonRatio` |
| `PrimeViewCalculator` (cloud 0.7, moon 0.3, lowest average) | `AstrSkyModel.bestWindow` |
| `BortleMpsasConverter` | removed |
| `QualityCalculator`, `StargazingLogic` (unused) | removed |
| Moon "interference" in the graphs | `ΔSQM_moon` |

Seeing and transparency are separate (the weather spec). This layer uses only cloud and extinction.

## 13. Known limits

- Twilight sky brightness is not modelled; the model is gated at -18°.
- Moonlight is modelled in the V band, not the SQM band.
- Clouds are one number per hour from a forecast model; moonlit clouds and cloud-amplified skyglow near cities are
  ignored, and a clear sky for a given star is not guaranteed by a low cover.
- The artificial ratio `r` comes from satellite data, so its error carries through (zone spec §7).
- The star-count slope and the extinction constants are not individually verified.
- Thresholds marked proposal are starting points to tune against observer reports.

## 14. Validation plan (proposal)

1. **Moonlight.** Compare `SQM_eff` with Globe at Night and SQM network readings taken with the moon up (the data
   record the date and time, so the moon can be computed), in dark and suburban strata. Report bias and RMSE in
   mag/arcsec². Expect scatter of the 8% to 23% the model's authors report plus sky and meter error.
2. **Limiting magnitude.** Compare `NELM_eff` with observers' limiting-magnitude reports for the same nights.
3. **States.** Compare the state with observers' descriptions (Milky Way visible or not) where reports include
   them; tune the cloud cuts and the 0.25 mag cause cut.
4. **Cloud.** Compare forecast cover with satellite cloud masks for the sampled nights.

## 15. Changelog

- **1.0 (2026-10-09):** First specification. Krisciunas & Schaefer moonlight model with a published anchor,
  extinction from pressure and aerosol, usable hours, best window, six states as effective zones, cause output, and
  Dart and Python references with shared vectors.
