import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/engine/models/condition_result.dart';

class SkyPortal extends StatelessWidget {

  const SkyPortal({
    super.key,
    required this.qualityLabel,
    required this.score,
    this.onTap,
    this.conditionResult,
  });
  final String qualityLabel;
  final int score;
  final VoidCallback? onTap;
  final ConditionResult? conditionResult;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Outer Glow Rings
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: <Color>[
                    Colors.indigo.withOpacity(0.2),
                    Colors.purple.withOpacity(0.2),
                  ],
                ),
              ),
            )
            .animate(onPlay: (AnimationController controller) => controller.repeat(reverse: true))
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
                  colors: <Color>[
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
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
                         ),
                       ),
                     ).animate(onPlay: (AnimationController controller) => controller.repeat())
                      .rotate(duration: 60.seconds),
                   ),

                   // Content
                   Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: <Widget>[
                         Text(
                           'CONDITIONS',
                           style: TextStyle(
                             fontSize: 10,
                             letterSpacing: 2,
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
                             height: 1,
                             color: Colors.white,
                             letterSpacing: -1,
                           ),
                         ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                         const SizedBox(height: 8),
                         // Qualitative Advice or Numeric Score
                         if (conditionResult != null)
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                             decoration: BoxDecoration(
                               color: conditionResult!.statusColor.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(20),
                               border: Border.all(color: conditionResult!.statusColor.withOpacity(0.2)),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: <Widget>[
                                 Container(
                                   width: 6,
                                   height: 6,
                                   decoration: BoxDecoration(
                                     color: conditionResult!.statusColor,
                                     shape: BoxShape.circle,
                                   ),
                                 ).animate(onPlay: (AnimationController controller) => controller.repeat(reverse: true))
                                  .fadeIn(duration: 1.seconds)
                                  .fadeOut(duration: 1.seconds),
                                 const SizedBox(width: 6),
                                 Text(
                                   conditionResult!.detailedAdvice,
                                   style: TextStyle(
                                     fontSize: 10,
                                     fontWeight: FontWeight.w500,
                                     color: conditionResult!.statusColor,
                                     letterSpacing: 0.5,
                                   ),
                                 ),
                               ],
                             ),
                           )
                         else
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.green.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(20),
                               border: Border.all(color: Colors.green.withOpacity(0.2)),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: <Widget>[
                                 Container(
                                   width: 6,
                                   height: 6,
                                   decoration: const BoxDecoration(
                                     color: Colors.greenAccent,
                                     shape: BoxShape.circle,
                                   ),
                                 ).animate(onPlay: (AnimationController controller) => controller.repeat(reverse: true))
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
