import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// A wrapper around [RiveAnimation] to facilitate testing.
/// 
/// Rive uses FFI for text rendering which can cause crashes in widget tests
/// if the native libraries aren't available or configured correctly.
/// This wrapper allows us to disable the actual Rive rendering during tests.
class AstrRiveAnimation extends StatelessWidget {
  final String asset;
  final String? artboard;
  final BoxFit? fit;
  final void Function(Artboard)? onInit;

  const AstrRiveAnimation.asset(
    this.asset, {
    super.key,
    this.artboard,
    this.fit,
    this.onInit,
  });

  /// Set this to true in your test `setUp` to prevent Rive from loading.
  static bool testMode = false;

  @override
  Widget build(BuildContext context) {
    if (testMode) {
      return SizedBox(
        key: const Key('rive_placeholder'),
        child: Text('Rive Animation: $asset ($artboard)'),
      );
    }
    return RiveAnimation.asset(
      asset,
      artboard: artboard,
      fit: fit,
      onInit: onInit,
    );
  }
}
