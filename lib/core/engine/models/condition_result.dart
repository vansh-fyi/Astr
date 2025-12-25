import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'condition_quality.dart';

/// Result of qualitative condition evaluation
class ConditionResult extends Equatable {

  const ConditionResult({
    required this.quality,
    required this.shortSummary,
    required this.detailedAdvice,
    required this.statusColor,
  });
  /// The overall quality assessment
  final ConditionQuality quality;

  /// Short summary text (e.g., "Excellent", "Poor")
  final String shortSummary;

  /// Detailed advice for the user (e.g., "Milky Way Visible", "Planets Only")
  final String detailedAdvice;

  /// Color representing the condition quality
  final Color statusColor;

  @override
  List<Object?> get props => <Object?>[quality, shortSummary, detailedAdvice, statusColor];
}
