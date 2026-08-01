import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/catalog_constants.dart';
import '../models/catalog.dart';
import '../providers/catalog_provider.dart';
import '../providers/detail_provider.dart';
import '../navigation/row_first_card_registry.dart';
import '../navigation/tab_bar_focus_registry.dart';
import '../widgets/media/widget_section.dart';

/// One configured row plus its currently-resolved catalog state.
///
/// [configIndex] is the row's position in [_ShowsPageState._widgets] — stable
/// for the whole session regardless of which rows turn out empty. It's what
/// keys each [WidgetSection] (so a row keeps its state — scroll offset,
/// selection — across a reflow), which is deliberately decoupled from its
/// position in the *visible* list (passed down as `rowIndex`), which shifts
/// whenever an earlier row is pruned.
class _RowSlot {
  final int configIndex;
  final WidgetConfig config;
  final AsyncValue<CatalogResponse> async;
  const _RowSlot({
    required this.configIndex,
    required this.config,
    required this.async,
  });
}

class ShowsPage extends ConsumerStatefulWidget {
  const ShowsPage({super.key});

  @override
  ConsumerState<ShowsPage> createState() => _ShowsPageState();
}

class _ShowsPageState extends ConsumerState<ShowsPage> with RouteAware {
  static const _rowSnapDuration = Duration(milliseconds: 320);

  final _pageCtrl = PageController();
  // Page-local registry — Movies/Shows/Search each own their own instance so
  // row indices (0, 1, 2, ...) never collide across pages.
  final _rowRegistry = RowFirstCardRegistry();
  List<WidgetConfig> _widgets = kDefaultShowWidgets;
  // Rows whose catalog is non-empty, or hasn't resolved yet (kept
  // provisionally visible until we know) — recomputed every build. This is
  // the PageView's actual item list: a row resolved empty or errored is
  // excluded outright, not rendered-and-hidden.
  List<_RowSlot> _visibleRows = const [];
  bool _snapping = false;
  double _trackpadAccum = 0.0;
  int? _pendingDpadFocusRow;
  // Runs once per mount (or per config reload): kicks off the "focus the
  // first available row" flow and lets its own registry-retry mechanism wait
  // for whichever row actually lands first.
  bool _initialFocusAttempted = false;
  // Runs once we're sure there's nothing to show at all.
  bool _focusedTabWhenEmpty = false;
  // Stable identity (configIndex) of whichever row the page is currently
  // showing/focused on — used to keep the PageView pinned to the same row
  // when an earlier row's pruning shifts everyone else's visible position.
  int? _currentConfigIndex;

  static const _ownRoute = '/shows';

  @override
  void initState() {
    super.initState();
    ref.read(widgetsConfigProvider).whenData((cfg) {
      _widgets = cfg.shows;
    });
    // Down from this page's own tab pill routes through the same robust
    // scroll-then-focus-with-retry path row-to-row navigation uses, rather
    // than the raw dpad package's one-shot spatial guess — see
    // TabBarFocusRegistry's doc comment for why that guess isn't enough once
    // rows can appear/vanish mid-session.
    ref.read(tabBarFocusRegistryProvider).registerOnDown(_ownRoute, () {
      if (_visibleRows.isEmpty) return false;
      unawaited(_focusRowByDpad(0));
      return true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    ref.read(tabBarFocusRegistryProvider).unregisterOnDown(_ownRoute);
    routeObserver.unsubscribe(this);
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _republishVisibleBackdrop();
  }

  void _republishVisibleBackdrop() {
    final rowIndex = _pageCtrl.hasClients
        ? (_pageCtrl.page?.round() ?? _pageCtrl.initialPage)
        : _pageCtrl.initialPage;
    _rowRegistry.republishBackdrop(rowIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rowRegistry.republishBackdrop(rowIndex);
    });
  }

  bool _isRowVisible(AsyncValue<CatalogResponse> async) {
    if (async.hasError) return false;
    final items = async.asData?.value.items;
    if (items != null) return items.isNotEmpty;
    return true; // still loading — keep its slot until we know either way
  }

  // If the row the page is currently showing/focused on shifted position (an
  // earlier row was pruned or reappeared), jump the PageView to keep it on
  // screen instead of silently displaying whatever now occupies the old
  // numeric offset. A jump, not an animation — this corrects a passive
  // reflow, it isn't a navigation the user asked for.
  //
  // Must defer to any navigation already in flight (_snapping, or a pending
  // dpad-driven focus target): _focusRowByDpad/_snapTo already know exactly
  // where the page needs to end up and are actively animating there. Letting
  // this fire concurrently — which happens whenever a row's async resolves
  // (a passive rebuild) at the same moment the user is mid-navigation — pits
  // two independent PageController writers against each other. That race is
  // exactly what produced "the first Up/Down press lands on nothing, the
  // second one reaches the right row": this jump could land the PageView back
  // on the row being left just as the other path's post-frame retry checks
  // what's actually built there.
  void _correctPageControllerDrift() {
    if (_currentConfigIndex == null) return;
    if (_snapping || _pendingDpadFocusRow != null) return;
    final newIndex = _visibleRows.indexWhere(
      (r) => r.configIndex == _currentConfigIndex,
    );
    if (newIndex < 0) {
      // The row we were on just vanished entirely — let the initial-focus
      // flow pick a fresh target instead of leaving the page pointed at a gap.
      _currentConfigIndex = null;
      _initialFocusAttempted = false;
      return;
    }
    if (!_pageCtrl.hasClients) return;
    final currentPage = _pageCtrl.page?.round() ?? _pageCtrl.initialPage;
    if (currentPage == newIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageCtrl.hasClients) _pageCtrl.jumpToPage(newIndex);
    });
  }

  void _snapTo(double dy) {
    if (_snapping) return;
    if (dy.abs() < 2) return;
    if (!_pageCtrl.hasClients) return;
    final page = _pageCtrl.page?.round() ?? 0;
    final maxPage = _visibleRows.length - 1;
    if (maxPage < 0) return;
    final target = dy > 0
        ? (page + 1).clamp(0, maxPage)
        : (page - 1).clamp(0, maxPage);
    if (target == page) return;
    _snapping = true;
    _currentConfigIndex = _visibleRows[target].configIndex;
    _pageCtrl
        .animateToPage(
          target,
          duration: _rowSnapDuration,
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted) return;
          _snapping = false;
          _trackpadAccum = 0.0;
          _focusRowFirstCard(target);
        });
  }

  Future<bool> _focusRowFirstCard(int rowIndex) async {
    await _rowRegistry.revealFirstCard(rowIndex);
    if (!mounted) return false;
    final node = _rowRegistry.entryFor(rowIndex);
    if (node == null) return false;
    return Dpad.of(context).requestFocus(node);
  }

  void _onFirstCardRegistered(int rowIndex) {
    if (_pendingDpadFocusRow != rowIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _pendingDpadFocusRow != rowIndex) return;
      if (await _focusRowFirstCard(rowIndex)) _pendingDpadFocusRow = null;
    });
  }

  void _focusTabBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || GoRouterState.of(context).uri.path != '/shows') return;
      final tab = ref.read(tabBarFocusRegistryProvider).forRoute('/shows');
      if (tab != null) Dpad.of(context).requestFocus(tab);
    });
  }

  // rowIndex here is a position in the *visible* row list. Retries via
  // RowFirstCardRegistry's onFirstCardRegistered callback until that slot's
  // row actually registers a real card — which naturally handles "the row
  // we're waiting on is still loading" and "the row we were waiting on got
  // pruned and a different one now occupies that slot" the same way.
  Future<void> _focusRowByDpad(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= _visibleRows.length) return;
    _pendingDpadFocusRow = rowIndex;
    _currentConfigIndex = _visibleRows[rowIndex].configIndex;
    if (_pageCtrl.hasClients) {
      final page = _pageCtrl.page?.round() ?? _pageCtrl.initialPage;
      if (page != rowIndex) {
        _snapping = true;
        await _pageCtrl.animateToPage(
          rowIndex,
          duration: _rowSnapDuration,
          curve: Curves.easeOutCubic,
        );
        if (!mounted) return;
        _snapping = false;
        _trackpadAccum = 0.0;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _pendingDpadFocusRow != rowIndex) return;
      if (await _focusRowFirstCard(rowIndex)) _pendingDpadFocusRow = null;
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      _snapTo(event.scrollDelta.dy);
    });
  }

  void _onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    _trackpadAccum = 0.0;
  }

  void _onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (_snapping) return;
    _trackpadAccum += event.panDelta.dy;
    if (_trackpadAccum.abs() < 50) return;
    final dy = _trackpadAccum;
    _trackpadAccum = 0.0;
    _snapTo(dy);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(widgetsConfigProvider, (_, next) {
      next.whenData((cfg) {
        if (!mounted) return;
        setState(() {
          _widgets = cfg.shows;
          // The configured row set changed — every stable identity below is
          // now meaningless; start the placement flow over.
          _initialFocusAttempted = false;
          _focusedTabWhenEmpty = false;
          _pendingDpadFocusRow = null;
          _currentConfigIndex = null;
        });
      });
    });

    // Invalidate all catalog rows when playback ends so "Continue Watching" refreshes
    ref.listen(playbackEndedProvider, (_, n) {
      ref.invalidate(catalogDataProvider);
    });

    final rowAsyncs = <AsyncValue<CatalogResponse>>[
      for (final w in _widgets)
        ref.watch(
          catalogDataProvider(
            provider: w.provider,
            category: w.category,
            mediaType: 'show',
          ),
        ),
    ];

    _visibleRows = [
      for (var i = 0; i < _widgets.length; i++)
        if (_isRowVisible(rowAsyncs[i]))
          _RowSlot(configIndex: i, config: _widgets[i], async: rowAsyncs[i]),
    ];

    final allSettled = rowAsyncs.every((a) => a.hasValue || a.hasError);

    _correctPageControllerDrift();

    if (!_initialFocusAttempted) {
      _initialFocusAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusRowByDpad(0);
      });
    }

    // Every row has settled and none of them have anything to show — give up
    // waiting on a row that will never register, and land focus on this
    // page's own tab pill instead. With zero rows in the PageView there is
    // nothing below it to navigate into, so Down from there is naturally a
    // no-op rather than needing special-case handling.
    if (allSettled && _visibleRows.isEmpty && !_focusedTabWhenEmpty) {
      _focusedTabWhenEmpty = true;
      _pendingDpadFocusRow = null;
      _focusTabBar();
    }

    return Listener(
      onPointerSignal: _onPointerSignal,
      onPointerPanZoomStart: _onPointerPanZoomStart,
      onPointerPanZoomUpdate: _onPointerPanZoomUpdate,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: PageView.builder(
          controller: _pageCtrl,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _visibleRows.length,
          // Without this, SliverChildBuilderDelegate diffs children purely by
          // position: when an earlier row is inserted/pruned and every later
          // row's index shifts, the row that used to live at index N is torn
          // down and rebuilt from scratch at its new index — including its
          // FocusNodes, so a reflow while the user is focused inside that row
          // silently kills the very FocusNode that has focus. This callback
          // lets the Sliver match a row's ValueKey to its new index instead,
          // so Flutter moves the existing Element (and calls didUpdateWidget,
          // which WidgetSection already handles) rather than recreating it.
          findChildIndexCallback: (Key key) {
            final configIndex = (key as ValueKey<int>).value;
            final idx = _visibleRows.indexWhere(
              (r) => r.configIndex == configIndex,
            );
            return idx == -1 ? null : idx;
          },
          itemBuilder: (context, idx) {
            final row = _visibleRows[idx];
            final w = row.config;
            final key = ValueKey<int>(row.configIndex);

            return RepaintBoundary(
              child: row.async.when(
                loading: () => WidgetSection(
                  key: key,
                  title: w.title,
                  items: const [],
                  isLoading: true,
                  rowIndex: idx,
                  stableId: row.configIndex,
                  rowCount: _visibleRows.length,
                  ownRoute: '/shows',
                  rowRegistry: _rowRegistry,
                  mediaType: 'show',
                  provider: w.provider,
                  category: w.category,
                  onRowFocusRequested: _focusRowByDpad,
                  onFirstCardRegistered: _onFirstCardRegistered,
                ),
                // Unreachable in practice — a row in _visibleRows is never in
                // an error state (see _isRowVisible) — but handled rather
                // than assumed, in case that invariant ever slips.
                error: (_, _) => const SizedBox.shrink(),
                data: (catalog) => WidgetSection(
                  key: key,
                  title: w.title,
                  items: catalog.items,
                  rowIndex: idx,
                  stableId: row.configIndex,
                  rowCount: _visibleRows.length,
                  ownRoute: '/shows',
                  rowRegistry: _rowRegistry,
                  mediaType: 'show',
                  provider: w.provider,
                  category: w.category,
                  onRowFocusRequested: _focusRowByDpad,
                  onFirstCardRegistered: _onFirstCardRegistered,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
