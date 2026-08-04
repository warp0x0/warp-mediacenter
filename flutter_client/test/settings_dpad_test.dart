import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warp_mediacenter_client/api/api_client.dart';
import 'package:warp_mediacenter_client/main.dart';

// ─────────────────────────────────────────────────────────────────────────────
// D-pad traversal on the Settings page, driven by real arrow keys against the
// real router, sidebar and Catalog panel — only the HTTP transport is faked.
//
// The Catalog panel's rows are variable-length and its sidebar gains a section
// per installed plugin, so both its focus-key set and its traversal grid are now
// computed rather than written out. That is exactly the kind of thing that is
// easy to reason about incorrectly: `_reapFocusNodes` disposes any node whose
// key is not in the live set, so a rows model that disagrees with the widget
// tree by one entry produces a control the remote simply cannot reach — and it
// looks fine on screen.
//
// Reading where FocusManager actually lands after a real keypress is the only
// account of that which cannot be argued with.
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _list(
  String id,
  String title, {
  String group = 'standard',
  List<String> mediaTypes = const ['movie', 'show'],
}) => {
  'id': id,
  'title': title,
  'media_types': mediaTypes,
  'group': group,
  'supports_pagination': true,
  'page_size': 20,
};

Map<String, dynamic> _widget(String category, String title) => {
  'source': 'tmdb',
  'provider': 'tmdb',
  'category': category,
  'title': title,
};

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.widgetCount, required this.withPlugin});

  int widgetCount;
  bool withPlugin;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    Object payload = <String, dynamic>{};

    if (path == '/api/v1/settings/widgets') {
      final rows = [
        {
          'source': 'warp',
          'provider': 'warp',
          'category': 'continue_watching',
          'title': 'Continue Watching',
        },
        for (var i = 1; i < widgetCount; i++) _widget('list_$i', 'List $i'),
      ];
      payload = {
        'movies': rows,
        'shows': rows,
        'min_widgets': 1,
        'max_widgets': 10,
      };
    } else if (path == '/api/v1/catalog/definitions') {
      payload = {
        'sources': [
          {
            'id': 'tmdb',
            'label': 'TMDb',
            'kind': 'builtin',
            'lists': [
              _list('list_0', 'List 0'),
              _list('list_1', 'List 1'),
              _list('genre_27', 'Horror', group: 'genre'),
            ],
          },
          if (withPlugin)
            {
              'id': 'simkl-catalog',
              'label': 'Simkl Catalogs',
              'kind': 'plugin',
              'icon': 'grid_view_outlined',
              'lists': [_list('trending_week', 'Trending This Week')],
            },
        ],
      };
    } else if (path == '/api/v1/plugins/categories') {
      payload = {
        'categories': [
          {
            'id': 'catalog',
            'label': 'Catalogs',
            'description': 'Browse rows',
            'exclusive': false,
            'active_plugin_id': null,
            'installed': withPlugin
                ? [
                    {
                      'plugin_id': 'simkl-catalog',
                      'category': 'catalog',
                      'name': 'Simkl Catalogs',
                      'version': '1.0.0',
                      'enabled': true,
                      'exclusive': false,
                      'has_settings': true,
                      'auth_kind': 'none',
                      'icon': 'grid_view_outlined',
                      'description': 'Simkl lists',
                      'capabilities': ['catalog.lists', 'catalog.fetch'],
                      'auth': {'required': false, 'connected': true},
                    },
                  ]
                : <Map<String, dynamic>>[],
          },
        ],
      };
    } else if (path.startsWith('/api/v1/catalog/')) {
      payload = {
        'category': 'x',
        'media_type': 'movie',
        'items': [],
        'count': 0,
        'has_more': false,
      };
    }

    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String? _focusLabel() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  late ProviderContainer container;

  Future<void> pumpSettings(
    WidgetTester tester, {
    int widgetCount = 6,
    bool withPlugin = false,
  }) async {
    final client = ApiClient('http://test.local');
    client.dio.httpClientAdapter = _FakeAdapter(
      widgetCount: widgetCount,
      withPlugin: withPlugin,
    );

    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WarpApp()),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Navigate to Settings the way the app does, then let its futures resolve.
    final settingsTab = find.text('Settings');
    expect(settingsTab, findsWidgets, reason: 'Settings tab must exist');
    await tester.tap(settingsTab.first, warnIfMissed: false);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    // One pump = one frame. Deliberately NOT pumpAndSettle: the bug class here
    // is focus work needing a frame nobody scheduled, and settling hides it.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Focus a settings control by its pool key, the way the page itself would.
  ///
  /// Goes through the real widget tree rather than the pool, so a key that the
  /// panel never rendered fails here instead of silently focusing a detached
  /// node.
  bool focusByLabel(String key) {
    FocusNode? found;
    void visit(FocusNode node) {
      if (node.debugLabel == 'Settings/$key') found ??= node;
      for (final child in node.children) {
        visit(child);
      }
    }

    visit(FocusManager.instance.rootScope);
    found?.requestFocus();
    return found != null;
  }

  /// Select a sidebar section, the way pressing Select on it does.
  ///
  /// Focusing the entry is not enough: the sidebar always renders every
  /// section, but only the *selected* one's content is built — and the content
  /// nodes are what traversal into the panel resolves against.
  Future<void> openSection(WidgetTester tester, String id) async {
    expect(
      focusByLabel('sidebar:$id'),
      isTrue,
      reason: 'the $id sidebar entry must be rendered',
    );
    await tester.pump();
    await press(tester, LogicalKeyboardKey.enter);
  }

  testWidgets('sidebar reaches the Catalog section and enters it', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openSection(tester, 'catalog');

    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(
      _focusLabel(),
      'Settings/catalog:movies',
      reason: 'Right from the sidebar enters the panel at its first control',
    );
  });

  testWidgets('Down walks every configured catalog row', (tester) async {
    await pumpSettings(tester, widgetCount: 6);
    await openSection(tester, 'catalog');

    expect(focusByLabel('catalog:movies'), isTrue);
    await tester.pump();

    // Toggle row -> the first *configurable* row. Row 0 is the pinned
    // Continue Watching row: it has no controls, so the D-pad steps over it.
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(
      _focusLabel(),
      'Settings/catalog:configure:1',
      reason: 'Down from the media toggle must skip the pinned row',
    );

    // Then one row per configurable widget.
    for (var i = 2; i < 6; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        _focusLabel(),
        'Settings/catalog:configure:$i',
        reason: 'Down from row ${i - 1} must reach row $i',
      );
    }

    // Past the last row: Add Row, then the Save/Refresh action row.
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusLabel(), 'Settings/catalog:addRow');

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusLabel(), 'Settings/catalog:save');

    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusLabel(), 'Settings/catalog:refresh');
  });

  testWidgets('a row exposes Remove to its right', (tester) async {
    await pumpSettings(tester, widgetCount: 6);
    await openSection(tester, 'catalog');

    expect(focusByLabel('catalog:configure:2'), isTrue);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(
      _focusLabel(),
      'Settings/catalog:remove:2',
      reason: 'Right from Configure reaches that row\'s Remove control',
    );

    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focusLabel(), 'Settings/catalog:configure:2');
  });

  testWidgets('Add Row extends the traversal grid', (tester) async {
    await pumpSettings(tester, widgetCount: 6);
    await openSection(tester, 'catalog');

    expect(focusByLabel('catalog:addRow'), isTrue);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.enter);

    // The new row must be reachable — this is the assertion that would fail if
    // `_catalogRows` and the widget tree disagreed about the row count.
    expect(focusByLabel('catalog:configure:6'), isTrue);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(
      _focusLabel(),
      'Settings/catalog:addRow',
      reason: 'the seventh row is still below the cap, so Add Row remains',
    );
  });

  testWidgets('Remove leaves focus on a live node', (tester) async {
    await pumpSettings(tester, widgetCount: 6);
    await openSection(tester, 'catalog');

    expect(focusByLabel('catalog:remove:5'), isTrue);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.enter);

    // The removed row's nodes get reaped; focus must have moved somewhere real.
    final label = _focusLabel();
    expect(label, isNotNull);
    expect(
      label,
      anyOf('Settings/catalog:configure:4', 'Settings/catalog:save'),
      reason: 'focus must land on a row that still exists',
    );
    expect(
      FocusManager.instance.primaryFocus?.context,
      isNotNull,
      reason: 'the focused node must still be mounted',
    );
  });

  testWidgets('the pinned Continue Watching row exposes no controls', (
    tester,
  ) async {
    await pumpSettings(tester, widgetCount: 6);
    await openSection(tester, 'catalog');

    expect(
      focusByLabel('catalog:configure:0'),
      isFalse,
      reason: 'the pinned row must have no Configure control',
    );
    expect(
      focusByLabel('catalog:remove:0'),
      isFalse,
      reason: 'the pinned row must have no Remove control',
    );
    // ...and it is still on screen, just not actionable.
    expect(find.text('Continue Watching'), findsWidgets);
  });

  testWidgets('saved row titles render without needing a Save first', (
    tester,
  ) async {
    await pumpSettings(tester, widgetCount: 6);
    await openSection(tester, 'catalog');

    // The server's rows are `List 1..5`; the built-in defaults are named
    // differently ("Trending Today" etc). Seeing the server's names means the
    // draft was adopted in the frame the config arrived, not a frame later.
    expect(
      find.text('List 1'),
      findsOneWidget,
      reason: 'the panel must show the saved configuration immediately',
    );
    expect(find.text('Trending Today'), findsNothing);
  });

  testWidgets('an installed catalog plugin gets its own sidebar section', (
    tester,
  ) async {
    await pumpSettings(tester, withPlugin: true);

    expect(
      focusByLabel('sidebar:plugin:simkl-catalog'),
      isTrue,
      reason:
          'a catalog plugin declaring settings must appear in the sidebar '
          'with no client-side change',
    );
  });
}
