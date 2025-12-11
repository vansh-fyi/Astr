// Mobile platform astronomy service initialization
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';

Future<void> initializeSwephPlatform() async {
  // Native Initialization
  final docsDir = await getApplicationDocumentsDirectory();
  final ephePath = '${docsDir.path}/ephe_files';
  final epheDir = Directory(ephePath);

  if (!await epheDir.exists()) {
    await epheDir.create(recursive: true);
  }

  // Initialize with the writable path
  await Sweph.init(epheFilesPath: ephePath);
}
