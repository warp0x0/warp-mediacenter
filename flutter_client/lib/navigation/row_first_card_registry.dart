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
    VoidCallback? republishBackdrop,
  }) => _entries[rowIndex] = RowFirstCardEntry(
    node: node,
    revealFirstCard: revealFirstCard,
    republishBackdrop: republishBackdrop,
  );

  /// Drops [rowIndex]'s entry only if it is still [node]'s.
  ///
  /// Flutter mounts a replacement element before unmounting the one it
  /// replaces, and a row that shifts position re-registers under its new
  /// index — so an unconditional remove here lets a late-disposing row delete
  /// the entry a *different*, live row already claimed for that index. The
  /// slot then reads as empty and cross-row navigation lands nowhere.
  void unregister(int rowIndex, FocusNode node) {
    if (identical(_entries[rowIndex]?.node, node)) _entries.remove(rowIndex);
  }

  /// Unconditional removal, regardless of who owns the slot.
  ///
  /// Only for callers that do not track which node they registered (the
  /// Library and Search row widgets). They carry the same clobber hazard
  /// [unregister] exists to prevent, but neither is part of the tab-bar /
  /// Movies / Shows traversal this was written to fix, so they keep their
  /// existing behaviour rather than being changed blind.
  void clear(int rowIndex) => _entries.remove(rowIndex);

  FocusNode? entryFor(int rowIndex) => _entries[rowIndex]?.node;

  Future<void> revealFirstCard(int rowIndex) async {
    await _entries[rowIndex]?.revealFirstCard?.call();
  }

  void republishBackdrop(int rowIndex) {
    _entries[rowIndex]?.republishBackdrop?.call();
  }
}

class RowFirstCardEntry {
  final FocusNode node;
  final Future<void> Function()? revealFirstCard;
  final VoidCallback? republishBackdrop;

  const RowFirstCardEntry({
    required this.node,
    this.revealFirstCard,
    this.republishBackdrop,
  });
}
