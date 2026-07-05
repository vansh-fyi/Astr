import 'package:astr/core/engine/models/condition_quality.dart';
import 'package:astr/core/engine/models/condition_result.dart';
import 'package:astr/core/engine/models/sky_state.dart';
import 'package:astr/core/error/failure.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/domain/repositories/i_catalog_repository.dart';
import 'package:astr/features/catalog/presentation/providers/object_detail_notifier.dart';
import 'package:astr/features/catalog/presentation/providers/rise_set_provider.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/presentation/providers/condition_quality_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/dashboard/presentation/widgets/conditions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class MockWeatherNotifier extends AsyncNotifier<Weather> implements WeatherNotifier {
  @override
  Future<Weather> build() async {
    return const Weather(cloudCover: 10);
  }

  @override
  Future<void> refresh() async {}
}

class FakeObjectDetailNotifier extends ObjectDetailNotifier {
  FakeObjectDetailNotifier(CelestialObject object)
      : super(
          _FakeCatalogRepository(object),
          _FakeRef(),
          '',
        );
}

class _FakeCatalogRepository implements ICatalogRepository {
  _FakeCatalogRepository(this._object);
  final CelestialObject _object;

  @override
  Future<Either<Failure, CelestialObject>> getObjectById(String id) async {
    return Right(_object);
  }

  @override
  Future<Either<Failure, List<CelestialObject>>> getAllObjects() async {
    return Right(<CelestialObject>[_object]);
  }

  @override
  Future<Either<Failure, List<CelestialObject>>> getObjectsByType(CelestialType type) async {
    return Right(<CelestialObject>[_object]);
  }
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('ConditionsCard builds and renders with default loading states', (WidgetTester tester) async {
    final sunObject = CelestialObject(
      id: 'sun',
      name: 'Sun',
      type: CelestialType.star,
      iconPath: '',
      magnitude: -26.74,
    );

    final moonObject = CelestialObject(
      id: 'moon',
      name: 'Moon',
      type: CelestialType.satellite,
      iconPath: '',
      magnitude: -12.74,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          weatherProvider.overrideWith(() => MockWeatherNotifier()),
          conditionQualityProvider.overrideWith((ref) => const ConditionResult(
            quality: ConditionQuality.excellent,
            shortSummary: 'Clear Skies',
            detailedAdvice: 'Perfect visibility for observation',
            statusColor: Colors.green,
            skyState: SkyState.milkyWayVisible,
          )),
          objectDetailNotifierProvider.overrideWith((ref, id) {
            if (id == 'sun') return FakeObjectDetailNotifier(sunObject);
            return FakeObjectDetailNotifier(moonObject);
          }),
          riseSetProvider.overrideWith((ref, object) async {
            return <String, DateTime?>{
              'rise': DateTime(2025, 1, 1, 6, 0),
              'set': DateTime(2025, 1, 1, 18, 0),
            };
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConditionsCard(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    // Verify Title/Subtitle (with leading space check)
    expect(find.text(' Clear Skies'), findsOneWidget);
    expect(find.text('  Perfect visibility for observation'), findsOneWidget);

    // Verify Cloud Cover display
    expect(find.text('Cloud Cover'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);

    // Verify 4 Rise/Set Cells and labels
    expect(find.text('SUNRISE'), findsOneWidget);
    expect(find.text('SUNSET'), findsOneWidget);
    expect(find.text('MOONRISE'), findsOneWidget);
    expect(find.text('MOONSET'), findsOneWidget);

    // Verify 06:00 and 18:00 displays
    expect(find.text('06:00'), findsNWidgets(2)); // Sunrise and Moonrise
    expect(find.text('18:00'), findsNWidgets(2)); // Sunset and Moonset
  });
}
