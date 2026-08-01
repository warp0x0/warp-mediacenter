import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TabBarFocusRegistry — "Up -> my own tab", and the reverse: "Down -> my own
// content, robustly"
//
// Every top-level page needs Up-from-its-topmost-element to land on that
// page's own tab pill (Movies page -> Movies tab, Search -> Search tab,
// Settings -> Settings tab, Power -> Power tab). Generalized once here
// instead of special-cased per page: each _TabPill registers its real
// FocusNode keyed by its route, and any page can look up its own route's
// tab node and request focus on it.
//
// The reverse direction — Down from a tab pill into that page's content — is
// handled differently on purpose. A page whose row list can change size at
// runtime (Movies/Shows, once Continue Watching et al. can appear or vanish
// mid-session) can't rely on the raw dpad package's one-shot spatial guess:
// that guess is made against whatever happens to be built *right now*, with
// no way to wait for a freshly-appeared row's widget to actually mount. A
// page instead registers an explicit onDown handler here, giving it the
// chance to run the same scroll-then-focus-with-retry path inter-row
// navigation already uses. Pages that don't need this (Search, Library,
// Settings, Power) simply don't register one, and Down falls through to the
// default spatial navigation exactly as it does today.
//
// ── Why removal is identity-checked ──────────────────────────────────────────
//
// Flutter mounts a replacement element *before* unmounting the one it
// replaces, so during a rebuild the order is: new State.initState (registers
// itself) -> old State.dispose (removes the entry for its route). A plain
// `remove(route)` in the old instance therefore deletes the *new* instance's
// registration, leaving the route with no entry at all — Down/Up then find
// nothing and the key press looks swallowed.
//
// Both removals take the exact object that was registered and drop the entry
// only if it is still that object, so a late-disposing predecessor cannot
// clobber its successor. That is why removal takes an argument that otherwise
// looks redundant.
//
// Callers must also capture this registry in a field rather than reaching for
// `ref.read` inside dispose(): Riverpod throws on `ref` once a widget is
// being unmounted, and that throw aborts dispose() before the removal ever
// runs, which is how dead nodes and dead handlers accumulated here in the
// first place.
// ─────────────────────────────────────────────────────────────────────────────

typedef TabDownHandler = bool Function();

class TabBarFocusRegistry {
  final _nodes = <String, FocusNode>{}; // keyed by route path, e.g. '/', '/shows'
  final _onDown = <String, TabDownHandler>{};

  void register(String route, FocusNode node) => _nodes[route] = node;

  /// Drops [route]'s node only if it is still [node] — see the identity note
  /// in this file's header.
  void unregister(String route, FocusNode node) {
    if (identical(_nodes[route], node)) _nodes.remove(route);
  }

  FocusNode? forRoute(String route) => _nodes[route];

  /// [handler] runs when Down is pressed while [route]'s tab pill has focus.
  /// Return true once the page has taken over placing focus itself (even if
  /// asynchronously); return false to fall through to default spatial nav.
  void registerOnDown(String route, TabDownHandler handler) =>
      _onDown[route] = handler;

  /// Drops [route]'s handler only if it is still [handler].
  void unregisterOnDown(String route, TabDownHandler handler) {
    if (identical(_onDown[route], handler)) _onDown.remove(route);
  }

  TabDownHandler? onDownFor(String route) => _onDown[route];
}

final tabBarFocusRegistryProvider = Provider<TabBarFocusRegistry>(
  (ref) => TabBarFocusRegistry(),
);
