# Skyglow Propagation Model

> Updated 2026-10-09. Parameters now match the production `zones.db` (scatter fraction 0.06, retuned from 0.12
> in Phase 2). The zone thresholds and SQM fit shown here are the **legacy v2 chain**; the zone definition is in
> [astr_zone_scale.md](astr_zone_scale.md) (v2.0).

How the Astr app accounts for atmospheric light scatter from nearby cities.

## The Problem

Satellite sensors (VIIRS) look **down** and measure light emitted **upward**. But a stargazer on the ground looks **up** and sees light scattered **through the atmosphere** from cities tens of kilometers away. This scattered light — called **skyglow** — is the dominant source of light pollution at dark-sky sites near urban areas.

**Example:** Bhadraj Temple (30 km from Dehradun) has zero detectable upward light, but a ground observer sees Dehradun's light dome, making it Zone 3–4 instead of Zone 1.

## The Model

We use a **Garstang-inspired atmospheric scattering kernel** applied via FFT convolution to the VNL radiance grid.

### Scatter Formula

For a source pixel with radiance `R` at distance `d` km, the skyglow contribution at the observer is:

```
scatter(d) = R × F × exp(-d / L) / (1 + (d / d₀)^β)
```

| Parameter | Value | Physical Meaning |
|-----------|-------|------------------|
| `F` (fraction) | 0.06 | 6% of upward light scatters horizontally (production). `scripts/apply_skyglow.py` still defaults to 0.12; pass `--fraction 0.06` to reproduce the production data |
| `L` (scale) | 20 km | Exponential attenuation length (Rayleigh + Mie) |
| `d₀` (reference) | 10 km | Power-law transition distance |
| `β` (power) | 2.5 | Combined geometric + atmospheric decay |
| Max radius | 80 km | Scatter negligible beyond this |

### Contribution of one lit pixel at key distances

The kernel gives each source pixel a weight `k(d) = F exp(-d/L) / (1 + (d/d0)^β)`. The skyglow at the observer is
the sum over all lit pixels within 80 km of `R_i k(d_i)`. For a single pixel with radiance 40 nW/cm²/sr and
the production fraction F = 0.06:

| Distance | k(d) | Contribution (nW/cm²/sr) |
|---|---|---|
| 5 km | 0.0397 | 1.59 |
| 10 km | 0.0182 | 0.73 |
| 20 km | 0.00332 | 0.133 |
| 30 km | 0.00081 | 0.032 |
| 50 km | 0.00009 | 0.0035 |
| 80 km | 0.00001 | 0.0002 |

A city is many such pixels, so its skyglow is far larger than one pixel's. (The earlier table in this file
did not reproduce from the formula and has been replaced.)

## Implementation

### Pipeline

```
VNL Raster (15" / ~500m) → Downsample 12× (~5.5 km) → FFT Convolve → Re-scan full res → zones.db
```

1. **Downsample:** Block-average the VNL raster from 86,401×33,601 to ~7,200×2,800 (DOWNSAMPLE=12). Fits in ~80 MB RAM.
2. **Convolve:** Apply the scatter kernel via FFT convolution (`scipy.signal.fftconvolve`). The kernel is a 31×31 pixel matrix (80 km radius at 5.5 km/pixel). Takes ~1 second.
3. **Re-scan:** Read the original VNL again at full resolution in strips of 200 rows. For each pixel, add the nearest-neighbor interpolated scatter value from the coarse grid. If `direct + scatter ≥ 0.25 nW` (Zone 2 threshold), store the H3 cell at **resolution 8** (~0.74 km²).
4. **Write:** Stream sorted cells from SQLite accumulator → binary `zones.db` with ASTR header format.

### Zone Classification (legacy v2 thresholds)

These are the thresholds that built the current `zones.db`. Zones are now defined on the artificial/natural
brightness ratio (see [astr_zone_scale.md](astr_zone_scale.md)); under that definition about 13.6% of stored
cells move by one zone, and the edges become R = 0.252, 0.535, 1.18, 2.74, 6.68, 17.0, 45.0 and 121.

| Radiance (nW/cm²/sr) | Zone |
|----------------------|------|
| ≥ 125.0 | 9 |
| ≥ 50.0 | 8 |
| ≥ 20.0 | 7 |
| ≥ 9.0 | 6 |
| ≥ 3.0 | 5 |
| ≥ 1.0 | 4 |
| ≥ 0.50 | 3 |
| ≥ 0.25 | 2 |
| < 0.25 | 1 |

### Final Radiance Formula

```
total_brightness(lat, lon) = direct_radiance(lat, lon) + Σ scatter(d_i, R_i)
```

Where the sum is over all lit source pixels within 80 km, computed efficiently via convolution.

## Effect on Zones

Illustrative only. These rows were written for the original 0.12 fraction and were not re-measured for the
production 0.06 data **(unverified)**.

| Scenario | Without Skyglow | With Skyglow |
|----------|----------------|-------------|
| City center (NYC) | Zone 9 | Zone 9 (no change) |
| Suburban (20 km from city) | Zone 4 | Zone 5 (+1) |
| Rural (30 km from city) | Zone 1 | Zone 2–3 (+2) |
| Dark site (50+ km from city) | Zone 1 | Zone 1 (no change) |
| Between two cities | Zone 1 | Zone 3–4 (cumulative) |

## Tuning

Parameters can be adjusted via CLI flags. Because the accumulator keeps the maximum value per cell, lowering a
parameter requires `--reset-accum` (the production retune to 0.06 used `--reset-accum --batch 10`):

```bash
python apply_skyglow.py --tif "../VNL NPP 2024 Global Masked Data.tif.gz" --fraction 0.15 --scale-km 25
```

- **Higher fraction** → more aggressive scatter (brighter skyglow)
- **Higher scale-km** → scatter reaches further from cities
- Lower values make the model more conservative

## References

- Garstang, R.H. (1986). "Model for artificial night-sky illumination." *PASP*, 98, 364
- Cinzano, P., Falchi, F., Elvidge, C.D. (2001). "The first World Atlas of the artificial night sky brightness." *Monthly Notices of the Royal Astronomical Society*, 328(3)
- Falchi, F., et al. (2016). "The new world atlas of artificial night sky brightness." *Science Advances*, 2(6)
