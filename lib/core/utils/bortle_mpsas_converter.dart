/// Utility for converting between Bortle Scale and MPSAS (mag/arcsec²)
///
/// Based on accepted astronomical standards:
/// - Bortle 1: 21.7-22.0 MPSAS (Excellent dark sky)
/// - Bortle 2: 21.5-21.7 MPSAS (Typical dark sky)
/// - Bortle 3: 21.3-21.5 MPSAS (Rural sky)
/// - Bortle 4: 20.4-21.3 MPSAS (Rural/suburban transition)
/// - Bortle 5: 19.1-20.4 MPSAS (Suburban sky)
/// - Bortle 6: 18.0-19.1 MPSAS (Bright suburban)
/// - Bortle 7: 18.0-19.0 MPSAS (Suburban/urban transition)
/// - Bortle 8: 17.0-18.0 MPSAS (City sky)
/// - Bortle 9: <17.0 MPSAS (Inner city)
///
/// References:
/// - Bortle, J. E. (2001). "Introducing the Bortle Dark-Sky Scale"
/// - IDA Light Pollution Atlas color mapping
class BortleMpsasConverter {
  /// Converts Bortle class (1-9) to typical MPSAS value
  ///
  /// Returns the mid-point of the MPSAS range for each Bortle class
  static double bortleToMpsas(int bortleClass) {
    switch (bortleClass) {
      case 1:
        return 21.85; // Excellent dark sky (mid-point of 21.7-22.0)
      case 2:
        return 21.60; // Typical dark sky (mid-point of 21.5-21.7)
      case 3:
        return 21.40; // Rural sky (mid-point of 21.3-21.5)
      case 4:
        return 20.85; // Rural/suburban (mid-point of 20.4-21.3)
      case 5:
        return 19.75; // Suburban (mid-point of 19.1-20.4)
      case 6:
        return 18.55; // Bright suburban (mid-point of 18.0-19.1)
      case 7:
        return 18.50; // Suburban/urban (mid-point of 18.0-19.0)
      case 8:
        return 17.50; // City sky (mid-point of 17.0-18.0)
      case 9:
        return 16.50; // Inner city (<17.0)
      default:
        // Default to mid-range if invalid input
        return 19;
    }
  }

  /// Converts MPSAS value to approximate Bortle class
  ///
  /// Useful for inverse calculations or validation
  static int mpsasToBortle(double mpsas) {
    if (mpsas >= 21.7) return 1;
    if (mpsas >= 21.5) return 2;
    if (mpsas >= 21.3) return 3;
    if (mpsas >= 20.4) return 4;
    if (mpsas >= 19.1) return 5;
    if (mpsas >= 18.5) return 6;
    if (mpsas >= 18.0) return 7;
    if (mpsas >= 17.0) return 8;
    return 9;
  }

  /// Returns a human-readable description for a Bortle class
  static String bortleDescription(int bortleClass) {
    switch (bortleClass) {
      case 1:
        return 'Excellent Dark Sky';
      case 2:
        return 'Typical Dark Sky';
      case 3:
        return 'Rural Sky';
      case 4:
        return 'Rural/Suburban Transition';
      case 5:
        return 'Suburban Sky';
      case 6:
        return 'Bright Suburban';
      case 7:
        return 'Suburban/Urban Transition';
      case 8:
        return 'City Sky';
      case 9:
        return 'Inner City';
      default:
        return 'Unknown';
    }
  }
}
