import 'package:flutter/widgets.dart';

/// Owns a variable-length list of [FocusNode]s and keeps disposal centralized.
class FocusNodeList {
  final List<FocusNode> _nodes = [];

  List<FocusNode> get nodes => List.unmodifiable(_nodes);

  FocusNode? at(int index) {
    if (index < 0 || index >= _nodes.length) return null;
    return _nodes[index];
  }

  void sync(int length, {String debugPrefix = 'FocusNode'}) {
    while (_nodes.length > length) {
      _nodes.removeLast().dispose();
    }
    while (_nodes.length < length) {
      _nodes.add(FocusNode(debugLabel: '$debugPrefix-${_nodes.length}'));
    }
  }

  void clear() {
    for (final node in _nodes) {
      node.dispose();
    }
    _nodes.clear();
  }
}
