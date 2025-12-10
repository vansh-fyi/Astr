import 'dart:ui';
import 'package:flutter/material.dart';

/// Optimized glass-morphism panel with performance enhancements
///
/// Performance optimizations:
/// - RepaintBoundary prevents unnecessary repaints of blur filter
/// - Static blur sigma values reduce GPU overhead
/// - Const constructors where possible
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  final bool enableBlur;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.border,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    // Optimized Style for Non-Blur (Performance Mode)
    // Higher opacity to mask background since we don't blur it
    final backgroundColor = enableBlur 
        ? const Color(0xFF121212).withValues(alpha: 0.8) 
        : const Color(0xFF121212).withValues(alpha: 0.95);

    // Subtle border for definition
    final borderColor = border ?? Border.all(
      color: Colors.white.withValues(alpha: enableBlur ? 0.08 : 0.12),
      width: 1,
    );

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: borderColor,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: content,
      );
    }

    if (!enableBlur) {
      // Return container directly without BackdropFilter/ClipRRect/RepaintBoundary
      // This is the key performance win.
      return content;
    }

    // Wrap BackdropFilter in RepaintBoundary to prevent unnecessary repaints
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: content,
        ),
      ),
    );
  }
}
