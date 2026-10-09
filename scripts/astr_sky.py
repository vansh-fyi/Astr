"""Astr sky synthesis v1.0 reference implementation.

Spec: docs/astr_sky_synthesis.md. Test vectors: test/fixtures/astr_sky_model.vectors.json.
The Dart implementation (lib/core/utils/astr_sky_model.dart) must give the same results.

Everything is expressed in natural units: 1.0 is the natural zenith sky brightness (22.0 mag/arcsec^2).
  r       artificial brightness / natural brightness (the Astr zone quantity, see astr_zone.py)
  b_moon  scattered moonlight / natural brightness
  total   1 + r + b_moon
"""

import math

from astr_zone import REFERENCE_SQM, nelm_from_sqm, ratio_from_sqm, sqm_from_ratio, zone_from_ratio

# --- Hourly rules (proposals, see the spec) ---
CLOUD_USABLE_MAX = 0.70
CLOUD_MILKY_WAY_MAX = 0.30
CLOUD_STARRY_MAX = 0.50
NELM_USABLE_MIN = 3.5
MIN_WINDOW_HOURS = 2
LOSS_NOTICEABLE_MAG = 0.25     # limiting-magnitude loss below which a cause is not worth naming
STAR_COUNT_SLOPE = 0.48        # d log10 N / d m, from commonly cited all-sky counts (unverified)
SUN_ALTITUDE_DARK = -18.0      # degrees, astronomical night

# --- Extinction (k_V in mag per airmass) ---
RAYLEIGH_K_SEA_LEVEL = 0.1057  # 1.0857 * 0.0973 (unverified individually)
OZONE_K = 0.016                # (unverified individually)
TAU_TO_K = 1.0857              # 2.5 log10(e)

STATES = ("milkyWayVisible", "starrySkies", "planetsVisible", "fewStars", "cloudy", "tooMuchLight")


def pressure_ratio(elevation_m):
    """Station pressure over sea-level pressure, international standard atmosphere (valid below 11 km)."""
    return (1.0 - 2.25577e-5 * elevation_m) ** 5.25588


def extinction_k_v(aod550=0.0, elevation_m=0.0):
    """V-band extinction coefficient: Rayleigh scaled by pressure, ozone, and aerosol optical depth."""
    return RAYLEIGH_K_SEA_LEVEL * pressure_ratio(elevation_m) + OZONE_K + TAU_TO_K * max(aod550, 0.0)


def scattering_airmass(zenith_deg):
    """Krisciunas & Schaefer (1991) eq. 3."""
    s = math.sin(math.radians(zenith_deg))
    return (1.0 - 0.96 * s * s) ** -0.5


def phase_angle_from_illumination(illumination):
    """Moon phase angle in degrees (0 = full, 180 = new) from the illuminated fraction 0..1."""
    return math.degrees(math.acos(max(-1.0, min(1.0, 2.0 * illumination - 1.0))))


def moon_brightness_v(obs_zenith_deg, moon_zenith_deg, separation_deg, phase_angle_deg, k_v):
    """Scattered moonlight in V mag/arcsec^2 (Krisciunas & Schaefer 1991). math.inf when the moon is down."""
    if moon_zenith_deg >= 90.0:
        return math.inf
    alpha = abs(phase_angle_deg)
    m = -12.73 + 0.026 * alpha + 4e-9 * alpha ** 4                                     # eq. 9
    i_star = 10.0 ** (-0.4 * (m + 16.57))                                              # eq. 8
    rho = separation_deg
    f = 10.0 ** 5.36 * (1.06 + math.cos(math.radians(rho)) ** 2) + 10.0 ** (6.15 - rho / 40.0)  # eq. 21
    x_obs = scattering_airmass(obs_zenith_deg)
    x_moon = scattering_airmass(moon_zenith_deg)
    b_nl = f * i_star * 10.0 ** (-0.4 * k_v * x_moon) * (1.0 - 10.0 ** (-0.4 * k_v * x_obs))  # nanoLamberts
    return (20.7233 - math.log(b_nl / 34.08)) / 0.92104                                # Garstang 1986 eq. 19


def moon_ratio(obs_zenith_deg, moon_zenith_deg, separation_deg, phase_angle_deg, k_v):
    """Scattered moonlight in natural units (0 when the moon is below the horizon)."""
    v = moon_brightness_v(obs_zenith_deg, moon_zenith_deg, separation_deg, phase_angle_deg, k_v)
    if math.isinf(v):
        return 0.0
    return 10.0 ** (0.4 * (REFERENCE_SQM - v))


def angular_separation_deg(alt1_deg, az1_deg, alt2_deg, az2_deg):
    """Angle between two directions given as altitude and azimuth in degrees."""
    a1, a2 = math.radians(alt1_deg), math.radians(alt2_deg)
    d_az = math.radians(az1_deg - az2_deg)
    c = math.sin(a1) * math.sin(a2) + math.cos(a1) * math.cos(a2) * math.cos(d_az)
    return math.degrees(math.acos(max(-1.0, min(1.0, c))))


def sqm_effective(r_art, b_moon=0.0, b_twilight=0.0):
    """Effective sky brightness in mag/arcsec^2: natural + artificial + moon + twilight, in natural units."""
    return REFERENCE_SQM - 2.5 * math.log10(1.0 + max(r_art, 0.0) + max(b_moon, 0.0) + max(b_twilight, 0.0))


def relative_star_count(nelm):
    """Number of naked-eye stars relative to a natural sky (NELM at 22.0 mag/arcsec^2)."""
    return 10.0 ** (STAR_COUNT_SLOPE * (nelm - nelm_from_sqm(REFERENCE_SQM)))


def hour_quality(dark, cloud, r_art, b_moon):
    """Per-hour values. cloud is a fraction 0..1. Returns a dict."""
    sqm = sqm_effective(r_art, b_moon)
    nelm = nelm_from_sqm(sqm)
    usable = bool(dark) and cloud <= CLOUD_USABLE_MAX and nelm >= NELM_USABLE_MIN
    utility = (1.0 - cloud) * relative_star_count(nelm) if usable else 0.0
    return {"dark": bool(dark), "cloud": cloud, "r_art": r_art, "b_moon": b_moon,
            "sqm": sqm, "nelm": nelm, "usable": usable, "utility": utility}


def best_window(hours, min_hours=MIN_WINDOW_HOURS):
    """Contiguous run of usable hours with the greatest summed utility, as (start, end_exclusive) or None.

    Each sample stands for one hour. Ties go to the earlier window.
    """
    best, best_u = None, 0.0
    i = 0
    n = len(hours)
    while i < n:
        if not hours[i]["usable"]:
            i += 1
            continue
        j = i
        total = 0.0
        while j < n and hours[j]["usable"]:
            total += hours[j]["utility"]
            j += 1
        if j - i >= min_hours and total > best_u:
            best, best_u = (i, j), total
        i = j
    return best


def sky_state(cloud, r_art, r_eff):
    """One of the six sky states from the cloud fraction, the artificial ratio and artificial + moon ratio."""
    if cloud > CLOUD_USABLE_MAX:
        return "cloudy"
    base_zone = zone_from_ratio(r_art)
    z = zone_from_ratio(r_eff)
    if z == 9 and base_zone < 9:
        z = 8                      # the moon can make the sky poor but never "too much light"
    if z == 9:
        return "tooMuchLight"
    if z == 8:
        state = "fewStars"
    elif z >= 6:
        state = "planetsVisible"
    elif z >= 4:
        state = "starrySkies"
    else:
        state = "milkyWayVisible"
    if state == "milkyWayVisible" and cloud > CLOUD_MILKY_WAY_MAX:
        state = "starrySkies"
    if state == "starrySkies" and cloud > CLOUD_STARRY_MAX:
        state = "planetsVisible"
    return state


def window_state(hours, window):
    """Sky state for a window: mean cloud, and mean total brightness (so a moon hour counts in luminance)."""
    start, end = window
    span = hours[start:end]
    cloud = sum(h["cloud"] for h in span) / len(span)
    r_art = sum(h["r_art"] for h in span) / len(span)
    r_eff = sum(h["r_art"] + h["b_moon"] for h in span) / len(span)
    return sky_state(cloud, r_art, r_eff)


def moon_hours(dark_flags, moon_altitudes):
    """(dark hours with the moon up, dark hours with the moon down). Inputs are per-hour samples."""
    up = sum(1 for d, a in zip(dark_flags, moon_altitudes) if d and a > 0.0)
    down = sum(1 for d, a in zip(dark_flags, moon_altitudes) if d and a <= 0.0)
    return up, down


def night_state(hours):
    """(state, window) for a night of hourly samples, or None when there is no astronomical night.

    With a usable window the state comes from that window. Without one it comes from the dark hours,
    so a cloudy night or a city sky still gets an honest state.
    """
    window = best_window(hours)
    if window is not None:
        return window_state(hours, window), window
    dark = [h for h in hours if h["dark"]]
    if not dark:
        return None
    cloud = sum(h["cloud"] for h in dark) / len(dark)
    r_art = sum(h["r_art"] for h in dark) / len(dark)
    r_eff = sum(h["r_art"] + h["b_moon"] for h in dark) / len(dark)
    return sky_state(cloud, r_art, r_eff), None


def instant_state(hour):
    """State for the 'right now' chip. None when the Sun is not below -18 degrees (day or twilight)."""
    if not hour["dark"]:
        return None
    return sky_state(hour["cloud"], hour["r_art"], hour["r_art"] + hour["b_moon"])


def why(cloud, r_art, r_eff):
    """What limits the sky: a dict with primary ('cloud', 'moon', 'light' or 'none') and the losses.

    light_loss and moon_loss are limiting-magnitude losses in magnitudes: light pollution against a natural
    sky, and the moon on top of the artificial sky. Cloud is named when it makes the state cloudy or caps it.
    """
    state = sky_state(cloud, r_art, r_eff)
    capped = state == "cloudy" or state != sky_state(0.0, r_art, r_eff)
    nelm_natural = nelm_from_sqm(REFERENCE_SQM)
    nelm_art = nelm_from_sqm(sqm_effective(r_art))
    nelm_all = nelm_from_sqm(sqm_effective(r_eff))
    light_loss = nelm_natural - nelm_art
    moon_loss = nelm_art - nelm_all
    if capped:
        primary = "cloud"
    elif moon_loss >= LOSS_NOTICEABLE_MAG and moon_loss > light_loss:
        primary = "moon"
    elif light_loss >= LOSS_NOTICEABLE_MAG:
        primary = "light"
    else:
        primary = "none"
    return {"primary": primary, "light_loss": light_loss, "moon_loss": moon_loss}
