import 'package:astr/core/error/failure.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/domain/repositories/i_catalog_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Implementation of ICatalogRepository using static offline data
class CatalogRepositoryImpl implements ICatalogRepository {
  // Static catalog data - offline, no external dependencies
  static final List<CelestialObject> _catalog = [
    // Solar System
    const CelestialObject(
      id: 'sun',
      name: 'Sun',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/sun.webp',
      magnitude: -26.74,
      ephemerisId: 0, // SE_SUN
    ),
    const CelestialObject(
      id: 'moon',
      name: 'Moon',
      type: CelestialType.planet,
      iconPath: 'assets/img/moon_full.webp', // Moon uses phase images
      magnitude: -12.74,
      ephemerisId: 1, // SE_MOON
    ),

    // Planets
    const CelestialObject(
      id: 'mercury',
      name: 'Mercury',
      type: CelestialType.planet,
      iconPath: 'assets/icons/planets/mercury.webp',
      magnitude: -1.9,
      ephemerisId: 1, // SE_MERCURY
    ),
    const CelestialObject(
      id: 'venus',
      name: 'Venus',
      type: CelestialType.planet,
      iconPath: 'assets/icons/planets/venus.webp',
      magnitude: -4.6,
      ephemerisId: 2, // SE_VENUS
    ),
    const CelestialObject(
      id: 'mars',
      name: 'Mars',
      type: CelestialType.planet,
      iconPath: 'assets/icons/planets/mars.webp',
      magnitude: -2.9,
      ephemerisId: 4, // SE_MARS
    ),
    const CelestialObject(
      id: 'jupiter',
      name: 'Jupiter',
      type: CelestialType.planet,
      iconPath: 'assets/icons/planets/jupiter.webp',
      magnitude: -2.9,
      ephemerisId: 5, // SE_JUPITER
    ),
    const CelestialObject(
      id: 'saturn',
      name: 'Saturn',
      type: CelestialType.planet,
      iconPath: 'assets/icons/planets/saturn.webp',
      magnitude: 0.7,
      ephemerisId: 6, // SE_SATURN
    ),
    const CelestialObject(
      id: 'uranus',
      name: 'Uranus',
      type: CelestialType.planet,
      iconPath: 'assets/icons/planets/uranus.webp',
      magnitude: 5.7,
      ephemerisId: 7, // SE_URANUS
    ),
    const CelestialObject(
      id: 'neptune',
      name: 'Neptune',
      type: CelestialType.planet,
      iconPath: 'assets/icons/planets/neptune.webp',
      magnitude: 7.8,
      ephemerisId: 8, // SE_NEPTUNE
    ),

    // Major Stars
    // Major Stars
    const CelestialObject(
      id: 'sirius',
      name: 'Sirius',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: -1.46,
      ephemerisId: null,
      ra: 101.287, // 06h 45m 09s
      dec: -16.716, // -16° 42′ 58″
    ),
    const CelestialObject(
      id: 'canopus',
      name: 'Canopus',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: -0.74,
      ephemerisId: null,
      ra: 95.988, // 06h 23m 57s
      dec: -52.696, // -52° 41′ 44″
    ),
    const CelestialObject(
      id: 'arcturus',
      name: 'Arcturus',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: -0.05,
      ephemerisId: null,
      ra: 213.915, // 14h 15m 40s
      dec: 19.183, // +19° 10′ 57″
    ),
    const CelestialObject(
      id: 'vega',
      name: 'Vega',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: 0.03,
      ephemerisId: null,
      ra: 279.234, // 18h 36m 56s
      dec: 38.784, // +38° 47′ 01″
    ),
    const CelestialObject(
      id: 'capella',
      name: 'Capella',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: 0.08,
      ephemerisId: null,
      ra: 79.172, // 05h 16m 41s
      dec: 45.998, // +45° 59′ 53″
    ),
    const CelestialObject(
      id: 'rigel',
      name: 'Rigel',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: 0.13,
      ephemerisId: null,
      ra: 78.634, // 05h 14m 32s
      dec: -8.202, // -08° 12′ 06″
    ),
    const CelestialObject(
      id: 'procyon',
      name: 'Procyon',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: 0.34,
      ephemerisId: null,
      ra: 114.825, // 07h 39m 18s
      dec: 5.225, // +05° 13′ 30″
    ),
    const CelestialObject(
      id: 'betelgeuse',
      name: 'Betelgeuse',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: 0.50,
      ephemerisId: null,
      ra: 88.793, // 05h 55m 10s
      dec: 7.407, // +07° 24′ 25″
    ),
    const CelestialObject(
      id: 'altair',
      name: 'Altair',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: 0.76,
      ephemerisId: null,
      ra: 297.696, // 19h 50m 47s
      dec: 8.868, // +08° 52′ 06″
    ),
    const CelestialObject(
      id: 'aldebaran',
      name: 'Aldebaran',
      type: CelestialType.star,
      iconPath: 'assets/icons/stars/star.webp',
      magnitude: 0.85,
      ephemerisId: null,
      ra: 68.980, // 04h 35m 55s
      dec: 16.509, // +16° 30′ 33″
    ),

    // Constellations
    const CelestialObject(
      id: 'orion',
      name: 'Orion',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/orion.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 83.5,
      dec: 3.0,
    ),
    const CelestialObject(
      id: 'ursa-major',
      name: 'Ursa Major',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/ursa_major.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 160.0,
      dec: 55.0,
    ),
    const CelestialObject(
      id: 'cassiopeia',
      name: 'Cassiopeia',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/cassiopeia.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 15.0,
      dec: 60.0,
    ),
    const CelestialObject(
      id: 'crux',
      name: 'Crux (Southern Cross)',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/crux.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 187.5,
      dec: -60.0,
    ),
    const CelestialObject(
      id: 'scorpius',
      name: 'Scorpius',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/scorpius.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 253.0,
      dec: -30.0,
    ),
    const CelestialObject(
      id: 'leo',
      name: 'Leo',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/leo.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 165.0,
      dec: 15.0,
    ),
    const CelestialObject(
      id: 'gemini',
      name: 'Gemini',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/gemini.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 105.0,
      dec: 20.0,
    ),
    const CelestialObject(
      id: 'andromeda',
      name: 'Andromeda',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/andromeda.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 12.0,
      dec: 37.0,
    ),
    const CelestialObject(
      id: 'cygnus',
      name: 'Cygnus',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/cygnus.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 307.5,
      dec: 40.0,
    ),
    const CelestialObject(
      id: 'lyra',
      name: 'Lyra',
      type: CelestialType.constellation,
      iconPath: 'assets/icons/constellations/lyra.webp',
      magnitude: null,
      ephemerisId: null,
      ra: 282.5,
      dec: 36.0,
    ),

    // Deep Sky Objects
    const CelestialObject(
      id: 'andromeda-galaxy',
      name: 'Andromeda Galaxy (M31)',
      type: CelestialType.galaxy,
      iconPath: 'assets/icons/galaxy/andromeda.webp',
      magnitude: 3.44,
      ra: 10.68, // 00h 42m 44s
      dec: 41.27, // +41° 16′ 9″
    ),
    const CelestialObject(
      id: 'orion-nebula',
      name: 'Orion Nebula (M42)',
      type: CelestialType.nebula,
      iconPath: 'assets/icons/nebula/orion_nebula.webp',
      magnitude: 4.0,
      ra: 83.82, // 05h 35m 17s
      dec: -5.38, // -05° 23′ 28″
    ),
    const CelestialObject(
      id: 'pleiades',
      name: 'Pleiades (M45)',
      type: CelestialType.cluster,
      iconPath: 'assets/icons/cluster/pleidas.webp',
      magnitude: 1.6,
      ra: 56.75, // 03h 47m 24s
      dec: 24.12, // +24° 07′ 00″
    ),
  ];

  @override
  Future<Either<Failure, List<CelestialObject>>> getObjectsByType(
    CelestialType type,
  ) async {
    try {
      final filtered = _catalog.where((obj) => obj.type == type).toList();
      return right(filtered);
    } catch (e) {
      return left(CacheFailure('Failed to filter catalog: $e'));
    }
  }

  @override
  Future<Either<Failure, CelestialObject>> getObjectById(String id) async {
    try {
      final object = _catalog.firstWhere(
        (obj) => obj.id == id,
        orElse: () => throw Exception('Object not found: $id'),
      );
      return right(object);
    } catch (e) {
      return left(CacheFailure('Object not found: $id'));
    }
  }

  @override
  Future<Either<Failure, List<CelestialObject>>> getAllObjects() async {
    try {
      return right(List.unmodifiable(_catalog));
    } catch (e) {
      return left(CacheFailure('Failed to load catalog: $e'));
    }
  }
}
