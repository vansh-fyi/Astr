/// Enum defining types of celestial objects in the catalog
enum CelestialType {
  planet,
  star,
  constellation,
  galaxy,
  nebula,
  cluster;

  String get displayName {
    switch (this)  {
      case CelestialType.planet:
        return 'Planets';
      case CelestialType.star:
        return 'Stars';
      case CelestialType.constellation:
        return 'Constellations';
      case CelestialType.galaxy:
        return 'Galaxies';
      case CelestialType.nebula:
        return 'Nebulae';
      case CelestialType.cluster:
        return 'Clusters';
    }
  }
}
