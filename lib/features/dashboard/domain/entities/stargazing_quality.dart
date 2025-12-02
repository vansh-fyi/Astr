enum StargazingQuality {
  excellent,
  good,
  fair,
  poor;

  String get label {
    switch (this) {
      case StargazingQuality.excellent:
        return 'Excellent';
      case StargazingQuality.good:
        return 'Good';
      case StargazingQuality.fair:
        return 'Fair';
      case StargazingQuality.poor:
        return 'Poor';
    }
  }

  int get score {
    switch (this) {
      case StargazingQuality.excellent:
        return 95;
      case StargazingQuality.good:
        return 75;
      case StargazingQuality.fair:
        return 50;
      case StargazingQuality.poor:
        return 25;
    }
  }
}
