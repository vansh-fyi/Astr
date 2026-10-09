"""Astr Zone scale v2.0 reference implementation.

Spec: docs/astr_zone_scale.md. Test vectors: test/fixtures/astr_zone_scale.vectors.json.
The Dart implementation (lib/core/utils/astr_zone_scale.dart) must give the same results.

r is the ratio of artificial to natural zenith sky brightness, L_artificial / L_natural.
Zone 1 is r < 0.32. Zone n (2 to 8) is [0.32 * 2^(n-2), 0.32 * 2^(n-1)). Zone 9 is r >= 40.96.
Boundaries are lower-inclusive.
"""

import math

NATURAL_UCD_PER_M2 = 174.0   # natural zenith brightness, microcandela per m^2 (Falchi et al. 2016)
REFERENCE_SQM = 22.0         # mag/arcsec^2 that corresponds to the natural brightness above
FIRST_EDGE = 0.32            # r at which zone 2 begins
STEP = 2.0                   # each zone edge is twice the previous one
ZONE_COUNT = 9
EDGES = tuple(FIRST_EDGE * STEP ** k for k in range(ZONE_COUNT - 1))  # start of zones 2..9

# Legacy v2 chain (interim, used to build the current zones.db). Radiance in nW/cm^2/sr.
LEGACY_THRESHOLDS = ((125.0, 9), (50.0, 8), (20.0, 7), (9.0, 6), (3.0, 5), (1.0, 4), (0.50, 3), (0.25, 2))
LEGACY_SQM_SLOPE = 1.7
LEGACY_SQM_GAIN = 2.0


def _check_ratio(r):
    if isinstance(r, bool) or not isinstance(r, (int, float)) or math.isnan(r):
        raise ValueError(f"r must be a number, got {r!r}")


def zone_from_ratio(r):
    """Zone 1-9 for an artificial/natural ratio. Negative r counts as 0. NaN raises ValueError."""
    _check_ratio(r)
    zone = 1
    for edge in EDGES:
        if r >= edge:
            zone += 1
        else:
            break
    return zone


def sqm_from_ratio(r):
    """Zenith sky brightness in mag/arcsec^2 for a ratio r (r < 0 counts as 0)."""
    _check_ratio(r)
    return REFERENCE_SQM - 2.5 * math.log10(1.0 + max(r, 0.0))


def ratio_from_sqm(sqm):
    """Inverse of sqm_from_ratio. An SQM above the reference gives 0."""
    if math.isnan(sqm):
        raise ValueError("sqm must be a number")
    return max(10.0 ** (0.4 * (REFERENCE_SQM - sqm)) - 1.0, 0.0)


def artificial_ucd_from_ratio(r):
    """Artificial zenith luminance in microcandela per m^2."""
    _check_ratio(r)
    return max(r, 0.0) * NATURAL_UCD_PER_M2


def nelm_from_sqm(sqm):
    """Naked-eye limiting magnitude from an SQM value (empirical, Unihedron/AAVSO relation)."""
    return 7.93 - 5.0 * math.log10(10.0 ** (4.316 - sqm / 5.0) + 1.0)


def legacy_zone_from_radiance(radiance):
    """Zone assigned by the production pipeline's radiance thresholds."""
    if radiance <= 0:
        return 1
    for threshold, zone in LEGACY_THRESHOLDS:
        if radiance >= threshold:
            return zone
    return 1


def legacy_ratio_from_radiance(radiance):
    """r implied by the legacy SQM fit 22 - 1.7 log10(1 + 2R): r = (1 + 2R)^0.68 - 1."""
    if radiance <= 0:
        return 0.0
    return (1.0 + LEGACY_SQM_GAIN * radiance) ** (0.4 * LEGACY_SQM_SLOPE) - 1.0
