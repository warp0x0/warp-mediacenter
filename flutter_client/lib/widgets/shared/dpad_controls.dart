import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/warp_theme.dart';
import '../../theme/warp_tokens.dart';
import 'warp_context_menu.dart';

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
    this.focusBoxShadow,
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
  final List<BoxShadow>? focusBoxShadow;
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
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DpadFocusable(
        effects: const [],
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
                    ? (widget.focusBackgroundColor ??
                          Colors.white.withAlpha(26))
                    : (widget.backgroundColor ?? Colors.white.withAlpha(13)),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: active
                      ? (widget.focusBorderColor ?? WarpColors.accent)
                      : (widget.borderColor ?? Colors.white.withAlpha(25)),
                  width: state.focused ? widget.tokens.focusRingWidth : 1,
                ),
                boxShadow: active ? widget.focusBoxShadow : null,
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

class WarpDpadTextField extends StatefulWidget {
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
    this.autofocus = false,
    this.entry = false,
    this.enabled = true,
    this.autoScroll = true,
    this.disableWrapperWhileEditing = false,
    this.moveCursorToEndOnEnter = false,
    this.enableSelectAllContextMenu = false,
    this.onExitEditMode,
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
  final bool autofocus;
  final bool entry;
  final bool enabled;
  final bool autoScroll;
  final bool disableWrapperWhileEditing;
  final bool moveCursorToEndOnEnter;
  final bool enableSelectAllContextMenu;
  final VoidCallback? onExitEditMode;

  @override
  State<WarpDpadTextField> createState() => _WarpDpadTextFieldState();
}

class _WarpDpadTextFieldState extends State<WarpDpadTextField> {
  Timer? _selectHoldTimer;
  bool _longSelectFired = false;

  @override
  void initState() {
    super.initState();
    widget.fieldFocusNode.addListener(_handleFieldFocusChanged);
  }

  @override
  void didUpdateWidget(WarpDpadTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fieldFocusNode != widget.fieldFocusNode) {
      oldWidget.fieldFocusNode.removeListener(_handleFieldFocusChanged);
      widget.fieldFocusNode.addListener(_handleFieldFocusChanged);
    }
  }

  @override
  void dispose() {
    _cancelSelectHold();
    widget.fieldFocusNode.removeListener(_handleFieldFocusChanged);
    super.dispose();
  }

  void _handleFieldFocusChanged() {
    if (!widget.fieldFocusNode.hasFocus) {
      // Opening the context menu legitimately moves focus away before the
      // select key is released. Preserve the fired flag so key-up cannot be
      // misclassified as a short Enter/Select submit.
      _cancelSelectHold(resetFired: false);
    }
    if (mounted) setState(() {});
  }

  void _enterEditMode() {
    widget.fieldFocusNode.requestFocus();
    if (!widget.moveCursorToEndOnEnter) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    });
  }

  void _leaveEditMode() {
    _cancelSelectHold();
    widget.wrapperFocusNode.requestFocus();
    widget.onExitEditMode?.call();
  }

  void _selectAll() {
    widget.fieldFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    });
  }

  void _showTextContextMenu() {
    if (!mounted) return;
    if (!widget.enableSelectAllContextMenu) return;
    showWarpContextMenu(
      context,
      restoreFocusNode: widget.fieldFocusNode,
      anchor: _caretAnchor(),
      items: [
        WarpContextMenuItem(
          label: 'Select All',
          icon: Icons.select_all,
          onSelected: _selectAll,
        ),
      ],
    );
  }

  Offset? _caretAnchor() {
    final focusContext = widget.fieldFocusNode.context;
    if (focusContext == null || !focusContext.mounted) return null;

    final editable = focusContext.findAncestorStateOfType<EditableTextState>();
    if (editable != null) {
      final value = editable.textEditingValue;
      final rawOffset = value.selection.isValid
          ? value.selection.extentOffset
          : value.text.length;
      final offset = rawOffset.clamp(0, value.text.length);
      final caretRect = editable.renderEditable.getLocalRectForCaret(
        TextPosition(offset: offset),
      );
      return editable.renderEditable.localToGlobal(
        Offset(caretRect.left, caretRect.bottom),
      );
    }

    final renderObject = focusContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
  }

  bool _isTextSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  KeyEventResult _handleTextKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      if (event is KeyDownEvent) _leaveEditMode();
      return KeyEventResult.handled;
    }

    if (!widget.enableSelectAllContextMenu || !_isTextSelectKey(key)) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      _longSelectFired = false;
      _selectHoldTimer?.cancel();
      _selectHoldTimer = Timer(DpadTheme.of(context).longSelectDuration, () {
        _longSelectFired = true;
        _showTextContextMenu();
      });
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      final fired = _longSelectFired;
      _cancelSelectHold();
      if (!fired &&
          (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter)) {
        widget.onSubmitted?.call(widget.controller.text);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _cancelSelectHold({bool resetFired = true}) {
    _selectHoldTimer?.cancel();
    _selectHoldTimer = null;
    if (resetFired) _longSelectFired = false;
  }

  void _handleDismissIntent() => _leaveEditMode();

  @override
  Widget build(BuildContext context) {
    final editing = widget.fieldFocusNode.hasFocus;
    final baseDecoration = widget.decoration ?? const InputDecoration();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _leaveEditMode,
        const SingleActivator(LogicalKeyboardKey.goBack): _leaveEditMode,
        const SingleActivator(LogicalKeyboardKey.browserBack): _leaveEditMode,
      },
      child: DpadFocusable(
        focusNode: widget.wrapperFocusNode,
        enabled:
            widget.enabled && (!editing || !widget.disableWrapperWhileEditing),
        autofocus: widget.autofocus,
        entry: widget.entry,
        autoScroll: widget.autoScroll,
        onSelect: _enterEditMode,
        onLongSelect: widget.enableSelectAllContextMenu
            ? _showTextContextMenu
            : null,
        onDirection: widget.onDirection,
        excludeChildFocus: false,
        builder: (context, state, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.tokens.radiusBtn),
            border: Border.all(
              color: state.focused ? WarpColors.accent : Colors.transparent,
              width: widget.tokens.focusRingWidth,
            ),
          ),
          child: child,
        ),
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                _handleDismissIntent();
                return null;
              },
            ),
          },
          child: Focus(
            onKeyEvent: _handleTextKey,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.fieldFocusNode,
              obscureText: widget.obscureText,
              style: widget.style,
              onSubmitted: widget.enableSelectAllContextMenu
                  ? null
                  : widget.onSubmitted,
              decoration: baseDecoration.copyWith(
                suffixIcon: widget.suffixIcon ?? baseDecoration.suffixIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
