import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_location_service.dart';
import 'i_location_service.dart';

final Provider<ILocationService> locationServiceProvider = Provider<ILocationService>((ProviderRef<ILocationService> ref) {
  return DeviceLocationService();
});
