import 'package:flutter/material.dart';

class RedModeOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const RedModeOverlay({
    super.key,
    required this.child,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0xFFCC0000), // Toned down red (80% brightness)
        BlendMode.multiply,
      ),
      child: child,
    );
  }
}
