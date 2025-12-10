import 'package:flutter/material.dart';
import 'package:astr/core/widgets/glass_panel.dart';

class CloudBar extends StatefulWidget {
  final double cloudCoverPercentage; // 0-100
  final bool isLoading;
  final String? errorMessage;

  const CloudBar({
    super.key,
    required this.cloudCoverPercentage,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<CloudBar> createState() => _CloudBarState();
}

class _CloudBarState extends State<CloudBar> {


  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cloud Cover',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
              if (widget.isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else if (widget.errorMessage != null)
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16)
              else
                Text(
                  '${widget.cloudCoverPercentage.toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.errorMessage != null)
            Text(
              widget.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            )
          else
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        width: constraints.maxWidth * (widget.cloudCoverPercentage / 100),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
