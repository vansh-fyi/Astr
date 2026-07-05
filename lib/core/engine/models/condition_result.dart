import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'condition_quality.dart';
import 'sky_state.dart';

/// Result of qualitative condition evaluation
class ConditionResult extends Equatable {

  const ConditionResult({
    required this.quality,
    required this.shortSummary,
    required this.detailedAdvice,
    required this.statusColor,
    required this.skyState,
  });
  /// The overall quality assessment
  final ConditionQuality quality;

  /// Short summary text (e.g., "Excellent", "Poor")
  final String shortSummary;

  /// Detailed advice for the user (e.g., "Milky Way Visible", "Planets Only")
  final String detailedAdvice;

  /// Color representing the condition quality
  final Color statusColor;

  /// The visual sky state
  final SkyState skyState;

  @override
  List<Object?> get props => <Object?>[quality, shortSummary, detailedAdvice, statusColor, skyState];
}
