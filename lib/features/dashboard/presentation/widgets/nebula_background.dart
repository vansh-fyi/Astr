import 'package:flutter/material.dart';

class NebulaBackground extends StatelessWidget {
  const NebulaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Color
        Container(
          color: const Color(0xFF020204),
        ),
        // Nebula Gradient 1 (Indigo)
        Positioned(
          top: -100,
          left: MediaQuery.of(context).size.width / 2 - 400,
          child: Container(
            width: 800,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.indigo.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                radius: 0.6,
              ),
            ),
          ),
        ),
        // Nebula Gradient 2 (Purple)
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                radius: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
