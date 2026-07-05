import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../providers/tos_provider.dart';

class ToSScreen extends ConsumerWidget {
  const ToSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Terms of Service',
                  style: AppTypography.title.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Astr is not liable for accidents or injuries.\n\nStargazing locations are suggestions only; verify safety yourself.',
                  style: AppTypography.body.copyWith(
                        color: AppColors.textSubdued,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(tosNotifierProvider.notifier).accept();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('I Agree'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
