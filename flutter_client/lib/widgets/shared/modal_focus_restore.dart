import 'package:flutter/material.dart';

mixin ModalFocusRestore<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  bool _appActive = true;
  FocusNode? _lastModalFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_rememberModalFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_rememberModalFocus);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (!_appActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final node = _lastModalFocus;
      if (mounted && node?.context != null) node?.requestFocus();
    });
  }

  void _rememberModalFocus() {
    if (!_appActive || !mounted) return;
    final node = FocusManager.instance.primaryFocus;
    final nodeContext = node?.context;
    if (node == null || node is FocusScopeNode || nodeContext == null) return;

    final modalBox = context.findRenderObject();
    final focusBox = nodeContext.findRenderObject();
    if (modalBox == null || focusBox == null) return;

    var current = focusBox.parent;
    while (current != null) {
      if (identical(current, modalBox)) {
        _lastModalFocus = node;
        return;
      }
      current = current.parent;
    }
  }
}
