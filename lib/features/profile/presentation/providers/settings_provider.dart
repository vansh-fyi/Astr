import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const _boxName = 'settings';
  static const _keyRedMode = 'red_mode';

  @override
  bool build() {
    final box = Hive.box(_boxName);
    return box.get(_keyRedMode, defaultValue: false) as bool;
  }

  void toggleRedMode() {
    final box = Hive.box(_boxName);
    final newValue = !state;
    box.put(_keyRedMode, newValue);
    state = newValue;
  }
}
