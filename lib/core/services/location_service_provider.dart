import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_location_service.dart';
import 'i_location_service.dart';

final locationServiceProvider = Provider<ILocationService>((ref) {
  return DeviceLocationService();
});
