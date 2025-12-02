import 'package:astr/features/astronomy/data/repositories/astro_engine_impl.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AstroEngineImpl engine;
  bool isSwephAvailable = false;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await AstroEngineImpl.initialize();
      isSwephAvailable = true;
    } catch (e) {
      print('Sweph initialization failed (expected in VM tests without dylib): $e');
    }
  });

  setUp(() {
    if (isSwephAvailable) {
      engine = AstroEngineImpl();
    }
  });

  test('Calculate Sun position for Greenwich', () async {
    if (!isSwephAvailable) {
      markTestSkipped('Sweph not available in this environment');
      return;
    }
    // ...
    // Greenwich Observatory
    final lat = 51.4769;
    final long = 0.0;
    final time = DateTime.utc(2024, 1, 1, 12, 0, 0); // Noon UTC

    final result = await engine.getPosition(
      body: CelestialBody.sun,
      time: time,
      latitude: lat,
      longitude: long,
    );

    expect(result.isRight(), true);
    final position = result.getOrElse((_) => throw Exception('Failed'));
    
    print('Sun Position: $position');

    // Sun should be roughly South (Az ~180) and low in sky (Winter)
    expect(position.azimuth, closeTo(180, 5.0)); // Within 5 degrees
    expect(position.altitude, closeTo(15, 5.0)); // Roughly 15 degrees (90 - 51.5 + (-23) = 15.5)
  });

  test('Calculate Moon position', () async {
    if (!isSwephAvailable) {
      markTestSkipped('Sweph not available in this environment');
      return;
    }
    final lat = 0.0;
    final long = 0.0;
    final time = DateTime.utc(2024, 1, 1, 0, 0, 0);

    final result = await engine.getPosition(
      body: CelestialBody.moon,
      time: time,
      latitude: lat,
      longitude: long,
    );

    expect(result.isRight(), true);
    final position = result.getOrElse((_) => throw Exception('Failed'));
    print('Moon Position: $position');
    
    expect(position.distance, greaterThan(0));
  });

  test('Performance check', () async {
    if (!isSwephAvailable) {
      markTestSkipped('Sweph not available in this environment');
      return;
    }
    final lat = 0.0;
    final long = 0.0;
    final time = DateTime.now();

    final stopwatch = Stopwatch()..start();
    await engine.getPosition(
      body: CelestialBody.jupiter,
      time: time,
      latitude: lat,
      longitude: long,
    );
    stopwatch.stop();

    print('Calculation time: ${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(50));
  });
}
