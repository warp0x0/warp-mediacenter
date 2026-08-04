import 'package:flutter/widgets.dart';

/// Directional traversal over a page described as rows of focus keys.
///
/// The pattern this generalises comes from the plugin settings pages: one
/// function produces both the render order and the traversal grid, so the two
/// can never drift. That property is what makes a *dynamic* section navigable —
/// when the rows come from a plugin's schema, or from however many catalog rows
/// the user has added, nothing about traversal can be hardcoded.
///
/// Hoisting it here means any future section (Provider plugins, Skins) gets
/// working D-pad navigation by supplying a rows function and nothing else.
///
/// Behaviour:
///
/// * **Up/Down** move between rows, scanning outward for the first *mounted*
///   node. Scanning matters: a row may be present in the model but not yet laid
///   out (a schema field still loading, a list item scrolled far out of view),
///   and stopping at an unmounted node would strand focus.
/// * **Left/Right** move along the current row first — which only matters where
///   several controls share a line — then leave the region via [onFocusLeft] /
///   [onFocusRight].
/// * A key **absent from the grid** keeps only the edge behaviour. Text fields
///   register an inner node the grid does not list, and it must still be able to
///   escape sideways.
///
/// Returns `true` when the keypress was handled, matching `DpadDirectionCallback`.
bool resolveGridDirection({
  required List<List<String>> rows,
  required String key,
  required TraversalDirection direction,
  required FocusNode Function(String key) focusFor,
  required bool Function(FocusNode node) focusMounted,
  required bool Function() onFocusLeft,
  required bool Function() onFocusRight,
}) {
  var row = -1;
  var col = -1;
  for (var i = 0; i < rows.length && row < 0; i++) {
    final j = rows[i].indexOf(key);
    if (j >= 0) {
      row = i;
      col = j;
    }
  }

  if (row < 0) {
    if (direction == TraversalDirection.left) return onFocusLeft();
    if (direction == TraversalDirection.right) return onFocusRight();
    return false;
  }

  bool focusRowFrom(int start, int step) {
    for (var i = start; i >= 0 && i < rows.length; i += step) {
      for (final candidate in rows[i]) {
        if (focusMounted(focusFor(candidate))) return true;
      }
    }
    return false;
  }

  switch (direction) {
    case TraversalDirection.up:
      return focusRowFrom(row - 1, -1);
    case TraversalDirection.down:
      return focusRowFrom(row + 1, 1);
    case TraversalDirection.left:
      for (var j = col - 1; j >= 0; j--) {
        if (focusMounted(focusFor(rows[row][j]))) return true;
      }
      return onFocusLeft();
    case TraversalDirection.right:
      for (var j = col + 1; j < rows[row].length; j++) {
        if (focusMounted(focusFor(rows[row][j]))) return true;
      }
      return onFocusRight();
  }
}
