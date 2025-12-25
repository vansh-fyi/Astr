import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// AC#10: Custom Loading Indicator with Lottie animation and cycling text
/// Replaces standard CircularProgressIndicator with "cosmic" theme
class CosmicLoader extends StatefulWidget {

  const CosmicLoader({
    super.key,
    this.size = 60,
    this.showText = true,
  });
  final double size;
  final bool showText;

  @override
  State<CosmicLoader> createState() => _CosmicLoaderState();
}

class _CosmicLoaderState extends State<CosmicLoader> {
  int _textIndex = 0;
  Timer? _timer;

  static const List<String> _loadingTexts = <String>[
    'Connecting to NASA',
    'Calculating Light Pollution',
    'Looking out for clouds',
    'Mapping the stars',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.showText) {
      _startTextCycle();
    }
  }

  void _startTextCycle() {
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Lottie.asset(
            'assets/lottie/loader.json',
            fit: BoxFit.contain,
          ),
        ),
        if (widget.showText) ...<Widget>[
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loadingTexts[_textIndex],
              key: ValueKey<int>(_textIndex),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
