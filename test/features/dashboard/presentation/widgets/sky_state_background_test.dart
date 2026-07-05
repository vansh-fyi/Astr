import 'package:flutter_test/flutter_test.dart';
import 'package:astr/core/engine/models/sky_state.dart';
import 'package:astr/features/dashboard/presentation/widgets/sky_state_background.dart';

void main() {
  group('SkyStateBackground Tests', () {
    test('SkyStateAssets.pathFor returns correct path for each SkyState', () {
      expect(
        SkyStateAssets.pathFor(SkyState.milkyWayVisible),
        'assets/img/milky_way.jpg',
      );
      expect(
        SkyStateAssets.pathFor(SkyState.starrySkies),
        'assets/img/starry_sky.jpg',
      );
      expect(
        SkyStateAssets.pathFor(SkyState.planetsVisible),
        'assets/img/planets.jpg',
      );
      expect(
        SkyStateAssets.pathFor(SkyState.fewStars),
        'assets/img/few_stars.jpg',
      );
      expect(
        SkyStateAssets.pathFor(SkyState.cloudy),
        'assets/img/cloudy.jpg',
      );
      expect(
        SkyStateAssets.pathFor(SkyState.tooMuchLight),
        'assets/img/excessive_light_pollution.jpg',
      );
    });
  });
}
