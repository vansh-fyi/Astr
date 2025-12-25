import 'package:fpdart/src/either.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failure.dart';
import '../../data/repositories/settings_repository.dart';

part 'tos_provider.g.dart';

@riverpod
class TosNotifier extends _$TosNotifier {
  @override
  bool build() {
    return ref.read(settingsRepositoryProvider).getTosAccepted();
  }

  Future<void> accept() async {
    final Either<Failure, void> result = await ref.read(settingsRepositoryProvider).setTosAccepted(true);
    result.fold(
      (Failure failure) {
        // Ideally log error or show snackbar, but for now just don't update state
        // or maybe throw to let UI handle it?
        // Given the simplicity, we'll just log it if we had a logger.
      },
      (_) => state = true,
    );
  }
}
