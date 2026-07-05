import 'package:dpad/dpad.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/catalog_constants.dart';
import '../models/catalog.dart';
import '../providers/catalog_provider.dart';
import '../providers/detail_provider.dart';
import '../navigation/row_first_card_registry.dart';
import '../widgets/media/widget_section.dart';

class ShowsPage extends ConsumerStatefulWidget {
  const ShowsPage({super.key});

  @override
  ConsumerState<ShowsPage> createState() => _ShowsPageState();
}

class _ShowsPageState extends ConsumerState<ShowsPage> {
  final _pageCtrl = PageController();
  // Page-local registry — Movies/Shows/Search each own their own instance so
  // row indices (0, 1, 2, ...) never collide across pages.
  final _rowRegistry = RowFirstCardRegistry();
  List<WidgetConfig> _widgets = kDefaultShowWidgets;
  bool _snapping = false;
  double _trackpadAccum = 0.0;

  @override
  void initState() {
    super.initState();
    ref.read(widgetsConfigProvider).whenData((cfg) {
      _widgets = cfg.shows;
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

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
        .animateToPage(target,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic)
        .then((_) {
          if (!mounted) return;
          _snapping = false;
          _trackpadAccum = 0.0;
          final node = _rowRegistry.entryFor(target);
          if (node != null) Dpad.of(context).requestFocus(node);
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
        if (mounted) setState(() => _widgets = cfg.shows);
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
                mediaType: 'show',
              ),
            );

            return catalogAsync.when(
              loading: () => WidgetSection(
                title: w.title,
                items: const [],
                isLoading: true,
                rowIndex: idx,
                ownRoute: '/shows',
                rowRegistry: _rowRegistry,
                mediaType: 'show',
                provider: w.provider,
                category: w.category,
                initialFocus: idx == 0,
              ),
              error: (_, _) => WidgetSection(
                title: w.title,
                items: const [],
                rowIndex: idx,
                ownRoute: '/shows',
                rowRegistry: _rowRegistry,
                mediaType: 'show',
                provider: w.provider,
                category: w.category,
              ),
              data: (catalog) => WidgetSection(
                key: ValueKey('shows-$idx-${w.category}'),
                title: w.title,
                items: catalog.items,
                rowIndex: idx,
                ownRoute: '/shows',
                rowRegistry: _rowRegistry,
                mediaType: 'show',
                provider: w.provider,
                category: w.category,
                initialFocus: idx == 0,
              ),
            );
          },
        ),
      ),
    );
  }
}
