import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/presentation/widgets/nebula_background.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020204),
      body: Stack(
        children: [
          const NebulaBackground(),
          const Center(
            child: Text(
              'Forecast Screen',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
