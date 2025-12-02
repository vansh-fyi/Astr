import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/geocoding_service.dart';
import '../../data/repositories/geocoding_repository_impl.dart';
import '../../domain/repositories/i_geocoding_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final dio = ref.watch(dioProvider);
  return GeocodingService(dio);
});

final geocodingRepositoryProvider = Provider<IGeocodingRepository>((ref) {
  final service = ref.watch(geocodingServiceProvider);
  return GeocodingRepositoryImpl(service);
});
