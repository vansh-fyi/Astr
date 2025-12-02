import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/context/presentation/providers/astr_context_provider.dart';
import '../../domain/entities/bortle_scale.dart';

final bortleProvider = Provider<BortleScale>((ref) {
  final context = ref.watch(astrContextProvider).value;
  // TODO: Implement real Bortle lookup based on context.location
  // For now, returning a default value to unblock Story 2.2
  if (context == null) return BortleScale.class4;
  
  return BortleScale.class4;
});
