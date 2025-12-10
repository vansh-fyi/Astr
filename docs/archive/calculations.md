# Astronomy Calculations

This document details the mathematical formulas and algorithms used in Astr to ensure transparency and accuracy.

## 1. Seeing Quality (Pickering Scale)

**Metric:** Atmospheric Seeing (1-10)
**Code Reference:** `lib/core/services/seeing_calculator.dart`
**Source:** [Pickering Scale (Harvard College Observatory)](https://en.wikipedia.org/wiki/Astronomical_seeing), [AstroBackyard](https://astrobackyard.com/astronomical-seeing/)

### Formula (Heuristic Model)
Since true Pickering seeing requires visual observation of a star's diffraction pattern, we use a meteorological proxy model based on turbulence factors.

$$ Score_{base} = 10 $$

**Penalties:**
1.  **Temperature Instability:**
    *   If $\Delta T_{3hr} > 5^\circ C$: $-2$
    *   If $\Delta T_{3hr} > 3^\circ C$: $-1$
2.  **Wind Shear:**
    *   If $Wind > 30 km/h$: $-3$
    *   If $Wind > 20 km/h$: $-2$
    *   If $Wind > 10 km/h$: $-1$

**Bonuses:**
1.  **Humidity Stability:**
    *   If $Humidity > 70\%$ AND $\Delta T_{3hr} < 3^\circ C$: $+1$ (Indicates stable laminar air flow)

**Final Score:**
$$ Score = Clamp(Score_{base} - Penalties + Bonuses, 1, 10) $$

---

## 2. Darkness Quality (MPSAS)

**Metric:** Magnitude Per Square Arcsecond (MPSAS)
**Code Reference:** `lib/core/services/darkness_calculator.dart`
**Source:** [David Lorenz Light Pollution Atlas](https://djlorenz.github.io/astronomy/lp/overlay/dark.html), [Unihedron SQM](http://unihedron.com/projects/darksky/faq.php)

### Formula (r^6 Model)
Calculates effective sky brightness by combining artificial light pollution (Bortle/Radiance) with natural moon interference.

$$ MPSAS_{effective} = MPSAS_{base} - Penalty_{moon} $$

**Moon Penalty:**
Modeled as a function of Moon Phase ($\Phi$) and Moon Altitude ($Alt_{moon}$).

$$ Penalty_{moon} = 
\begin{cases} 
4.0 \times \Phi \times \sin(Alt_{moon}) & \text{if } Alt_{moon} > 0 \\
0 & \text{if } Alt_{moon} \le 0 
\end{cases} $$

*   **Max Penalty:** 4.0 MPSAS (Full Moon at Zenith)
*   **Min Penalty:** 0.0 MPSAS (New Moon or Moon below horizon)

---

## 3. Moon Phase & Position

**Metric:** Phase (0-100%), Altitude/Azimuth
**Code Reference:** `lib/features/astronomy/data/repositories/astro_engine_impl.dart`
**Source:** [Swiss Ephemeris (sweph)](https://www.astro.com/swisseph/), [NASA JPL Horizons](https://ssd.jpl.nasa.gov/horizons/)

### Implementation
We use the **Swiss Ephemeris** (via `sweph` package), which is a high-precision compression of the NASA JPL DE431 ephemeris.

**Algorithms:**
*   **Position:** `swe_calc_ut` (Flag: `SEFLG_SWIEPH`)
*   **Topocentric Correction:** `swe_azalt` (Converts Equatorial RA/Dec to Local Alt/Az)
*   **Phase:** `swe_pheno_ut` (Returns phase angle and illumination fraction)

**Accuracy:**
*   Precision: $\pm 0.001$ arcseconds
*   Timeframe: 3000 BC to 3000 AD
