// Checks AstrSkyModel against test/fixtures/astr_sky_model.vectors.json, the same
// vectors that scripts/test_astr_sky.py runs against the Python reference.

import 'dart:convert';
import 'dart:io';

import 'package:astr/core/engine/models/sky_state.dart';
import 'package:astr/core/utils/astr_sky_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, dynamic> v = jsonDecode(
    File('test/fixtures/astr_sky_model.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  double n(Object? x) => (x! as num).toDouble();
  List<Map<String, dynamic>> cases(Object? raw) => (raw! as List<dynamic>).cast<Map<String, dynamic>>();
  SkyHour hour(List<dynamic> r) => AstrSkyModel.hourQuality(
        dark: r[0] as bool,
        cloud: n(r[1]),
        rArt: n(r[2]),
        bMoon: n(r[3]),
      );
  SkyState? state(Object? name) =>
      name == null ? null : SkyState.values.firstWhere((SkyState s) => s.name == name);

  double phase(Map<String, dynamic> c) => n(c['phase_angle']);

  group('AstrSkyModel', () {
    test('published Krisciunas and Schaefer anchor', () {
      final Map<String, dynamic> a = v['anchor'] as Map<String, dynamic>;
      expect(
        AstrSkyModel.moonBrightnessV(
          obsZenithDeg: n(a['obs_zenith']),
          moonZenithDeg: n(a['moon_zenith']),
          separationDeg: n(a['separation']),
          phaseAngleDeg: n(a['phase_angle']),
          kV: n(a['k_v']),
        ),
        closeTo(n(a['v']), n(a['tolerance'])),
      );
    });

    test('numeric tables', () {
      void check(String key, double Function(Map<String, dynamic>) fn, String out) {
        final Map<String, dynamic> t = v[key] as Map<String, dynamic>;
        for (final Map<String, dynamic> c in cases(t['cases'])) {
          expect(fn(c), closeTo(n(c[out]), n(t['tolerance'])), reason: '$key $c');
        }
      }

      check('scattering_airmass', (Map<String, dynamic> c) => AstrSkyModel.scatteringAirmass(n(c['zenith'])), 'x');
      check('phase_angle_from_illumination',
          (Map<String, dynamic> c) => AstrSkyModel.phaseAngleFromIllumination(n(c['illumination'])), 'degrees');
      check('pressure_ratio', (Map<String, dynamic> c) => AstrSkyModel.pressureRatio(n(c['elevation_m'])), 'ratio');
      check(
        'extinction_k_v',
        (Map<String, dynamic> c) =>
            AstrSkyModel.extinctionKV(aod550: n(c['aod550']), elevationM: n(c['elevation_m'])),
        'k',
      );
      check(
        'moon_brightness_v',
        (Map<String, dynamic> c) => AstrSkyModel.moonBrightnessV(
          obsZenithDeg: n(c['obs_zenith']),
          moonZenithDeg: n(c['moon_zenith']),
          separationDeg: n(c['separation']),
          phaseAngleDeg: phase(c),
          kV: n(c['k_v']),
        ),
        'v',
      );
      check(
        'moon_ratio',
        (Map<String, dynamic> c) => AstrSkyModel.moonRatio(
          obsZenithDeg: n(c['obs_zenith']),
          moonZenithDeg: n(c['moon_zenith']),
          separationDeg: n(c['separation']),
          phaseAngleDeg: phase(c),
          kV: n(c['k_v']),
        ),
        'ratio',
      );
      check(
        'angular_separation',
        (Map<String, dynamic> c) =>
            AstrSkyModel.angularSeparationDeg(n(c['alt1']), n(c['az1']), n(c['alt2']), n(c['az2'])),
        'degrees',
      );
      check(
        'sqm_effective',
        (Map<String, dynamic> c) => AstrSkyModel.sqmEffective(n(c['r_art']), bMoon: n(c['b_moon'])),
        'sqm',
      );
      check('relative_star_count', (Map<String, dynamic> c) => AstrSkyModel.relativeStarCount(n(c['nelm'])), 'relative');
    });

    test('moon below the horizon', () {
      expect(
        AstrSkyModel.moonBrightnessV(
          obsZenithDeg: 0,
          moonZenithDeg: 90,
          separationDeg: 90,
          phaseAngleDeg: 0,
          kV: 0.15,
        ).isInfinite,
        isTrue,
      );
      expect(
        AstrSkyModel.moonRatio(obsZenithDeg: 0, moonZenithDeg: 95, separationDeg: 95, phaseAngleDeg: 0, kV: 0.15),
        0,
      );
    });

    test('sky state table', () {
      for (final Map<String, dynamic> c in cases(v['sky_state'])) {
        expect(
          AstrSkyModel.skyState(cloud: n(c['cloud']), rArt: n(c['r_art']), rEff: n(c['r_eff'])),
          state(c['state']),
          reason: '$c',
        );
      }
    });

    test('night state and window', () {
      final Map<String, dynamic> t = v['night_state'] as Map<String, dynamic>;
      for (final Map<String, dynamic> c in cases(t['cases'])) {
        final List<SkyHour> hours = (c['hours'] as List<dynamic>)
            .map((dynamic r) => hour(r as List<dynamic>))
            .toList();
        final NightSky? res = AstrSkyModel.nightState(hours);
        if (c['state'] == null) {
          expect(res, isNull, reason: '${c['name']}');
          continue;
        }
        expect(res!.state, state(c['state']), reason: '${c['name']}');
        final List<dynamic>? w = c['window'] as List<dynamic>?;
        expect(res.window, w == null ? isNull : SkyWindow(w[0] as int, w[1] as int), reason: '${c['name']}');
      }
    });

    test('instant state', () {
      for (final Map<String, dynamic> c in cases(v['instant_state'])) {
        expect(
          AstrSkyModel.instantState(hour(c['hour'] as List<dynamic>)),
          state(c['state']),
          reason: '$c',
        );
      }
    });

    test('why', () {
      final Map<String, dynamic> t = v['why'] as Map<String, dynamic>;
      for (final Map<String, dynamic> c in cases(t['cases'])) {
        final SkyCause w = AstrSkyModel.why(cloud: n(c['cloud']), rArt: n(c['r_art']), rEff: n(c['r_eff']));
        expect(w.primary, c['primary'], reason: '$c');
        expect(w.lightLoss, closeTo(n(c['light_loss']), n(t['tolerance'])));
        expect(w.moonLoss, closeTo(n(c['moon_loss']), n(t['tolerance'])));
      }
    });

    test('moon hours', () {
      final Map<String, dynamic> t = v['moon_hours'] as Map<String, dynamic>;
      for (final Map<String, dynamic> c in cases(t['cases'])) {
        final (int, int) r = AstrSkyModel.moonHours(
          (c['dark'] as List<dynamic>).cast<bool>(),
          (c['moon_altitude'] as List<dynamic>).map(n).toList(),
        );
        expect(r, (c['up'] as int, c['down'] as int));
      }
    });
  });
}
