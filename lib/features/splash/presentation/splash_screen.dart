import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Splash screen with Lottie animation
/// AC#9: Loops animation exactly 3 times before transitioning
class SplashScreen extends StatefulWidget {

  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
  });
  final VoidCallback onInitializationComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _loopCount = 0;
  static const int _maxLoops = 3; // AC#9: Loop exactly 3 times

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _loopCount++;
      if (_loopCount < _maxLoops) {
        // Restart animation for next loop
        _controller.reset();
        _controller.forward();
      } else {
        // AC#9: All loops complete, transition to home
        widget.onInitializationComplete();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B), // Match flutter_native_splash
      body: Center(
        child: Lottie.asset(
          'assets/lottie/logo.json',
          controller: _controller,
          onLoaded: (LottieComposition composition) {
            _controller
              ..duration = composition.duration
              ..forward(); // Start first loop
          },
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
