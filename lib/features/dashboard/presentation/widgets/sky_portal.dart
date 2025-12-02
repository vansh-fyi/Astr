import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkyPortal extends StatelessWidget {
  final String qualityLabel;
  final int score;
  final VoidCallback? onTap;

  const SkyPortal({
    super.key,
    required this.qualityLabel,
    required this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glow Rings
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Colors.indigo.withOpacity(0.2),
                    Colors.purple.withOpacity(0.2),
                  ],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 4.seconds)
            .fade(begin: 0.5, end: 0.8, duration: 4.seconds),

            // Main Circle
            Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                   // Inner Ring
                   Positioned.fill(
                     child: Container(
                       margin: const EdgeInsets.all(4),
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(color: Colors.white.withOpacity(0.05)),
                       ),
                     ),
                   ),
                   
                   // Dashed Ring (Simulated with circular border and dash effect if possible, 
                   // but for now just a faint ring)
                   Positioned.fill(
                     child: Container(
                       margin: const EdgeInsets.all(30),
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(
                           color: Colors.white.withOpacity(0.1),
                           style: BorderStyle.solid, // Flutter doesn't support dashed borders natively on circles easily without custom painter
                           width: 1,
                         ),
                       ),
                     ).animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 60.seconds),
                   ),

                   // Content
                   Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(
                           'CONDITIONS',
                           style: TextStyle(
                             fontSize: 10,
                             letterSpacing: 2.0,
                             color: Colors.indigo[200],
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           qualityLabel,
                           style: const TextStyle(
                             fontSize: 48,
                             fontWeight: FontWeight.w500,
                             height: 1.0,
                             color: Colors.white,
                             letterSpacing: -1.0,
                           ),
                         ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                         const SizedBox(height: 8),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.green.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: Colors.green.withOpacity(0.2)),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Container(
                                 width: 6,
                                 height: 6,
                                 decoration: const BoxDecoration(
                                   color: Colors.greenAccent,
                                   shape: BoxShape.circle,
                                 ),
                               ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                .fadeIn(duration: 1.seconds)
                                .fadeOut(duration: 1.seconds),
                               const SizedBox(width: 6),
                               Text(
                                 '$score/100',
                                 style: const TextStyle(
                                   fontSize: 10,
                                   fontWeight: FontWeight.w500,
                                   color: Colors.greenAccent,
                                   letterSpacing: 0.5,
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            

          ],
        ),
      ),
    );
  }
}
