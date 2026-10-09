import 'dart:ui';

import 'package:flutter/material.dart';

import 'astr_colors.dart';
import 'astr_opacity.dart';

/// The five accent tones for glass tiles and buttons. Each is a stop from
/// [AstrColors], so a tone can never drift from the colour system.
enum AstrTone {
  blue,
  green,
  pink,
  amber,
  red;

  Color get color => switch (this) {
        AstrTone.blue => AstrColors.deepSpace[200]!,
        AstrTone.green => AstrColors.auroraGreen[400]!,
        AstrTone.pink => AstrColors.auroraPink[400]!,
        AstrTone.amber => AstrColors.sodiumAirglow[400]!,
        AstrTone.red => AstrColors.oxygenAirglow[400]!,
      };
}

/// Tile edge lengths in logical pixels. The corner radius is 28% of the edge.
enum AstrTileSize {
  sm(44),
  md(72),
  lg(96);

  const AstrTileSize(this.edge);
  final double edge;
}

const Color _kInk = Color(0xFF0C0F11);

/// A tinted glass square holding one glyph, with a bloom of its tone along the
/// bottom edge. When [selected] the tile fills with the tone.
class AstrGlassTile extends StatelessWidget {
  const AstrGlassTile({
    super.key,
    required this.icon,
    required this.label,
    this.tone = AstrTone.blue,
    this.size = AstrTileSize.md,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;

  /// Accessible name, read by screen readers.
  final String label;
  final AstrTone tone;
  final AstrTileSize size;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color c = tone.color;
    final BorderRadius radius = BorderRadius.circular(size.edge * 0.28);
    final Color glyph = selected ? _kInk : c;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: size.edge,
            height: size.edge,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: c.withValues(alpha: 0.35)),
              color: selected ? c : null,
              gradient: selected
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color.alphaBlend(c.withValues(alpha: 0.22), _kInk),
                        Color.alphaBlend(c.withValues(alpha: 0.08), _kInk),
                      ],
                    ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: c.withValues(alpha: selected ? 1 : Mag.m2),
                  blurRadius: 30,
                  spreadRadius: -12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Icon(
                icon,
                size: size.edge * 0.44,
                color: glyph,
                shadows: selected
                    ? null
                    : <Shadow>[Shadow(color: c.withValues(alpha: 0.7), blurRadius: 10)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual weight of an [AstrGlassButton]. Filled is the default.
enum AstrButtonVariant { filled, glass, outline }

/// A pill button. Filled uses the tone as its fill with dark text; glass tints
/// the surface; outline draws only the edge.
class AstrGlassButton extends StatelessWidget {
  const AstrGlassButton({
    super.key,
    required this.label,
    this.icon,
    this.tone = AstrTone.blue,
    this.variant = AstrButtonVariant.filled,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final AstrTone tone;
  final AstrButtonVariant variant;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color c = tone.color;
    final bool filled = variant == AstrButtonVariant.filled;
    final Color fg = switch (variant) {
      AstrButtonVariant.filled => _kInk,
      AstrButtonVariant.glass => AstrColors.spaceGrey[50]!,
      AstrButtonVariant.outline => c,
    };
    final BorderRadius radius = BorderRadius.circular(999);

    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: switch (variant) {
                AstrButtonVariant.filled => Color.lerp(c, Colors.white, 0.3)!,
                AstrButtonVariant.glass => c.withValues(alpha: 0.45),
                AstrButtonVariant.outline => c,
              },
            ),
            gradient: switch (variant) {
              AstrButtonVariant.filled => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color.lerp(c, Colors.white, 0.18)!, c],
                ),
              AstrButtonVariant.glass => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.alphaBlend(c.withValues(alpha: 0.3), _kInk),
                    Color.alphaBlend(c.withValues(alpha: 0.14), _kInk),
                  ],
                ),
              AstrButtonVariant.outline => null,
            },
            boxShadow: filled
                ? <BoxShadow>[BoxShadow(color: c.withValues(alpha: Mag.m2), blurRadius: 24, spreadRadius: -10, offset: const Offset(0, 8))]
                : null,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 18, color: variant == AstrButtonVariant.glass ? c : fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The glass surface for cards: a sheen over the overlay colour, a hairline
/// edge, an inset top highlight and a bloom of [tone] along the bottom edge.
/// Mini cards are 164 by 154 and the conditions card 345 by 242.
class AstrGlassCard extends StatelessWidget {
  const AstrGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.tone = AstrTone.blue,
  });

  final Widget child;
  final double? width;
  final double? height;
  final AstrTone tone;

  @override
  Widget build(BuildContext context) {
    final Color c = tone.color;
    final BorderRadius radius = BorderRadius.circular(16);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(color: c.withValues(alpha: Mag.m3), blurRadius: 36, spreadRadius: -18, offset: const Offset(0, 14)),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              gradient: RadialGradient(
                center: const Alignment(0, 1.2),
                radius: 0.9,
                colors: <Color>[c.withValues(alpha: Mag.m3), Colors.transparent],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
