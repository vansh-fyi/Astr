// Web platform astronomy service initialization
import 'package:sweph/sweph.dart';

Future<void> initializeSwephPlatform() async {
  // Web Initialization
  // On web, we rely on assets being served correctly or default initialization
  await Sweph.init();
}
