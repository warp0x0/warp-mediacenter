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
// no way to wait for a freshly-appeared row's widget to actually mount, which
// is exactly the "lands on nothing, resolves on the second press" bug this
// was added to fix. A page instead registers an explicit onDown handler here,
// giving it the chance to run the same scroll-then-focus-with-retry path
// inter-row navigation already uses. Pages that don't need this (Search,
// Library, Settings, Power) simply don't register one, and Down falls through
// to the default spatial navigation exactly as it does today.
//
// App-global (one instance for the whole app, unlike RowFirstCardRegistry),
// since there is only ever one tab bar.
// ─────────────────────────────────────────────────────────────────────────────

class TabBarFocusRegistry {
  final _nodes = <String, FocusNode>{}; // keyed by route path, e.g. '/', '/shows', '/search'
  final _onDown = <String, bool Function()>{};

  void register(String route, FocusNode node) => _nodes[route] = node;

  void unregister(String route) => _nodes.remove(route);

  FocusNode? forRoute(String route) => _nodes[route];

  /// [handler] runs when Down is pressed while [route]'s tab pill has focus.
  /// Return true once the page has taken over placing focus itself (even if
  /// asynchronously); return false to fall through to default spatial nav.
  void registerOnDown(String route, bool Function() handler) =>
      _onDown[route] = handler;

  void unregisterOnDown(String route) => _onDown.remove(route);

  bool Function()? onDownFor(String route) => _onDown[route];
}

final tabBarFocusRegistryProvider =
    Provider<TabBarFocusRegistry>((ref) => TabBarFocusRegistry());
