import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warp_mediacenter_client/api/api_client.dart';
import 'package:warp_mediacenter_client/main.dart';
import 'package:warp_mediacenter_client/navigation/tab_bar_focus_registry.dart';
import 'package:warp_mediacenter_client/providers/catalog_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// End-to-end D-pad traversal against the real router, real tab bar, real
// MoviesPage and real dpad key handling — only the HTTP transport is faked.
//
// Written because three rounds of reasoning about this widget tree produced
// three wrong diagnoses. Reading where FocusManager actually lands after a
// real arrow key is the only account of this that cannot be argued with.
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _item(String title, int i) => {
  'id': '$title-$i',
  'title': '$title $i',
  'type': 'movie',
  'source_tag': 'tmdb',
  'year': 2020,
  'overview': 'Overview for $title $i',
  'poster_path': '/p$i.jpg',
  'backdrop_path': '/b$i.jpg',
  'tmdb_id': '${1000 + i}',
  'media': {
    'id': '$title-$i',
    'title': '$title $i',
    'name': '$title $i',
    'year': 2020,
    'overview': 'Overview for $title $i',
    'poster_path': '/p$i.jpg',
    'backdrop_path': '/b$i.jpg',
  },
};

/// Categories listed here return items; anything else returns an empty row,
/// which is how a row is made to "not exist" (see `_isRowVisible`).
///
/// Config row 0 is the pinned Continue Watching row, so a fixture that omits
/// `continue_watching` is modelling "no tracker installed yet" — row 0 prunes
/// and every later row moves up a slot.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.populated);

  Set<String> populated;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    Object payload;

    if (path.startsWith('/api/v1/catalog/')) {
      final category = path.split('/').last;
      final has = populated.contains(category);
      payload = {
        'category': category,
        'media_type': 'movie',
        'items': has ? [for (var i = 0; i < 5; i++) _item(category, i)] : [],
        'count': has ? 5 : 0,
      };
    } else {
      payload = {};
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
  late _FakeAdapter adapter;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, Set<String> populated) async {
    adapter = _FakeAdapter(populated);
    final client = ApiClient('http://test.local');
    client.dio.httpClientAdapter = adapter;

    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const WarpApp(),
      ),
    );
    // Let the catalog futures resolve and rows settle.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The exact node the app itself would navigate to for the Movies tab —
  /// asking the real registry, so a stale or missing entry fails here rather
  /// than being papered over by the test picking a node some other way.
  FocusNode moviesPill() {
    final node = container.read(tabBarFocusRegistryProvider).forRoute('/');
    expect(node, isNotNull, reason: 'Movies tab pill must be registered');
    return node!;
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    // One pump = one frame. Deliberately NOT pumpAndSettle: the whole class of
    // bug here is focus work that needs a frame nobody scheduled, and settling
    // would paper over it.
    // The focus chain is: key -> maybe animateToPage (320ms) -> post-frame ->
    // revealFirstCard -> endOfFrame -> requestFocus. Each hop needs a frame,
    // so drive several rather than assuming a fixed count.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Down from the Movies tab pill lands on row 0 card 0', (
    tester,
  ) async {
    await pumpApp(tester, {'continue_watching', 'trending_day', 'popular'});

    // Focus the Movies tab pill the way Up-from-row-0 would.
    final pill = moviesPill();
    expect(
      pill.context?.mounted,
      isTrue,
      reason: 'the registered pill must belong to a live element',
    );
    pill.requestFocus();
    await tester.pump();
    expect(_focusLabel(), 'TabPill-/');

    await press(tester, LogicalKeyboardKey.arrowDown);

    expect(
      _focusLabel(),
      'RibbonCard-r0-c0',
      reason: 'Down from the tab pill must land on the first row, first card',
    );
  });

  testWidgets('Up from row 1 returns to row 0 card 0', (tester) async {
    await pumpApp(tester, {'continue_watching', 'trending_day', 'popular'});

    moviesPill().requestFocus();
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusLabel(), 'RibbonCard-r0-c0');

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusLabel(), 'RibbonCard-r1-c0', reason: 'row 0 -> row 1');

    await press(tester, LogicalKeyboardKey.arrowUp);
    // The fake catalog carries no trailer, so the hero entry point is
    // More Info rather than Play Trailer (see _heroEntryFocusNode).
    expect(
      _focusLabel(),
      'MoreInfo-row1',
      reason: 'Up from a card enters its own row hero group first',
    );

    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(
      _focusLabel(),
      'RibbonCard-r0-c0',
      reason: 'Up from row 1 hero must reach row 0, deterministically',
    );
  });

  testWidgets(
    'a row that appears mid-session keeps Down and Up deterministic',
    (tester) async {
      // Continue Watching absent, exactly as before a tracker plugin is
      // installed: pinned config row 0 resolves empty and is pruned, so the
      // first *visible* row is config row 1.
      await pumpApp(tester, {'trending_day', 'popular'});

      moviesPill().requestFocus();
      await tester.pump();
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        _focusLabel(),
        'RibbonCard-r1-c0',
        reason: 'with row 0 pruned, Down lands on config row 1',
      );

      // Install the tracker: row 0 now has content and appears above
      // everything else, shifting every later row down one slot.
      adapter.populated = {'continue_watching', 'trending_day', 'popular'};
      container.invalidate(catalogDataProvider);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      moviesPill().requestFocus();
      await tester.pump();
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        _focusLabel(),
        'RibbonCard-r0-c0',
        reason: 'first press after the row appears must reach it, not a ghost',
      );

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusLabel(), 'RibbonCard-r1-c0');

      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(_focusLabel(), 'MoreInfo-row1');

      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(
        _focusLabel(),
        'RibbonCard-r0-c0',
        reason: 'Up into the newly-appeared row must work on the first press',
      );
    },
  );

  testWidgets('returning to the pill from row 0 leaves Down working in one press', (
    tester,
  ) async {
    await pumpApp(tester, {'continue_watching', 'trending_day', 'popular'});

    moviesPill().requestFocus();
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusLabel(), 'RibbonCard-r0-c0');

    // Card -> this row's hero group -> the tab pill. This is the round trip
    // that leaves Down needing a second press.
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(_focusLabel(), 'MoreInfo-row0');

    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(_focusLabel(), 'TabPill-/');

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(
      _focusLabel(),
      'RibbonCard-r0-c0',
      reason: 'one Down must be enough, exactly as on the first descent',
    );
  });
}
