import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/warp_theme.dart';
import '../../theme/warp_tokens.dart';

class WarpContextMenuItem {
  const WarpContextMenuItem({
    required this.label,
    required this.onSelected,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onSelected;
  final bool destructive;
}

Future<void> showWarpContextMenu(
  BuildContext context, {
  required List<WarpContextMenuItem> items,
  FocusNode? restoreFocusNode,
  Offset? anchor,
}) async {
  if (items.isEmpty) return;
  final focusToRestore = restoreFocusNode ?? FocusManager.instance.primaryFocus;
  final resolvedAnchor = anchor ?? _anchorForFocusNode(focusToRestore);

  await showGeneralDialog<void>(
    context: context,
    barrierLabel: 'Context menu',
    barrierDismissible: true,
    barrierColor: Colors.black.withAlpha(90),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (dialogContext, _, _) =>
        _WarpContextMenuOverlay(items: items, anchor: resolvedAnchor),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (focusToRestore?.context != null) focusToRestore?.requestFocus();
  });
}

Offset? _anchorForFocusNode(FocusNode? node) {
  final context = node?.context;
  if (context == null || !context.mounted) return null;
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
}

class _WarpContextMenuOverlay extends StatefulWidget {
  const _WarpContextMenuOverlay({required this.items, required this.anchor});

  final List<WarpContextMenuItem> items;
  final Offset? anchor;

  @override
  State<_WarpContextMenuOverlay> createState() =>
      _WarpContextMenuOverlayState();
}

class _WarpContextMenuOverlayState extends State<_WarpContextMenuOverlay> {
  final _sentinelFocus = FocusNode(debugLabel: 'ContextMenuSentinel');
  late final List<FocusNode> _itemFocusNodes;

  @override
  void initState() {
    super.initState();
    _itemFocusNodes = List.generate(
      widget.items.length,
      (i) => FocusNode(debugLabel: 'ContextMenuItem-$i'),
    );
  }

  @override
  void dispose() {
    _sentinelFocus.dispose();
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  bool _sentinelDirection(TraversalDirection direction) {
    if (_itemFocusNodes.isEmpty) return true;
    if (direction == TraversalDirection.down ||
        direction == TraversalDirection.right) {
      Dpad.of(context).requestFocus(_itemFocusNodes.first);
      return true;
    }
    if (direction == TraversalDirection.up ||
        direction == TraversalDirection.left) {
      Dpad.of(context).requestFocus(_itemFocusNodes.last);
      return true;
    }
    return true;
  }

  void _select(WarpContextMenuItem item) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => item.onSelected());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final tokens = WarpTokens(UiDensity.desktop, size);
    const menuWidth = 220.0;
    final estimatedHeight = (widget.items.length * 44.0 + 18).clamp(
      72.0,
      320.0,
    );
    final anchor = widget.anchor ?? size.center(Offset.zero);
    final left = (anchor.dx - 12).clamp(16.0, size.width - menuWidth - 16);
    final top = (anchor.dy + 12).clamp(
      16.0,
      size.height - estimatedHeight - 16,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.goBack): _close,
        const SingleActivator(LogicalKeyboardKey.browserBack): _close,
      },
      child: DpadRegion(
        memoryKey: 'warp-context-menu-$hashCode',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: menuWidth,
                  child: GestureDetector(
                    onTap: () {},
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xF20C0C12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(28)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 30,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 1,
                              height: 1,
                              child: DpadFocusable(
                                effects: const [],
                                focusNode: _sentinelFocus,
                                autofocus: true,
                                entry: true,
                                onDirection: _sentinelDirection,
                                onSelect: () {},
                                child: const SizedBox.shrink(),
                              ),
                            ),
                            for (var i = 0; i < widget.items.length; i++)
                              _ContextMenuRow(
                                item: widget.items[i],
                                focusNode: _itemFocusNodes[i],
                                tokens: tokens,
                                onSelect: () => _select(widget.items[i]),
                              ),
                          ],
                        ),
                      ),
                    ),
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

class _ContextMenuRow extends StatefulWidget {
  const _ContextMenuRow({
    required this.item,
    required this.focusNode,
    required this.tokens,
    required this.onSelect,
  });

  final WarpContextMenuItem item;
  final FocusNode focusNode;
  final WarpTokens tokens;
  final VoidCallback onSelect;

  @override
  State<_ContextMenuRow> createState() => _ContextMenuRowState();
}

class _ContextMenuRowState extends State<_ContextMenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.item.destructive ? Colors.redAccent : Colors.white;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onSelect: widget.onSelect,
        tapToSelect: false,
        builder: (context, state, child) {
          final active = state.focused || _hovered;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onSelect,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: active ? Colors.white.withAlpha(24) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.focused ? WarpColors.accent : Colors.transparent,
                  width: widget.tokens.focusRingWidth,
                ),
              ),
              child: Row(
                children: [
                  if (widget.item.icon != null) ...[
                    Icon(
                      widget.item.icon,
                      color: color.withAlpha(210),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: TextStyle(
                        color: color.withAlpha(220),
                        fontSize: widget.tokens.fontSubtitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}
