enum CelestialBody {
  sun,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}
