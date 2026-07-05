import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TabBarFocusRegistry — "Up -> my own tab" pattern
//
// Every top-level page needs Up-from-its-topmost-element to land on that
// page's own tab pill (Movies page -> Movies tab, Search -> Search tab,
// Settings -> Settings tab, Power -> Power tab). Generalized once here
// instead of special-cased per page: each _TabPill registers its real
// FocusNode keyed by its route, and any page can look up its own route's
// tab node and request focus on it.
//
// App-global (one instance for the whole app, unlike RowFirstCardRegistry),
// since there is only ever one tab bar.
// ─────────────────────────────────────────────────────────────────────────────

class TabBarFocusRegistry {
  final _nodes = <String, FocusNode>{}; // keyed by route path, e.g. '/', '/shows', '/search'

  void register(String route, FocusNode node) => _nodes[route] = node;

  void unregister(String route) => _nodes.remove(route);

  FocusNode? forRoute(String route) => _nodes[route];
}

final tabBarFocusRegistryProvider =
    Provider<TabBarFocusRegistry>((ref) => TabBarFocusRegistry());
