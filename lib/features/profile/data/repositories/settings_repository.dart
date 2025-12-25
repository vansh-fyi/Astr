import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';

part 'settings_repository.g.dart';

@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  return SettingsRepository(Hive.box('settings'));
}

class SettingsRepository {

  SettingsRepository(this._settingsBox);
  final Box _settingsBox;

  static const String _kTosAcceptedKey = 'tos_accepted';

  bool getTosAccepted() {
    return _settingsBox.get(_kTosAcceptedKey, defaultValue: false) as bool;
  }

  Future<Either<Failure, void>> setTosAccepted(bool value) async {
    try {
      await _settingsBox.put(_kTosAcceptedKey, value);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
