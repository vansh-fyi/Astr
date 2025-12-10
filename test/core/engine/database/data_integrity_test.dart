import 'dart:io';
import 'package:astr/core/engine/models/dso.dart';
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
      final assetDb = File('assets/db/astr.db');
      expect(assetDb.existsSync(), true, reason: 'astr.db must exist in assets/db/');

      // Copy to temp location for testing
      final testDir = await Directory.systemTemp.createTemp('astr_integrity_test_');
      final testDbPath = join(testDir.path, 'astr.db');
      await assetDb.copy(testDbPath);

      db = await databaseFactory.openDatabase(testDbPath, options: OpenDatabaseOptions(readOnly: true));
    });

    tearDownAll(() async {
      await db.close();
    });

    test('database schema matches architecture.md specification', () async {
      // Verify stars table exists with correct schema
      final starsTable = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='stars'",
      );
      expect(starsTable, isNotEmpty, reason: 'stars table must exist');

      final starsSchema = starsTable.first['sql'] as String;
      expect(starsSchema.toLowerCase(), contains('hip_id'), reason: 'stars table must have hip_id column');
      expect(starsSchema.toLowerCase(), contains('ra'), reason: 'stars table must have ra column');
      expect(starsSchema.toLowerCase(), contains('dec'), reason: 'stars table must have dec column');
      expect(starsSchema.toLowerCase(), contains('mag'), reason: 'stars table must have mag column');
      expect(starsSchema.toLowerCase(), contains('name'), reason: 'stars table must have name column');
      expect(starsSchema.toLowerCase(), contains('constellation'), reason: 'stars table must have constellation column');

      // Verify dso table exists with correct schema
      final dsoTable = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='dso'",
      );
      expect(dsoTable, isNotEmpty, reason: 'dso table must exist');

      final dsoSchema = dsoTable.first['sql'] as String;
      expect(dsoSchema.toLowerCase(), contains('messier_id'), reason: 'dso table must have messier_id column');
      expect(dsoSchema.toLowerCase(), contains('ngc_id'), reason: 'dso table must have ngc_id column');
      expect(dsoSchema.toLowerCase(), contains('type'), reason: 'dso table must have type column');
      expect(dsoSchema.toLowerCase(), contains('ra'), reason: 'dso table must have ra column');
      expect(dsoSchema.toLowerCase(), contains('dec'), reason: 'dso table must have dec column');
      expect(dsoSchema.toLowerCase(), contains('mag'), reason: 'dso table must have mag column');
    });

    test('stars table contains Hipparcos catalog data', () async {
      final starCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM stars');
      final starCount = starCountResult.first['count'] as int;

      expect(starCount, greaterThan(0), reason: 'stars table must not be empty');
      // Note: Test database has minimal data; production should have full Hipparcos catalog

      // Verify sample well-known stars exist
      final sirius = await db.query('stars', where: 'LOWER(name) LIKE ?', whereArgs: ['%sirius%'], limit: 1);
      expect(sirius, isNotEmpty, reason: 'Sirius (brightest star) must be in database');

      final polaris = await db.query('stars', where: 'LOWER(name) LIKE ?', whereArgs: ['%polaris%'], limit: 1);
      expect(polaris, isNotEmpty, reason: 'Polaris must be in database');
    });

    test('dso table contains Messier and NGC catalog data', () async {
      final dsoCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM dso');
      final dsoCount = dsoCountResult.first['count'] as int;

      expect(dsoCount, greaterThan(0), reason: 'dso table must not be empty');
      // Note: Test database has minimal data; production should have full Messier/NGC catalogs

      // Verify Andromeda Galaxy (M31) exists
      final andromeda = await db.query(
        'dso',
        where: 'messier_id = ? OR LOWER(name) LIKE ?',
        whereArgs: ['M31', '%andromeda%'],
        limit: 1,
      );
      expect(andromeda, isNotEmpty, reason: 'Andromeda Galaxy (M31) must be in database');

      // Verify sample Messier objects
      final messierId = await db.query('dso', where: 'messier_id IS NOT NULL', limit: 1);
      expect(messierId, isNotEmpty, reason: 'Database must contain Messier catalog entries');

      // Verify sample NGC objects
      final ngcId = await db.query('dso', where: 'ngc_id IS NOT NULL', limit: 1);
      expect(ngcId, isNotEmpty, reason: 'Database must contain NGC catalog entries');
    });

    test('database has proper indices for performance', () async {
      // Check for indices on stars table
      final starsIndices = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='stars'",
      );

      // At minimum, there should be indices on frequently queried columns
      // (SQLite auto-creates index on PRIMARY KEY, but we should verify others)
      expect(starsIndices.isNotEmpty, true, reason: 'stars table should have indices');

      // Check for indices on dso table
      final dsoIndices = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='dso'",
      );
      expect(dsoIndices.isNotEmpty, true, reason: 'dso table should have indices');
    });

    test('star data has valid astronomical coordinates', () async {
      final sampleStars = await db.query('stars', limit: 10);

      for (final star in sampleStars) {
        final ra = star['ra'] as double?;
        final dec = star['dec'] as double?;

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
      final sampleDsos = await db.query('dso', limit: 10);

      for (final dso in sampleDsos) {
        final ra = dso['ra'] as double?;
        final dec = dso['dec'] as double?;

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
