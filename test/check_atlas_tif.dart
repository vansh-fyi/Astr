import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  print('Attempting to load World_Atlas_2015.tif...');

  final File file = File('/Users/hp/Desktop/Work/Repositories/Astr/Light_Pollution_ATLAS/World_Atlas_2015.tif');

  if (!await file.exists()) {
    print('File not found!');
    return;
  }

  print('File size: ${(await file.length()) / (1024 * 1024 * 1024)} GB');
  print('Reading first few bytes to check format...');

  final List<List<int>> bytes = await file.openRead(0, 1024).toList();
  final List<int> header = bytes.expand((List<int> x) => x).take(20).toList();

  print('Header bytes: ${header.map((int b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

  // Try to decode with image package
  print('\nAttempting to decode with image package...');
  try {
    final Uint8List imageBytes = await file.readAsBytes();
    final img.Image? image = img.decodeTiff(imageBytes);

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
