import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../domain/entities/stargazing_quality.dart';

class SummaryText extends StatelessWidget {

  const SummaryText({
    super.key,
    required this.quality,
  });
  final StargazingQuality quality;

  String get _text {
    switch (quality) {
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

  @override
  Widget build(BuildContext context) {
    // "Starlight" white font - using design system tokens
    final TextStyle textStyle = AppTypography.display.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        );

    Widget textWidget = Text(
      _text,
      style: textStyle,
      textAlign: TextAlign.center,
    );

    if (quality == StargazingQuality.excellent) {
      // AC-2.2.4: animate-pulse-glow
      // Using flutter_animate to create a subtle pulse and glow effect
      textWidget = textWidget
          .animate(onPlay: (AnimationController controller) => controller.repeat(reverse: true))
          .custom(
            duration: 2000.ms,
            builder: (BuildContext context, double value, Widget child) {
              // Custom glow effect using shadow
              return DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.5 * value),
                      blurRadius: 20 * value,
                      spreadRadius: 2 * value,
                    ),
                  ],
                ),
                child: child,
              );
            },
          )
          .scaleXY(end: 1.05, duration: 2000.ms, curve: Curves.easeInOut);
    }

    return textWidget;
  }
}
