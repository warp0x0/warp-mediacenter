import 'package:flutter/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RowFirstCardRegistry — cross-row Down-chaining
//
// One FocusNode per row index: the row's first card. Used both for
// cross-row Down navigation (any card in row N -> row N+1's first card,
// and the reverse for Up from a row's hero/entry group) and for each
// screen's initial autofocus.
//
// Deliberately minimal — unlike the old NavRowRegistry, it does not track
// column position, since every vertical jump lands on one deterministic
// target (never a computed column), and left/right within a row is left to
// dpad's own beam traversal.
//
// Owned as a plain field by each page (MoviesPage, ShowsPage, SearchPage
// each create their own instance and pass it down explicitly), rather than
// as a Riverpod provider — row indices are page-local, and a page-owned
// plain field avoids ProviderScope-override/ambient-ref scoping pitfalls.
// ─────────────────────────────────────────────────────────────────────────────

class RowFirstCardRegistry {
  final _entries = <int, RowFirstCardEntry>{};

  void register(
    int rowIndex,
    FocusNode node, {
    Future<void> Function()? revealFirstCard,
  }) => _entries[rowIndex] = RowFirstCardEntry(
    node: node,
    revealFirstCard: revealFirstCard,
  );

  void unregister(int rowIndex) => _entries.remove(rowIndex);

  FocusNode? entryFor(int rowIndex) => _entries[rowIndex]?.node;

  Future<void> revealFirstCard(int rowIndex) async {
    await _entries[rowIndex]?.revealFirstCard?.call();
  }
}

class RowFirstCardEntry {
  final FocusNode node;
  final Future<void> Function()? revealFirstCard;

  const RowFirstCardEntry({required this.node, this.revealFirstCard});
}
