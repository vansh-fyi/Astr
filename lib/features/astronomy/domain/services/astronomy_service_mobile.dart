// Mobile platform astronomy service initialization
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';

Future<void> initializeSwephPlatform() async {
  // Native Initialization
  final Directory docsDir = await getApplicationDocumentsDirectory();
  final String ephePath = '${docsDir.path}/ephe_files';
  final Directory epheDir = Directory(ephePath);

  if (!await epheDir.exists()) {
    await epheDir.create(recursive: true);
  }

  // Initialize with the writable path
  await Sweph.init(epheFilesPath: ephePath);
}
