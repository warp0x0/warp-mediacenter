import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../theme/warp_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WarpAccentButton — shared CTA-button focus treatment
//
// Global rule: CTA buttons (Play Trailer, More Info, Resume, Play, Quit App,
// Search, See More, Connect/Disconnect, Reset/Done, ...) never show a focus
// ring or glow. Unfocused, every one of them renders the same dark
// background + cyan border ("More Info" secondary look). Focused, the
// button reveals its own native accent color as a filled background
// instead — Play Trailer/most CTAs -> cyan, Resume -> amber, Play/Quit App
// (destructive) -> red.
//
// Wraps DpadFocusable directly so callers wire navigation exactly like a
// raw DpadFocusable (focusNode/onSelect/onDirection/autofocus/entry) while
// getting this visual treatment for free.
// ─────────────────────────────────────────────────────────────────────────────

class WarpAccentButton extends StatelessWidget {
  const WarpAccentButton({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onSelect,
    this.icon,
    this.focusNode,
    this.onDirection,
    this.autofocus = false,
    this.entry = false,
    this.fontSize = 16,
    this.paddingHorizontal = 24,
    this.paddingVertical = 14,
  });

  final String label;
  final IconData? icon;

  /// The color revealed as a filled background when this button is focused.
  /// Unfocused, the button always shows the dark-bg/cyan-border default
  /// regardless of this color.
  final Color accentColor;

  final VoidCallback onSelect;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;
  final bool autofocus;
  final bool entry;
  final double fontSize;
  final double paddingHorizontal;
  final double paddingVertical;

  static const _darkBg = Color(0xCC333232);
  static const _cyanBorder = WarpColors.accent;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      focusNode: focusNode,
      onSelect: onSelect,
      onDirection: onDirection,
      autofocus: autofocus,
      entry: entry,
      builder: (context, state, child) {
        final focused = state.focused;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: paddingHorizontal,
            vertical: paddingVertical,
          ),
          decoration: BoxDecoration(
            color: focused ? accentColor : _darkBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: focused ? accentColor : _cyanBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: fontSize + 2),
                SizedBox(width: fontSize * 0.4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
