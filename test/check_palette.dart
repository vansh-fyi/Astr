import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  print('Loading Light_Pollution_Map.png...');

  final File file = File('/Users/hp/Desktop/Work/Repositories/Astr/assets/maps/Light_Pollution_Map.png');
  final Uint8List bytes = await file.readAsBytes();
  final img.Image? image = img.decodePng(bytes);

  if (image == null) {
    print('Failed to load image');
    return;
  }

  print('Map loaded: ${image.width}x${image.height} pixels');
  print('Format: ${image.format}');
  print('Num channels: ${image.numChannels}');
  print('');

  // Sample unique colors from the map
  final Set<String> colorSet = <String>{};

  print('Sampling colors from different regions...');

  // Sample from various regions
  for (int x = 0; x < image.width; x += 1000) {
    for (int y = 0; y < image.height; y += 1000) {
      final img.Pixel pixel = image.getPixel(x, y);
      final int r = pixel.r.toInt();
      final int g = pixel.g.toInt();
      final int b = pixel.b.toInt();
      colorSet.add('($r, $g, $b)');
    }
  }

  print('Found ${colorSet.length} unique colors:');
  final List<String> sortedColors = colorSet.toList()..sort();
  for (final String color in sortedColors) {
    print('  RGB: $color');
  }
}
