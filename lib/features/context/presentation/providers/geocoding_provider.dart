import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/geocoding_service.dart';
import '../../data/repositories/geocoding_repository_impl.dart';
import '../../domain/repositories/i_geocoding_repository.dart';

final Provider<Dio> dioProvider = Provider<Dio>((ProviderRef<Dio> ref) {
  return Dio();
});

final Provider<GeocodingService> geocodingServiceProvider = Provider<GeocodingService>((ProviderRef<GeocodingService> ref) {
  final Dio dio = ref.watch(dioProvider);
  return GeocodingService(dio);
});

final Provider<IGeocodingRepository> geocodingRepositoryProvider = Provider<IGeocodingRepository>((ProviderRef<IGeocodingRepository> ref) {
  final GeocodingService service = ref.watch(geocodingServiceProvider);
  return GeocodingRepositoryImpl(service);
});
