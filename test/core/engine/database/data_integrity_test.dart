import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Data Integrity Test for astr.db (AC #5)
///
/// Validates that the database file contains the expected schema
/// and sample data as specified in architecture.md
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Data Integrity (AC #5)', () {
    late Database db;

    setUpAll(() async {
      // Load the actual database file from assets
      final File assetDb = File('assets/db/astr.db');
      expect(assetDb.existsSync(), true, reason: 'astr.db must exist in assets/db/');

      // Copy to temp location for testing
      final Directory testDir = await Directory.systemTemp.createTemp('astr_integrity_test_');
      final String testDbPath = join(testDir.path, 'astr.db');
      await assetDb.copy(testDbPath);

      db = await databaseFactory.openDatabase(testDbPath, options: OpenDatabaseOptions(readOnly: true));
    });

    tearDownAll(() async {
      await db.close();
    });

    test('database schema matches architecture.md specification', () async {
      // Verify stars table exists with correct schema
      final List<Map<String, Object?>> starsTable = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='stars'",
      );
      expect(starsTable, isNotEmpty, reason: 'stars table must exist');

      final String starsSchema = starsTable.first['sql']! as String;
      expect(starsSchema.toLowerCase(), contains('hip_id'), reason: 'stars table must have hip_id column');
      expect(starsSchema.toLowerCase(), contains('ra'), reason: 'stars table must have ra column');
      expect(starsSchema.toLowerCase(), contains('dec'), reason: 'stars table must have dec column');
      expect(starsSchema.toLowerCase(), contains('mag'), reason: 'stars table must have mag column');
      expect(starsSchema.toLowerCase(), contains('name'), reason: 'stars table must have name column');
      expect(starsSchema.toLowerCase(), contains('constellation'), reason: 'stars table must have constellation column');

      // Verify dso table exists with correct schema
      final List<Map<String, Object?>> dsoTable = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='dso'",
      );
      expect(dsoTable, isNotEmpty, reason: 'dso table must exist');

      final String dsoSchema = dsoTable.first['sql']! as String;
      expect(dsoSchema.toLowerCase(), contains('messier_id'), reason: 'dso table must have messier_id column');
      expect(dsoSchema.toLowerCase(), contains('ngc_id'), reason: 'dso table must have ngc_id column');
      expect(dsoSchema.toLowerCase(), contains('type'), reason: 'dso table must have type column');
      expect(dsoSchema.toLowerCase(), contains('ra'), reason: 'dso table must have ra column');
      expect(dsoSchema.toLowerCase(), contains('dec'), reason: 'dso table must have dec column');
      expect(dsoSchema.toLowerCase(), contains('mag'), reason: 'dso table must have mag column');
    });

    test('stars table contains Hipparcos catalog data', () async {
      final List<Map<String, Object?>> starCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM stars');
      final int starCount = starCountResult.first['count']! as int;

      expect(starCount, greaterThan(0), reason: 'stars table must not be empty');
      // Note: Test database has minimal data; production should have full Hipparcos catalog

      // Verify sample well-known stars exist
      final List<Map<String, Object?>> sirius = await db.query('stars', where: 'LOWER(name) LIKE ?', whereArgs: <Object?>['%sirius%'], limit: 1);
      expect(sirius, isNotEmpty, reason: 'Sirius (brightest star) must be in database');

      final List<Map<String, Object?>> polaris = await db.query('stars', where: 'LOWER(name) LIKE ?', whereArgs: <Object?>['%polaris%'], limit: 1);
      expect(polaris, isNotEmpty, reason: 'Polaris must be in database');
    });

    test('dso table contains Messier and NGC catalog data', () async {
      final List<Map<String, Object?>> dsoCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM dso');
      final int dsoCount = dsoCountResult.first['count']! as int;

      expect(dsoCount, greaterThan(0), reason: 'dso table must not be empty');
      // Note: Test database has minimal data; production should have full Messier/NGC catalogs

      // Verify Andromeda Galaxy (M31) exists
      final List<Map<String, Object?>> andromeda = await db.query(
        'dso',
        where: 'messier_id = ? OR LOWER(name) LIKE ?',
        whereArgs: <Object?>['M31', '%andromeda%'],
        limit: 1,
      );
      expect(andromeda, isNotEmpty, reason: 'Andromeda Galaxy (M31) must be in database');

      // Verify sample Messier objects
      final List<Map<String, Object?>> messierId = await db.query('dso', where: 'messier_id IS NOT NULL', limit: 1);
      expect(messierId, isNotEmpty, reason: 'Database must contain Messier catalog entries');

      // Verify sample NGC objects
      final List<Map<String, Object?>> ngcId = await db.query('dso', where: 'ngc_id IS NOT NULL', limit: 1);
      expect(ngcId, isNotEmpty, reason: 'Database must contain NGC catalog entries');
    });

    test('database has proper indices for performance', () async {
      // Check for indices on stars table
      final List<Map<String, Object?>> starsIndices = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='stars'",
      );

      // At minimum, there should be indices on frequently queried columns
      // (SQLite auto-creates index on PRIMARY KEY, but we should verify others)
      expect(starsIndices.isNotEmpty, true, reason: 'stars table should have indices');

      // Check for indices on dso table
      final List<Map<String, Object?>> dsoIndices = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='dso'",
      );
      expect(dsoIndices.isNotEmpty, true, reason: 'dso table should have indices');
    });

    test('star data has valid astronomical coordinates', () async {
      final List<Map<String, Object?>> sampleStars = await db.query('stars', limit: 10);

      for (final Map<String, Object?> star in sampleStars) {
        final double? ra = star['ra'] as double?;
        final double? dec = star['dec'] as double?;

        if (ra != null) {
          expect(ra, greaterThanOrEqualTo(0.0), reason: 'RA must be >= 0');
          expect(ra, lessThan(360.0), reason: 'RA must be < 360 degrees');
        }

        if (dec != null) {
          expect(dec, greaterThanOrEqualTo(-90.0), reason: 'Dec must be >= -90');
          expect(dec, lessThanOrEqualTo(90.0), reason: 'Dec must be <= 90 degrees');
        }
      }
    });

    test('dso data has valid astronomical coordinates', () async {
      final List<Map<String, Object?>> sampleDsos = await db.query('dso', limit: 10);

      for (final Map<String, Object?> dso in sampleDsos) {
        final double? ra = dso['ra'] as double?;
        final double? dec = dso['dec'] as double?;

        if (ra != null) {
          expect(ra, greaterThanOrEqualTo(0.0), reason: 'RA must be >= 0');
          expect(ra, lessThan(360.0), reason: 'RA must be < 360 degrees');
        }

        if (dec != null) {
          expect(dec, greaterThanOrEqualTo(-90.0), reason: 'Dec must be >= -90');
          expect(dec, lessThanOrEqualTo(90.0), reason: 'Dec must be <= 90 degrees');
        }
      }
    });
  });
}
