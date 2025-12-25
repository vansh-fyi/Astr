import 'package:equatable/equatable.dart';

class MoonPhaseInfo extends Equatable {   // 0 to 360 degrees (0=New, 90=First Quarter, 180=Full, 270=Last Quarter)

  const MoonPhaseInfo({
    required this.illumination,
    required this.phaseAngle,
  });
  final double illumination; // 0.0 to 1.0
  final double phaseAngle;

  @override
  List<Object?> get props => <Object?>[illumination, phaseAngle];
}
