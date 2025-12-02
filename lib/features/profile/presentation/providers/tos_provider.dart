import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/settings_repository.dart';

part 'tos_provider.g.dart';

@riverpod
class TosNotifier extends _$TosNotifier {
  @override
  bool build() {
    return ref.read(settingsRepositoryProvider).getTosAccepted();
  }

  Future<void> accept() async {
    final result = await ref.read(settingsRepositoryProvider).setTosAccepted(true);
    result.fold(
      (failure) {
        // Ideally log error or show snackbar, but for now just don't update state
        // or maybe throw to let UI handle it?
        // Given the simplicity, we'll just log it if we had a logger.
      },
      (_) => state = true,
    );
  }
}
