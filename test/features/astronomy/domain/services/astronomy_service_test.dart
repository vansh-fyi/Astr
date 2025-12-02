import 'package:flutter_test/flutter_test.dart';
import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:sweph/sweph.dart';

void main() {
  late AstronomyService service;

  setUp(() {
    service = AstronomyService();
    // We can't easily mock Sweph as it's a static FFI wrapper.
    // However, for unit tests, we might need to rely on integration tests or 
    // mock the service itself if we were testing consumers.
    // But here we want to test the logic OF the service.
    // Since Sweph requires assets, running this as a pure unit test might fail 
    // if assets aren't available.
    // We might need to skip actual Sweph calls or use a mockable wrapper.
    // Given the constraints, I'll write a test that assumes Sweph can be initialized 
    // or I'll mock the internal calls if I refactor.
    // But for now, let's try to write a test that checks the logic flow, 
    // assuming we can mock the private _calcEvent if it was protected, but it's not.
    
    // Actually, since I can't easily init Sweph in this environment without assets,
    // I will write a test that mocks the results of calculateRiseSetTransit if I could.
    // But I can't mock methods of the class I'm testing easily without a partial mock.
    
    // Instead, I'll verify the logic by creating a subclass that overrides calculateRiseSetTransit
    // to return fixed times, thus testing getNightWindow logic in isolation.
  });

  test('getNightWindow returns correct window for day time', () async {
    final service = MockAstronomyService();
    final date = DateTime(2023, 10, 27, 14, 0); // 2 PM
    final lat = 51.5;
    final long = -0.1;

    final window = await service.getNightWindow(date: date, lat: lat, long: long);

    expect(window['start'], DateTime(2023, 10, 27, 18, 0)); // Today Sunset
    expect(window['end'], DateTime(2023, 10, 28, 6, 0)); // Tomorrow Sunrise
  });

  test('getNightWindow returns correct window for early morning (pre-dawn)', () async {
    final service = MockAstronomyService();
    final date = DateTime(2023, 10, 27, 4, 0); // 4 AM
    final lat = 51.5;
    final long = -0.1;

    final window = await service.getNightWindow(date: date, lat: lat, long: long);

    expect(window['start'], DateTime(2023, 10, 26, 18, 0)); // Yesterday Sunset
    expect(window['end'], DateTime(2023, 10, 27, 6, 0)); // Today Sunrise
  });

  test('getNightWindow returns correct window for late night (post-sunset)', () async {
    final service = MockAstronomyService();
    final date = DateTime(2023, 10, 27, 22, 0); // 10 PM
    final lat = 51.5;
    final long = -0.1;

    final window = await service.getNightWindow(date: date, lat: lat, long: long);

    expect(window['start'], DateTime(2023, 10, 27, 18, 0)); // Today Sunset
    expect(window['end'], DateTime(2023, 10, 28, 6, 0)); // Tomorrow Sunrise
  });
}

class MockAstronomyService extends AstronomyService {
  @override
  Future<void> init() async {
    // No-op
  }

  @override
  void checkInitialized() {
    // No-op
  }

  @override
  Map<String, DateTime?> calculateRiseSetTransit({
    required HeavenlyBody body,
    String? starName,
    required DateTime date,
    required double lat,
    required double long,
  }) {
    // Return fixed times for testing logic
    // Rise: 6 AM, Set: 6 PM
    return {
      'rise': DateTime(date.year, date.month, date.day, 6, 0),
      'set': DateTime(date.year, date.month, date.day, 18, 0),
      'transit': DateTime(date.year, date.month, date.day, 12, 0),
    };
  }
}
