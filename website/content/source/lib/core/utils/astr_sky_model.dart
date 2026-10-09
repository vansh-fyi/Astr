import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../engine/models/sky_state.dart';
import 'astr_zone_scale.dart';

/// Per-hour sky values. Built with [AstrSkyModel.hourQuality].
@immutable
class SkyHour {
  const SkyHour({
    required this.dark,
    required this.cloud,
    required this.rArt,
    required this.bMoon,
    required this.sqm,
    required this.nelm,
    required this.usable,
    required this.utility,
  });

  /// The Sun is at or below -18 degrees.
  final bool dark;

  /// Cloud cover as a fraction, 0 to 1.
  final double cloud;

  /// Artificial brightness over natural brightness.
  final double rArt;

  /// Scattered moonlight over natural brightness.
  final double bMoon;

  /// Effective sky brightness in mag/arcsec².
  final double sqm;

  /// Naked-eye limiting magnitude for [sqm].
  final double nelm;

  final bool usable;

  /// Clear fraction times relative star count; 0 when not usable.
  final double utility;
}

/// What limits the sky, from [AstrSkyModel.why].
@immutable
class SkyCause {
  const SkyCause(this.primary, this.lightLoss, this.moonLoss);

  /// `cloud`, `moon`, `light` or `none`.
  final String primary;

  /// Limiting-magnitude loss from artificial light against a natural sky.
  final double lightLoss;

  /// Limiting-magnitude loss from the moon on top of the artificial sky.
  final double moonLoss;
}

/// A run of hourly samples, `[start, end)`.
@immutable
class SkyWindow {
  const SkyWindow(this.start, this.end);
  final int start;
  final int end;

  @override
  bool operator ==(Object other) => other is SkyWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SkyWindow($start, $end)';
}

/// The result for a night: a state and, when there is one, the best window.
@immutable
class NightSky {
  const NightSky(this.state, this.window);
  final SkyState state;
  final SkyWindow? window;
}

/// Astr sky synthesis v1.0.
///
/// Spec: `docs/astr_sky_synthesis.md`. Test vectors: `test/fixtures/astr_sky_model.vectors.json`.
/// The Python reference (`scripts/astr_sky.py`) must give the same results.
///
/// Everything is in natural units: 1.0 is the natural zenith sky brightness (22.0 mag/arcsec²).
abstract final class AstrSkyModel {
  static const double cloudUsableMax = 0.70;
  static const double cloudMilkyWayMax = 0.30;
  static const double cloudStarryMax = 0.50;
  static const double nelmUsableMin = 3.5;
  static const int minWindowHours = 2;

  /// Limiting-magnitude loss below which a cause is not worth naming.
  static const double lossNoticeableMag = 0.25;

  /// d log10 N / d m, from commonly cited all-sky star counts (unverified).
  static const double starCountSlope = 0.48;

  /// Sun altitude at or below which the sky is dark, in degrees.
  static const double sunAltitudeDark = -18;

  static const double _rayleighKSeaLevel = 0.1057;
  static const double _ozoneK = 0.016;
  static const double _tauToK = 1.0857;

  /// Station pressure over sea-level pressure, international standard atmosphere (below 11 km).
  static double pressureRatio(double elevationM) =>
      math.pow(1 - 2.25577e-5 * elevationM, 5.25588).toDouble();

  /// V-band extinction coefficient in mag per airmass.
  static double extinctionKV({double aod550 = 0, double elevationM = 0}) =>
      _rayleighKSeaLevel * pressureRatio(elevationM) + _ozoneK + _tauToK * math.max(aod550, 0);

  /// Krisciunas & Schaefer (1991) eq. 3.
  static double scatteringAirmass(double zenithDeg) {
    final double s = math.sin(_rad(zenithDeg));
    return math.pow(1 - 0.96 * s * s, -0.5).toDouble();
  }

  /// Moon phase angle in degrees (0 full, 180 new) from the illuminated fraction 0 to 1.
  static double phaseAngleFromIllumination(double illumination) =>
      _deg(math.acos((2 * illumination - 1).clamp(-1.0, 1.0)));

  /// Scattered moonlight in V mag/arcsec² (Krisciunas & Schaefer 1991). Infinity when the moon is down.
  static double moonBrightnessV({
    required double obsZenithDeg,
    required double moonZenithDeg,
    required double separationDeg,
    required double phaseAngleDeg,
    required double kV,
  }) {
    if (moonZenithDeg >= 90) return double.infinity;
    final double alpha = phaseAngleDeg.abs();
    final double m = -12.73 + 0.026 * alpha + 4e-9 * math.pow(alpha, 4); // eq. 9
    final double iStar = math.pow(10, -0.4 * (m + 16.57)).toDouble(); // eq. 8
    final double f = math.pow(10, 5.36) * (1.06 + math.pow(math.cos(_rad(separationDeg)), 2)) +
        math.pow(10, 6.15 - separationDeg / 40); // eq. 21
    final double xObs = scatteringAirmass(obsZenithDeg);
    final double xMoon = scatteringAirmass(moonZenithDeg);
    final double bNl = f *
        iStar *
        math.pow(10, -0.4 * kV * xMoon) *
        (1 - math.pow(10, -0.4 * kV * xObs)); // nanoLamberts
    return (20.7233 - math.log(bNl / 34.08)) / 0.92104; // Garstang 1986 eq. 19
  }

  /// Scattered moonlight in natural units (0 when the moon is below the horizon).
  static double moonRatio({
    required double obsZenithDeg,
    required double moonZenithDeg,
    required double separationDeg,
    required double phaseAngleDeg,
    required double kV,
  }) {
    final double v = moonBrightnessV(
      obsZenithDeg: obsZenithDeg,
      moonZenithDeg: moonZenithDeg,
      separationDeg: separationDeg,
      phaseAngleDeg: phaseAngleDeg,
      kV: kV,
    );
    if (v.isInfinite) return 0;
    return math.pow(10, 0.4 * (AstrZoneScale.referenceSqm - v)).toDouble();
  }

  /// Angle between two directions given as altitude and azimuth in degrees.
  static double angularSeparationDeg(double alt1, double az1, double alt2, double az2) {
    final double a1 = _rad(alt1);
    final double a2 = _rad(alt2);
    final double c = math.sin(a1) * math.sin(a2) + math.cos(a1) * math.cos(a2) * math.cos(_rad(az1 - az2));
    return _deg(math.acos(c.clamp(-1.0, 1.0)));
  }

  /// Effective sky brightness in mag/arcsec²: natural + artificial + moon + twilight, in natural units.
  static double sqmEffective(double rArt, {double bMoon = 0, double bTwilight = 0}) =>
      AstrZoneScale.referenceSqm -
      2.5 * _log10(1 + math.max(rArt, 0) + math.max(bMoon, 0) + math.max(bTwilight, 0));

  /// Naked-eye star count relative to a natural sky.
  static double relativeStarCount(double nelm) =>
      math.pow(10, starCountSlope * (nelm - AstrZoneScale.nelmFromSqm(AstrZoneScale.referenceSqm))).toDouble();

  /// Per-hour values. [cloud] is a fraction 0 to 1.
  static SkyHour hourQuality({
    required bool dark,
    required double cloud,
    required double rArt,
    required double bMoon,
  }) {
    final double sqm = sqmEffective(rArt, bMoon: bMoon);
    final double nelm = AstrZoneScale.nelmFromSqm(sqm);
    final bool usable = dark && cloud <= cloudUsableMax && nelm >= nelmUsableMin;
    final double utility = usable ? (1 - cloud) * relativeStarCount(nelm) : 0;
    return SkyHour(
      dark: dark,
      cloud: cloud,
      rArt: rArt,
      bMoon: bMoon,
      sqm: sqm,
      nelm: nelm,
      usable: usable,
      utility: utility,
    );
  }

  /// The run of usable hours with the greatest summed utility, or null. Ties go to the earlier run.
  static SkyWindow? bestWindow(List<SkyHour> hours, {int minHours = minWindowHours}) {
    SkyWindow? best;
    double bestUtility = 0;
    int i = 0;
    while (i < hours.length) {
      if (!hours[i].usable) {
        i++;
        continue;
      }
      int j = i;
      double total = 0;
      while (j < hours.length && hours[j].usable) {
        total += hours[j].utility;
        j++;
      }
      if (j - i >= minHours && total > bestUtility) {
        best = SkyWindow(i, j);
        bestUtility = total;
      }
      i = j;
    }
    return best;
  }

  /// One of the six sky states from the cloud fraction, the artificial ratio and artificial + moon ratio.
  static SkyState skyState({required double cloud, required double rArt, required double rEff}) {
    if (cloud > cloudUsableMax) return SkyState.cloudy;
    final int baseZone = AstrZoneScale.zoneFromRatio(rArt);
    int z = AstrZoneScale.zoneFromRatio(rEff);
    if (z == 9 && baseZone < 9) z = 8; // the moon can make the sky poor but never "too much light"
    if (z == 9) return SkyState.tooMuchLight;
    SkyState state;
    if (z == 8) {
      state = SkyState.fewStars;
    } else if (z >= 6) {
      state = SkyState.planetsVisible;
    } else if (z >= 4) {
      state = SkyState.starrySkies;
    } else {
      state = SkyState.milkyWayVisible;
    }
    if (state == SkyState.milkyWayVisible && cloud > cloudMilkyWayMax) state = SkyState.starrySkies;
    if (state == SkyState.starrySkies && cloud > cloudStarryMax) state = SkyState.planetsVisible;
    return state;
  }

  /// What limits the sky. Cloud is named when it makes the state cloudy or caps it.
  static SkyCause why({required double cloud, required double rArt, required double rEff}) {
    final SkyState state = skyState(cloud: cloud, rArt: rArt, rEff: rEff);
    final bool capped = state == SkyState.cloudy || state != skyState(cloud: 0, rArt: rArt, rEff: rEff);
    final double nelmNatural = AstrZoneScale.nelmFromSqm(AstrZoneScale.referenceSqm);
    final double nelmArt = AstrZoneScale.nelmFromSqm(sqmEffective(rArt));
    final double nelmAll = AstrZoneScale.nelmFromSqm(sqmEffective(rEff));
    final double lightLoss = nelmNatural - nelmArt;
    final double moonLoss = nelmArt - nelmAll;
    String primary;
    if (capped) {
      primary = 'cloud';
    } else if (moonLoss >= lossNoticeableMag && moonLoss > lightLoss) {
      primary = 'moon';
    } else if (lightLoss >= lossNoticeableMag) {
      primary = 'light';
    } else {
      primary = 'none';
    }
    return SkyCause(primary, lightLoss, moonLoss);
  }

  /// State for a night of hourly samples, or null when there is no astronomical night.
  static NightSky? nightState(List<SkyHour> hours) {
    final SkyWindow? window = bestWindow(hours);
    final List<SkyHour> span = window != null
        ? hours.sublist(window.start, window.end)
        : hours.where((SkyHour h) => h.dark).toList();
    if (span.isEmpty) return null;
    final double n = span.length.toDouble();
    final double cloud = span.fold<double>(0, (double a, SkyHour h) => a + h.cloud) / n;
    final double rArt = span.fold<double>(0, (double a, SkyHour h) => a + h.rArt) / n;
    final double rEff = span.fold<double>(0, (double a, SkyHour h) => a + h.rArt + h.bMoon) / n;
    return NightSky(skyState(cloud: cloud, rArt: rArt, rEff: rEff), window);
  }

  /// State for the "right now" chip. Null when the Sun is not below -18 degrees.
  static SkyState? instantState(SkyHour hour) {
    if (!hour.dark) return null;
    return skyState(cloud: hour.cloud, rArt: hour.rArt, rEff: hour.rArt + hour.bMoon);
  }

  /// (dark hours with the moon up, dark hours with the moon down).
  static (int, int) moonHours(List<bool> dark, List<double> moonAltitudes) {
    int up = 0;
    int down = 0;
    for (int i = 0; i < dark.length && i < moonAltitudes.length; i++) {
      if (!dark[i]) continue;
      if (moonAltitudes[i] > 0) {
        up++;
      } else {
        down++;
      }
    }
    return (up, down);
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
  static double _log10(double x) => math.log(x) / math.ln10;
}
