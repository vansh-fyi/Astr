import 'package:astr/core/error/failure.dart';
import 'package:astr/features/astronomy/data/repositories/astro_engine_impl.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/src/either.dart';

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
    const double lat = 51.4769;
    const double long = 0;
    final DateTime time = DateTime.utc(2024, 1, 1, 12); // Noon UTC

    final Either<Failure, CelestialPosition> result = await engine.getPosition(
      body: CelestialBody.sun,
      time: time,
      latitude: lat,
      longitude: long,
    );

    expect(result.isRight(), true);
    final CelestialPosition position = result.getOrElse((_) => throw Exception('Failed'));
    
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
    const double lat = 0;
    const double long = 0;
    final DateTime time = DateTime.utc(2024, 1);

    final Either<Failure, CelestialPosition> result = await engine.getPosition(
      body: CelestialBody.moon,
      time: time,
      latitude: lat,
      longitude: long,
    );

    expect(result.isRight(), true);
    final CelestialPosition position = result.getOrElse((_) => throw Exception('Failed'));
    print('Moon Position: $position');
    
    expect(position.distance, greaterThan(0));
  });

  test('Performance check', () async {
    if (!isSwephAvailable) {
      markTestSkipped('Sweph not available in this environment');
      return;
    }
    const double lat = 0;
    const double long = 0;
    final DateTime time = DateTime.now();

    final Stopwatch stopwatch = Stopwatch()..start();
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
