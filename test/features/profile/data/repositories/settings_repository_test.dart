import 'package:astr/features/profile/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_repository_test.mocks.dart';

@GenerateMocks([Box])
void main() {
  late SettingsRepository repository;
  late MockBox mockBox;

  setUp(() {
    mockBox = MockBox();
    repository = SettingsRepository(mockBox);
  });

  group('SettingsRepository', () {
    test('getTosAccepted returns false when key is missing', () {
      when(mockBox.get('tos_accepted', defaultValue: false)).thenReturn(false);

      final result = repository.getTosAccepted();

      expect(result, false);
      verify(mockBox.get('tos_accepted', defaultValue: false)).called(1);
    });

    test('getTosAccepted returns true when key is true', () {
      when(mockBox.get('tos_accepted', defaultValue: false)).thenReturn(true);

      final result = repository.getTosAccepted();

      expect(result, true);
      verify(mockBox.get('tos_accepted', defaultValue: false)).called(1);
    });

    test('setTosAccepted saves value to box', () async {
      when(mockBox.put('tos_accepted', true)).thenAnswer((_) async => {});

      final result = await repository.setTosAccepted(true);

      expect(result.isRight(), true);
      verify(mockBox.put('tos_accepted', true)).called(1);
    });
  });
}
