
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

// Configuration
const String GEONAMES_URL = "http://download.geonames.org/export/dump/cities15000.zip";
const String MAP_PATH = "assets/maps/world2024_low3.png";
const String OUTPUT_PATH = "assets/db/cities.json";
const int MIN_POPULATION = 15000;
const int MAX_ENTRIES = 15000;

// Reference colors for Lorenz Light Pollution Zones (from OfflineLPDataSource)
final List<({List<int> rgb, int bortle})> ZONE_COLORS = [
  (rgb: [0, 0, 50], bortle: 1),
  (rgb: [0, 24, 73], bortle: 1),
  (rgb: [0, 61, 102], bortle: 2),
  (rgb: [0, 85, 127], bortle: 2),
  (rgb: [0, 110, 51], bortle: 3),
  (rgb: [61, 153, 61], bortle: 4),
  (rgb: [153, 153, 0], bortle: 4),
  (rgb: [204, 204, 0], bortle: 5),
  (rgb: [204, 102, 0], bortle: 5),
  (rgb: [255, 153, 51], bortle: 6),
  (rgb: [204, 0, 0], bortle: 7),
  (rgb: [255, 51, 51], bortle: 8),
  (rgb: [255, 153, 153], bortle: 8),
  (rgb: [255, 204, 204], bortle: 9),
  (rgb: [255, 255, 255], bortle: 9),
];

class City {
  final String name;
  final double lat;
  final double lng;
  final double pop;

  City({required this.name, required this.lat, required this.lng, required this.pop});
}

Future<void> main() async {
  print('Starting City DB Generation...');
  final cities = <City>[];
  final tempDir = Directory('temp_cities_data');

  // Phase 1: Data Acquisition
  try {
    print('Step 1: Attempting Download...');
    if (!tempDir.existsSync()) {
      tempDir.createSync();
    }

    final zipPath = '${tempDir.path}/cities.zip';
    final txtPath = '${tempDir.path}/cities15000.txt';

    // 1. Download Zip
    final downloadResult = await Process.run('curl', ['-L', '-o', zipPath, GEONAMES_URL]);
    if (downloadResult.exitCode != 0) {
      throw Exception('Download failed: ${downloadResult.stderr}');
    }

    // 2. Unzip
    final unzipResult = await Process.run('unzip', ['-o', zipPath, '-d', tempDir.path]);
    if (unzipResult.exitCode != 0) {
      throw Exception('Unzip failed: ${unzipResult.stderr}');
    }

    print('Step 2: Parsing GeoNames data...');
    final input = File(txtPath).openRead();
    final lines = await input.transform(utf8.decoder).transform(const LineSplitter()).toList();

    // GeoNames format (tab-separated):
    // 0:geonameid 1:name 4:latitude 5:longitude 14:population
    for (int i = 0; i < lines.length; i++) {
        final parts = lines[i].split('\t');
        if (parts.length < 15) continue;
        try {
            final name = parts[1];
            final lat = double.parse(parts[4]);
            final lng = double.parse(parts[5]);
            final popStr = parts[14];
            final pop = popStr.isNotEmpty ? double.parse(popStr) : 0.0;

            if (pop >= MIN_POPULATION) {
                cities.add(City(name: name, lat: lat, lng: lng, pop: pop));
            }
        } catch (_) {}
    }
    print('Successfully parsed ${cities.length} cities.');

  } catch (e) {
    print('Download/Parsing failed ($e). Using FALLBACK cities list.');
    cities.clear();
    cities.addAll([
        City(name: "Delhi", lat: 28.6139, lng: 77.2090, pop: 30000000),
        City(name: "New York", lat: 40.7128, lng: -74.0060, pop: 8000000),
        City(name: "London", lat: 51.5074, lng: -0.1278, pop: 9000000),
        City(name: "Tokyo", lat: 35.6762, lng: 139.6503, pop: 37000000),
        City(name: "Paris", lat: 48.8566, lng: 2.3522, pop: 2000000),
        City(name: "Sydney", lat: -33.8688, lng: 151.2093, pop: 5000000),
        City(name: "Mumbai", lat: 19.0760, lng: 72.8777, pop: 20000000),
        City(name: "Shanghai", lat: 31.2304, lng: 121.4737, pop: 26000000),
        City(name: "Sao Paulo", lat: -23.5505, lng: -46.6333, pop: 22000000),
        City(name: "Cairo", lat: 30.0444, lng: 31.2357, pop: 20000000),
        City(name: "Moscow", lat: 55.7558, lng: 37.6173, pop: 12000000),
        City(name: "Istanbul", lat: 41.0082, lng: 28.9784, pop: 15000000),
        City(name: "Lagos", lat: 6.5244, lng: 3.3792, pop: 14000000),
        City(name: "Los Angeles", lat: 34.0522, lng: -118.2437, pop: 4000000),
        City(name: "Chicago", lat: 41.8781, lng: -87.6298, pop: 2700000),
        City(name: "Rural Test Point", lat: 25.0000, lng: 10.0000, pop: 20000), // Sahara
    ]);
  }

  // Phase 2: Processing & Map Lookup
  try {
    cities.sort((a, b) => b.pop.compareTo(a.pop));
    final selectedCities = cities.take(MAX_ENTRIES).toList();
    print('Selected top ${selectedCities.length} cities.');

    print('Step 3: Calculating Bortle Class from Map...');
    final mapFile = File(MAP_PATH);
    if (!mapFile.existsSync()) throw Exception('Map file missing: $MAP_PATH');
    
    final image = img.decodeImage(await mapFile.readAsBytes());
    if (image == null) throw Exception('Failed to decode map image');

    final processedData = <dynamic>[];

    for (final city in selectedCities) {
        final x = ((city.lng + 180) * (image.width / 360)).toInt();
        final y = ((90 - city.lat) * (image.height / 180)).toInt();
        
        int bortle = 1;
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
            bortle = getBortleFromColor(image.getPixel(x, y));
        }

        // Urban correction
        if (city.pop > 1000000 && bortle < 7) bortle = 8;
        else if (city.pop > 500000 && bortle < 6) bortle = 6;

        processedData.add(double.parse(city.lat.toStringAsFixed(4)));
        processedData.add(double.parse(city.lng.toStringAsFixed(4)));
        processedData.add(bortle);
    }

    print('Step 4: Saving to JSON...');
    final outFile = File(OUTPUT_PATH);
    await outFile.writeAsString(jsonEncode(processedData));
    print('Done. Saved to $OUTPUT_PATH (${(await outFile.length()) / 1024} KB)');

  } catch (e, stack) {
    print('Error during processing: $e\n$stack');
  } finally {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  }
}

List<String> splitCsvLine(String line) {
  List<String> result = [];
  bool inQuote = false;
  StringBuffer buffer = StringBuffer();
  for (int i = 0; i < line.length; i++) {
    String char = line[i];
    if (char == '"') { inQuote = !inQuote; }
    else if (char == ',' && !inQuote) {
      result.add(buffer.toString().replaceAll('"', '').trim());
      buffer.clear();
    } else { buffer.write(char); }
  }
  result.add(buffer.toString().replaceAll('"', '').trim());
  return result;
}

int getBortleFromColor(img.Pixel pixel) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    double minDist = double.infinity;
    int bestBortle = 5;
    for (final zone in ZONE_COLORS) {
        final dist = sqrt(pow(r - zone.rgb[0], 2) + pow(g - zone.rgb[1], 2) + pow(b - zone.rgb[2], 2));
        if (dist < minDist) { minDist = dist; bestBortle = zone.bortle; }
    }
    return bestBortle;
}
