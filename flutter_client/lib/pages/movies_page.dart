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

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});

  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> with RouteAware {
  static const _rowSnapDuration = Duration(milliseconds: 320);

  final _pageCtrl = PageController();
  // Page-local registry — Movies/Shows/Search each own their own instance so
  // row indices (0, 1, 2, ...) never collide across pages.
  final _rowRegistry = RowFirstCardRegistry();
  List<WidgetConfig> _widgets = kDefaultMovieWidgets;
  bool _snapping = false;
  int? _pendingDpadFocusRow;
  bool _focusedTabOnCatalogError = false;
  // Trackpad pan/zoom accumulator — cleared on gesture start and after each snap.
  double _trackpadAccum = 0.0;

  @override
  void initState() {
    super.initState();
    ref.read(widgetsConfigProvider).whenData((cfg) {
      _widgets = cfg.movies;
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

  // Shared snap logic for both input paths.
  void _snapTo(double dy) {
    if (_snapping) return;
    if (dy.abs() < 2) return;
    if (!_pageCtrl.hasClients) return;
    final page = _pageCtrl.page?.round() ?? 0;
    final maxPage = _widgets.length - 1;
    if (maxPage < 0) return;
    final target = dy > 0
        ? (page + 1).clamp(0, maxPage)
        : (page - 1).clamp(0, maxPage);
    if (target == page) return;
    _snapping = true;
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

  void _focusTabOnCatalogError(int rowIndex) {
    if (rowIndex != 0 || _focusedTabOnCatalogError) return;
    _focusedTabOnCatalogError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || GoRouterState.of(context).uri.path != '/') return;
      final tab = ref.read(tabBarFocusRegistryProvider).forRoute('/');
      if (tab != null) Dpad.of(context).requestFocus(tab);
    });
  }

  Future<void> _focusRowByDpad(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= _widgets.length) return;
    _pendingDpadFocusRow = rowIndex;
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

  // Mouse wheel — each PointerScrollEvent is a discrete notch; fire immediately.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      _snapTo(event.scrollDelta.dy);
    });
  }

  // Trackpad — panDelta is small per frame; accumulate until threshold, then snap.
  // panDelta.dy shares the same sign convention as scrollDelta.dy (macOS applies
  // the natural-scrolling flip to both before Flutter sees them).
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
        if (mounted) setState(() => _widgets = cfg.movies);
      });
    });

    // Invalidate all catalog rows when playback ends so "Continue Watching" refreshes
    ref.listen(playbackEndedProvider, (_, n) {
      ref.invalidate(catalogDataProvider);
    });

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
          itemCount: _widgets.length,
          itemBuilder: (context, idx) {
            final w = _widgets[idx];
            final catalogAsync = ref.watch(
              catalogDataProvider(
                provider: w.provider,
                category: w.category,
                mediaType: 'movie',
              ),
            );

            return RepaintBoundary(
              child: catalogAsync.when(
                loading: () => WidgetSection(
                  title: w.title,
                  items: const [],
                  isLoading: true,
                  rowIndex: idx,
                  rowCount: _widgets.length,
                  ownRoute: '/',
                  rowRegistry: _rowRegistry,
                  mediaType: 'movie',
                  provider: w.provider,
                  category: w.category,
                  initialFocus: idx == 0,
                  onRowFocusRequested: _focusRowByDpad,
                  onFirstCardRegistered: _onFirstCardRegistered,
                ),
                error: (_, _) {
                  _focusTabOnCatalogError(idx);
                  return WidgetSection(
                    title: w.title,
                    items: const [],
                    rowIndex: idx,
                    rowCount: _widgets.length,
                    ownRoute: '/',
                    rowRegistry: _rowRegistry,
                    mediaType: 'movie',
                    provider: w.provider,
                    category: w.category,
                    onRowFocusRequested: _focusRowByDpad,
                    onFirstCardRegistered: _onFirstCardRegistered,
                  );
                },
                data: (catalog) => WidgetSection(
                  key: ValueKey('movies-$idx-${w.category}'),
                  title: w.title,
                  items: catalog.items,
                  rowIndex: idx,
                  rowCount: _widgets.length,
                  ownRoute: '/',
                  rowRegistry: _rowRegistry,
                  mediaType: 'movie',
                  provider: w.provider,
                  category: w.category,
                  initialFocus: idx == 0,
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
