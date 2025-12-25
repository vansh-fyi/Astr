import 'dart:io';

import 'package:astr/features/profile/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('SettingsNotifier defaults to false', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(settingsNotifierProvider), false);
  });

  test('SettingsNotifier toggles state and persists', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final SettingsNotifier notifier = container.read(settingsNotifierProvider.notifier);
    
    notifier.toggleRedMode();
    expect(container.read(settingsNotifierProvider), true);
    expect(Hive.box('settings').get('red_mode'), true);

    notifier.toggleRedMode();
    expect(container.read(settingsNotifierProvider), false);
    expect(Hive.box('settings').get('red_mode'), false);
  });
}
