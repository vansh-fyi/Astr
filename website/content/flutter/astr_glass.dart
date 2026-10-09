import 'dart:ui';

import 'package:flutter/material.dart';

import 'astr_colors.dart';
import 'astr_layout.dart';
import 'astr_opacity.dart';
import 'astr_spacing.dart';
import 'astr_type.dart';

/// The five accent tones for glass tiles and buttons, named by the colour they
/// are. Each is a stop from [AstrColors], so a tone can never drift from the
/// colour system.
enum AstrTone {
  deepSpace,
  auroraGreen,
  auroraPink,
  sodiumAirglow,
  oxygenAirglow;

  Color get color => switch (this) {
        AstrTone.deepSpace => AstrColors.deepSpace[200]!,
        AstrTone.auroraGreen => AstrColors.auroraGreen[400]!,
        AstrTone.auroraPink => AstrColors.auroraPink[400]!,
        AstrTone.sodiumAirglow => AstrColors.sodiumAirglow[400]!,
        AstrTone.oxygenAirglow => AstrColors.oxygenAirglow[400]!,
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
/// bottom edge. When [selected] the tile fills with the tone. Pressed, it
/// squeezes slightly and its glow grows, like the hover state on the web.
class AstrGlassTile extends StatefulWidget {
  const AstrGlassTile({
    super.key,
    required this.icon,
    required this.label,
    this.tone = AstrTone.deepSpace,
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
  State<AstrGlassTile> createState() => _AstrGlassTileState();
}

class _AstrGlassTileState extends State<AstrGlassTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color c = widget.tone.color;
    final AstrTileSize size = widget.size;
    final bool selected = widget.selected;
    final BorderRadius radius = BorderRadius.circular(size.edge * AstrLayout.minor);

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: Opacity(
        opacity: widget.onPressed == null ? Mag.m2 : 1,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 100),
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
                    color: c.withValues(alpha: selected || _pressed ? Mag.m0 : Mag.m1),
                    blurRadius: AstrSpace.f34,
                    spreadRadius: _pressed ? -AstrSpace.f8 : -AstrSpace.f13,
                    offset: const Offset(0, AstrSpace.f13),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: widget.onPressed,
                onHighlightChanged: (bool value) => setState(() => _pressed = value),
                child: Icon(
                  widget.icon,
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
      ),
    );
  }
}

/// Visual weight of an [AstrGlassButton]. Filled is the default.
enum AstrButtonVariant { filled, glass, outline }

/// A pill button, [AstrSize.control] tall (55, the touch target), or
/// [AstrSize.controlCompact] (34). Filled uses the tone as its fill with dark
/// text; glass tints the surface; outline draws only the edge. Pressed, it
/// squeezes slightly and glows in its tone, even the quiet variants.
class AstrGlassButton extends StatefulWidget {
  const AstrGlassButton({
    super.key,
    required this.label,
    this.icon,
    this.tone = AstrTone.deepSpace,
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
  State<AstrGlassButton> createState() => _AstrGlassButtonState();
}

class _AstrGlassButtonState extends State<AstrGlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color c = widget.tone.color;
    final Color text = AstrColors.spaceGrey[50]!;
    final AstrButtonVariant variant = widget.variant;
    final bool filled = variant == AstrButtonVariant.filled;
    final Color fg = switch (variant) {
      AstrButtonVariant.filled => _ink,
      AstrButtonVariant.glass => text,
      AstrButtonVariant.outline => c,
    };
    final BorderRadius radius = BorderRadius.circular(AstrRadius.f34 * 2);

    return Opacity(
      opacity: widget.onPressed == null ? Mag.m2 : 1,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            height: widget.compact ? AstrSize.controlCompact : AstrSize.control,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: switch (variant) {
                  AstrButtonVariant.filled => Color.alphaBlend(text.withValues(alpha: Mag.m3), c),
                  AstrButtonVariant.glass => c.withValues(alpha: Mag.m2),
                  AstrButtonVariant.outline => c,
                },
              ),
              color: variant == AstrButtonVariant.outline && _pressed ? c.withValues(alpha: Mag.m5) : null,
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
              boxShadow: filled || _pressed
                  ? <BoxShadow>[
                      BoxShadow(
                        color: c,
                        blurRadius: AstrSpace.f21,
                        spreadRadius: _pressed ? -AstrSpace.f5 : -AstrSpace.f8,
                        offset: Offset(0, _pressed ? AstrSpace.f13 : AstrSpace.f8),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onPressed,
              onHighlightChanged: (bool value) => setState(() => _pressed = value),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.compact ? AstrSpace.f13 : AstrSpace.f21),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.icon != null) ...<Widget>[
                      Icon(widget.icon, size: AstrSize.icon, color: variant == AstrButtonVariant.glass ? c : fg),
                      const SizedBox(width: AstrSpace.f8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: widget.compact ? AstrType.sNeg1 : AstrType.s0,
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

/// A switch. The track is a golden rectangle, 55 by 34, with a 21 thumb; when
/// [compact] it steps down the Fibonacci ladder to 34 by 21 and a 13 thumb.
/// On, the track fills with the tone and the thumb turns dark.
class AstrGlassToggle extends StatefulWidget {
  const AstrGlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.tone = AstrTone.deepSpace,
    this.compact = false,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Accessible name, read by screen readers.
  final String label;
  final AstrTone tone;
  final bool compact;

  @override
  State<AstrGlassToggle> createState() => _AstrGlassToggleState();
}

class _AstrGlassToggleState extends State<AstrGlassToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final AstrGlassToggle w = widget;
    final bool value = w.value;
    final Color c = w.tone.color;
    final Color text = AstrColors.spaceGrey[50]!;
    final double trackW = w.compact ? AstrSpace.f34 : AstrSpace.f55;
    final double trackH = w.compact ? AstrSpace.f21 : AstrSpace.f34;
    final double thumb = w.compact ? AstrSpace.f13 : AstrSpace.f21;
    final double inset = (trackH - thumb) / 2;
    const Duration duration = Duration(milliseconds: 300);

    return Semantics(
      toggled: value,
      label: w.label,
      child: Opacity(
        opacity: w.onChanged == null ? Mag.m2 : 1,
        child: GestureDetector(
          onTap: w.onChanged == null ? null : () => w.onChanged!(!value),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: trackW,
            height: trackH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(trackH),
              border: Border.all(color: value ? Color.alphaBlend(text.withValues(alpha: Mag.m3), c) : text.withValues(alpha: Mag.m5)),
              gradient: value
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color.alphaBlend(text.withValues(alpha: Mag.m3), c), c],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[text.withValues(alpha: Mag.m5), text.withValues(alpha: Mag.m8)],
                    ),
              boxShadow: value || _pressed
                  ? <BoxShadow>[BoxShadow(color: c, blurRadius: AstrSpace.f21, spreadRadius: -AstrSpace.f8, offset: const Offset(0, AstrSpace.f8))]
                  : null,
            ),
            child: AnimatedAlign(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: inset - AstrSpace.f1),
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? _ink : AstrColors.spaceGrey[300],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text field on the glass material: a label above, the control with an
/// optional leading icon, and a line of help or error text below. The control
/// is [AstrSize.control] tall (55), or [AstrSize.controlCompact] (34); focus
/// draws [tone] on the border.
class AstrGlassTextField extends StatelessWidget {
  const AstrGlassTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.icon,
    this.tone = AstrTone.deepSpace,
    this.compact = false,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.keyboardType,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? icon;
  final AstrTone tone;
  final bool compact;

  /// 1 for a single line, more for a multiline field.
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final Color text = AstrColors.spaceGrey[50]!;
    final Color muted = AstrColors.spaceGrey[300]!;
    final Color error = AstrColors.oxygenAirglow[400]!;
    final double radius = compact ? AstrRadius.f8 : AstrRadius.f13;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color),
        );

    return Opacity(
      opacity: enabled ? 1 : Mag.m2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontFamily: 'Satoshi', fontSize: AstrType.sNeg1, fontWeight: FontWeight.w500, color: text),
          ),
          const SizedBox(height: AstrSpace.f5),
          TextField(
            controller: controller,
            enabled: enabled,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(fontSize: compact ? AstrType.sNeg1 : AstrType.s0, color: text),
            cursorColor: tone.color,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: muted.withValues(alpha: Mag.m1)),
              helperText: helperText,
              helperStyle: TextStyle(fontSize: AstrType.sNeg2, color: muted),
              errorText: errorText,
              errorStyle: TextStyle(fontSize: AstrType.sNeg2, color: error),
              prefixIcon: icon == null ? null : Icon(icon, size: compact ? AstrSpace.f13 : AstrSize.icon, color: muted),
              filled: true,
              fillColor: text.withValues(alpha: Mag.m7),
              constraints: BoxConstraints(minHeight: compact ? AstrSize.controlCompact : AstrSize.control),
              contentPadding: EdgeInsets.symmetric(horizontal: compact ? AstrSpace.f8 : AstrSpace.f13, vertical: AstrSpace.f13),
              enabledBorder: border(text.withValues(alpha: Mag.m5)),
              focusedBorder: border(tone.color),
              errorBorder: border(error),
              focusedErrorBorder: border(error),
              disabledBorder: border(text.withValues(alpha: Mag.m5)),
            ),
          ),
        ],
      ),
    );
  }
}
