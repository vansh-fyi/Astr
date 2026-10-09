import 'dart:ui';

import 'package:flutter/material.dart';

import 'astr_colors.dart';
import 'astr_layout.dart';
import 'astr_opacity.dart';
import 'astr_spacing.dart';
import 'astr_type.dart';

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

/// Tile edge lengths: the Fibonacci steps 34, 55 and 89. The corner radius is
/// the golden minor part of the edge (0.382), which lands on the next
/// Fibonacci radius down: 13, 21 and 34.
enum AstrTileSize {
  sm(AstrSpace.f34),
  md(AstrSpace.f55),
  lg(AstrSpace.f89);

  const AstrTileSize(this.edge);
  final double edge;
}

/// Text and glyphs on a filled tone.
final Color _ink = AstrColors.spaceGrey[950]!;

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
    final BorderRadius radius = BorderRadius.circular(size.edge * AstrLayout.minor);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Opacity(
        opacity: onPressed == null ? Mag.m2 : 1,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: size.edge,
            height: size.edge,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: c.withValues(alpha: Mag.m3)),
              color: selected ? c : null,
              gradient: selected
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color.alphaBlend(c.withValues(alpha: Mag.m4), _ink),
                        Color.alphaBlend(c.withValues(alpha: Mag.m6), _ink),
                      ],
                    ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: c.withValues(alpha: selected ? Mag.m0 : Mag.m1),
                  blurRadius: AstrSpace.f34,
                  spreadRadius: -AstrSpace.f13,
                  offset: const Offset(0, AstrSpace.f13),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Icon(
                icon,
                size: size.edge * AstrLayout.minor,
                color: selected ? _ink : c,
                shadows: selected
                    ? null
                    : <Shadow>[Shadow(color: c.withValues(alpha: Mag.m1), blurRadius: AstrSpace.f8)],
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

/// A pill button, [AstrSize.control] tall (55, the touch target), or
/// [AstrSize.controlCompact] (34).
/// Filled uses the tone as its fill with dark text; glass tints the surface;
/// outline draws only the edge.
class AstrGlassButton extends StatelessWidget {
  const AstrGlassButton({
    super.key,
    required this.label,
    this.icon,
    this.tone = AstrTone.blue,
    this.variant = AstrButtonVariant.filled,
    this.compact = false,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final AstrTone tone;
  final AstrButtonVariant variant;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color c = tone.color;
    final Color text = AstrColors.spaceGrey[50]!;
    final bool filled = variant == AstrButtonVariant.filled;
    final Color fg = switch (variant) {
      AstrButtonVariant.filled => _ink,
      AstrButtonVariant.glass => text,
      AstrButtonVariant.outline => c,
    };
    final BorderRadius radius = BorderRadius.circular(AstrRadius.f34 * 2);

    return Opacity(
      opacity: onPressed == null ? Mag.m2 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: compact ? AstrSize.controlCompact : AstrSize.control,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: switch (variant) {
                AstrButtonVariant.filled => Color.alphaBlend(text.withValues(alpha: Mag.m3), c),
                AstrButtonVariant.glass => c.withValues(alpha: Mag.m2),
                AstrButtonVariant.outline => c,
              },
            ),
            gradient: switch (variant) {
              AstrButtonVariant.filled => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color.alphaBlend(text.withValues(alpha: Mag.m3), c), c],
                ),
              AstrButtonVariant.glass => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.alphaBlend(c.withValues(alpha: Mag.m3), _ink),
                    Color.alphaBlend(c.withValues(alpha: Mag.m5), _ink),
                  ],
                ),
              AstrButtonVariant.outline => null,
            },
            boxShadow: filled
                ? <BoxShadow>[BoxShadow(color: c, blurRadius: AstrSpace.f21, spreadRadius: -AstrSpace.f8, offset: const Offset(0, AstrSpace.f8))]
                : null,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? AstrSpace.f13 : AstrSpace.f21),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: AstrSize.icon, color: variant == AstrButtonVariant.glass ? c : fg),
                    const SizedBox(width: AstrSpace.f8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: compact ? AstrType.sNeg1 : AstrType.s0,
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

/// The glass surface for cards: a sheen over the surface and a hairline edge.
/// Cards do not glow; glow belongs to buttons and tiles. Mini cards are
/// [AstrSpace.f144] wide and 144 + 21 tall.
class AstrGlassCard extends StatelessWidget {
  const AstrGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
  });

  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Color text = AstrColors.spaceGrey[50]!;
    final BorderRadius radius = BorderRadius.circular(AstrRadius.f21);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AstrSpace.f13, sigmaY: AstrSpace.f13),
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.all(AstrSpace.f13),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: text.withValues(alpha: Mag.m5)),
              color: _ink.withValues(alpha: Mag.m1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  text.withValues(alpha: Mag.m5),
                  text.withValues(alpha: Mag.m8),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
