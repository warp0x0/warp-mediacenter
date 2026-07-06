import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/warp_theme.dart';
import '../../theme/warp_tokens.dart';

class WarpDpadButton extends StatefulWidget {
  const WarpDpadButton({
    super.key,
    required this.child,
    required this.onSelect,
    required this.tokens,
    this.focusNode,
    this.onDirection,
    this.autofocus = false,
    this.entry = false,
    this.enabled = true,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.backgroundColor,
    this.focusBackgroundColor,
    this.borderColor,
    this.focusBorderColor,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onSelect;
  final WarpTokens tokens;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;
  final bool autofocus;
  final bool entry;
  final bool enabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? focusBackgroundColor;
  final Color? borderColor;
  final Color? focusBorderColor;
  final double? borderRadius;

  @override
  State<WarpDpadButton> createState() => _WarpDpadButtonState();
}

class _WarpDpadButtonState extends State<WarpDpadButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? widget.tokens.radiusBtn;
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DpadFocusable(
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        entry: widget.entry,
        onDirection: widget.onDirection,
        onSelect: widget.onSelect,
        tapToSelect: false,
        builder: (context, state, child) {
          final active = state.focused || _hovered;
          return GestureDetector(
            onTap: widget.enabled
                ? () {
                    widget.focusNode?.requestFocus();
                    widget.onSelect();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: active
                    ? (widget.focusBackgroundColor ?? Colors.white.withAlpha(26))
                    : (widget.backgroundColor ?? Colors.white.withAlpha(13)),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: active
                      ? (widget.focusBorderColor ?? WarpColors.accent)
                      : (widget.borderColor ?? Colors.white.withAlpha(25)),
                  width: state.focused ? widget.tokens.focusRingWidth : 1,
                ),
              ),
              child: Center(child: child),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class WarpDpadTextField extends StatelessWidget {
  const WarpDpadTextField({
    super.key,
    required this.controller,
    required this.fieldFocusNode,
    required this.wrapperFocusNode,
    required this.tokens,
    this.onDirection,
    this.onSubmitted,
    this.decoration,
    this.style,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode fieldFocusNode;
  final FocusNode wrapperFocusNode;
  final WarpTokens tokens;
  final DpadDirectionCallback? onDirection;
  final ValueChanged<String>? onSubmitted;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool obscureText;
  final Widget? suffixIcon;

  void _leaveEditMode() => wrapperFocusNode.requestFocus();

  @override
  Widget build(BuildContext context) {
    final baseDecoration = decoration ?? const InputDecoration();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _leaveEditMode,
        const SingleActivator(LogicalKeyboardKey.goBack): _leaveEditMode,
        const SingleActivator(LogicalKeyboardKey.browserBack): _leaveEditMode,
      },
      child: DpadFocusable(
        focusNode: wrapperFocusNode,
        onSelect: () => fieldFocusNode.requestFocus(),
        onDirection: onDirection,
        excludeChildFocus: false,
        builder: (context, state, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusBtn),
            border: Border.all(
              color: state.focused ? WarpColors.accent : Colors.transparent,
              width: tokens.focusRingWidth,
            ),
          ),
          child: child,
        ),
        child: TextField(
          controller: controller,
          focusNode: fieldFocusNode,
          obscureText: obscureText,
          style: style,
          onSubmitted: onSubmitted,
          decoration: baseDecoration.copyWith(suffixIcon: suffixIcon ?? baseDecoration.suffixIcon),
        ),
      ),
    );
  }
}
