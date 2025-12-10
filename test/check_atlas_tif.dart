import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('Attempting to load World_Atlas_2015.tif...');

  final file = File('/Users/hp/Desktop/Work/Repositories/Astr/Light_Pollution_ATLAS/World_Atlas_2015.tif');

  if (!await file.exists()) {
    print('File not found!');
    return;
  }

  print('File size: ${(await file.length()) / (1024 * 1024 * 1024)} GB');
  print('Reading first few bytes to check format...');

  final bytes = await file.openRead(0, 1024).toList();
  final header = bytes.expand((x) => x).take(20).toList();

  print('Header bytes: ${header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

  // Try to decode with image package
  print('\nAttempting to decode with image package...');
  try {
    final imageBytes = await file.readAsBytes();
    final image = img.decodeTiff(imageBytes);

    if (image != null) {
      print('SUCCESS! TIFF decoded');
      print('Dimensions: ${image.width}x${image.height}');
      print('Format: ${image.format}');
      print('Channels: ${image.numChannels}');
    } else {
      print('TIFF decode returned null');
    }
  } catch (e) {
    print('ERROR: $e');
  }
}
