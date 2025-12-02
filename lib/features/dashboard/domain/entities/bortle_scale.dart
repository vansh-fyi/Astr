enum BortleScale {
  class1(1, 'Excellent Dark Sky site'),
  class2(2, 'Typical truly dark site'),
  class3(3, 'Rural sky'),
  class4(4, 'Rural/suburban transition'),
  class5(5, 'Suburban sky'),
  class6(6, 'Bright suburban sky'),
  class7(7, 'Suburban/urban transition'),
  class8(8, 'City sky'),
  class9(9, 'Inner-city sky');

  final int value;
  final String description;

  const BortleScale(this.value, this.description);

  static BortleScale fromValue(int value) {
    return BortleScale.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BortleScale.class9, // Default to worst case if out of bounds
    );
  }
}
