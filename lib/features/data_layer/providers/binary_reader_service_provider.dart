import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/binary_reader_service.dart';

/// Riverpod provider for [BinaryReaderService].
///
/// This is an async provider that handles initialization (asset copying if needed).
///
/// Usage:
/// ```dart
/// final binaryReaderAsync = ref.watch(binaryReaderServiceProvider);
/// binaryReaderAsync.when(
///   data: (service) => service.readBytes(offset: 1024, length: 12),
///   loading: () => /* show loading */,
///   error: (e, st) => /* handle error */,
/// );
/// ```
final FutureProvider<BinaryReaderService> binaryReaderServiceProvider =
    FutureProvider<BinaryReaderService>(
  (FutureProviderRef<BinaryReaderService> ref) async {
    return BinaryReaderService.initialize();
  },
);
