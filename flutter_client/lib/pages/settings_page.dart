import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../api/api_client.dart';
import '../api/catalog_constants.dart';
import '../models/auth.dart';
import '../models/catalog.dart';
import '../navigation/tab_bar_focus_registry.dart';
import '../providers/catalog_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/warp_tokens.dart';
import '../widgets/shared/dpad_controls.dart';
import '../widgets/shared/modal_focus_restore.dart';
import '../widgets/shared/tv_modal_chrome_scale.dart';

// Settings API key names (must match backend)
const _kTmdbApiKey = 'tmdb_api_key';
const _kTraktClientId = 'trakt_client_id';
const _kTraktClientSecret = 'trakt_client_secret';
const _kDebridClientId = 'realdebrid_client_id';
const _kDebridClientSecret = 'realdebrid_client_secret';
const _kTorrentApiUrl = 'torrent_api_url';
const _kTorrentApiKey = 'torrent_api_key';

bool _isTvScaled(BuildContext context) {
  final media = MediaQuery.of(context);
  final view = View.maybeOf(context);
  if (view == null || media.size.width <= 0) return false;
  final logicalViewportWidth = view.physicalSize.width / view.devicePixelRatio;
  return media.size.width > logicalViewportWidth * 1.2;
}

Duration _settingsFocusDuration(BuildContext context) => _isTvScaled(context)
    ? const Duration(milliseconds: 100)
    : const Duration(milliseconds: 160);

Duration _settingsScrollDuration(BuildContext context) => _isTvScaled(context)
    ? const Duration(milliseconds: 150)
    : const Duration(milliseconds: 240);

bool _focusSettingsNode(BuildContext context, FocusNode node) {
  final focused = Dpad.of(context).requestFocus(node);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!node.hasFocus) return;
    final nodeContext = node.context;
    if (nodeContext == null) return;
    Scrollable.ensureVisible(
      nodeContext,
      alignment: 0.12,
      duration: _settingsFocusDuration(nodeContext),
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  });
  return focused;
}

// ─────────────────────────────────────────────────────────────────────────────
// SettingsPage — mirrors Tauri SettingsPage.tsx:
//   sidebar (header + nav + footer) + content header + scrollable body
// ─────────────────────────────────────────────────────────────────────────────

enum _SettingsSection { auth, providers, apiKeys, connection, catalog, general }

class _SectionMeta {
  final _SettingsSection id;
  final IconData icon;
  final String label;
  final String description;
  const _SectionMeta(this.id, this.icon, this.label, this.description);
}

const _sections = [
  _SectionMeta(
    _SettingsSection.auth,
    Icons.shield_outlined,
    'Authentication',
    'Trakt & Real Debrid accounts',
  ),
  _SectionMeta(
    _SettingsSection.providers,
    Icons.bolt_outlined,
    'Providers',
    'Service connection status',
  ),
  _SectionMeta(
    _SettingsSection.apiKeys,
    Icons.key_outlined,
    'API Keys',
    'TMDb and provider keys',
  ),
  _SectionMeta(
    _SettingsSection.connection,
    Icons.dns_outlined,
    'Connection',
    'Backend server settings',
  ),
  _SectionMeta(
    _SettingsSection.catalog,
    Icons.grid_view_outlined,
    'Catalog',
    'Content sources & widgets',
  ),
  _SectionMeta(
    _SettingsSection.general,
    Icons.tune_outlined,
    'General',
    'App preferences',
  ),
];

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  _SettingsSection _section = _SettingsSection.auth;
  late final List<FocusNode> _sidebarFocusNodes;
  late final List<_ApiKeyFocus> _apiKeyFocusNodes;
  late final List<FocusNode> _catalogConfigureFocusNodes;
  final _contentScrollController = ScrollController();
  final _scrollRailFocusNode = FocusNode(debugLabel: 'SettingsScrollRail');
  final _traktFocusNode = FocusNode(debugLabel: 'SettingsAuthTrakt');
  final _debridFocusNode = FocusNode(debugLabel: 'SettingsAuthRealDebrid');
  final _connectionFieldFocusNode = FocusNode(debugLabel: 'BackendUrlField');
  final _connectionWrapperFocusNode = FocusNode(
    debugLabel: 'BackendUrlWrapper',
  );
  final _connectionTestFocusNode = FocusNode(
    debugLabel: 'SettingsConnectionTest',
  );
  final _connectionSaveFocusNode = FocusNode(
    debugLabel: 'SettingsConnectionSave',
  );
  final _catalogMovieFocusNode = FocusNode(debugLabel: 'SettingsCatalogMovies');
  final _catalogShowFocusNode = FocusNode(debugLabel: 'SettingsCatalogShows');
  final _catalogSaveFocusNode = FocusNode(debugLabel: 'SettingsCatalogSave');
  final _catalogRefreshFocusNode = FocusNode(
    debugLabel: 'SettingsCatalogRefresh',
  );
  FocusNode? _lastSettingsFocus;
  bool _appActive = true;

  static const _apiKeySpecs = [
    (label: 'API Key', settingKey: _kTmdbApiKey, obscure: true),
    (label: 'Client ID', settingKey: _kTraktClientId, obscure: true),
    (label: 'Client Secret', settingKey: _kTraktClientSecret, obscure: true),
    (label: 'Client ID', settingKey: _kDebridClientId, obscure: true),
    (label: 'Client Secret', settingKey: _kDebridClientSecret, obscure: true),
    (label: 'API URL', settingKey: _kTorrentApiUrl, obscure: false),
    (label: 'API Key', settingKey: _kTorrentApiKey, obscure: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_rememberSettingsFocus);
    _sidebarFocusNodes = List.generate(
      _sections.length,
      (i) => FocusNode(debugLabel: 'SettingsSidebar-${_sections[i].label}'),
    );
    _apiKeyFocusNodes = List.generate(
      _apiKeySpecs.length,
      (i) => _ApiKeyFocus(_apiKeySpecs[i].settingKey),
    );
    _catalogConfigureFocusNodes = List.generate(
      6,
      (i) => FocusNode(debugLabel: 'SettingsCatalogConfigure-$i'),
    );
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_rememberSettingsFocus);
    WidgetsBinding.instance.removeObserver(this);
    for (final node in _sidebarFocusNodes) {
      node.dispose();
    }
    for (final nodes in _apiKeyFocusNodes) {
      nodes.dispose();
    }
    for (final node in _catalogConfigureFocusNodes) {
      node.dispose();
    }
    _contentScrollController.dispose();
    _scrollRailFocusNode.dispose();
    _traktFocusNode.dispose();
    _debridFocusNode.dispose();
    _connectionFieldFocusNode.dispose();
    _connectionWrapperFocusNode.dispose();
    _connectionTestFocusNode.dispose();
    _connectionSaveFocusNode.dispose();
    _catalogMovieFocusNode.dispose();
    _catalogShowFocusNode.dispose();
    _catalogSaveFocusNode.dispose();
    _catalogRefreshFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final node = _lastSettingsFocus;
        if (mounted && node?.context != null) {
          _focusSettingsNode(context, node!);
        }
      });
    }
  }

  void _rememberSettingsFocus() {
    if (!_appActive || !mounted) return;
    final node = FocusManager.instance.primaryFocus;
    final nodeContext = node?.context;
    if (node == null || node is FocusScopeNode || nodeContext == null) return;
    final pageBox = context.findRenderObject();
    final focusBox = nodeContext.findRenderObject();
    if (pageBox == null || focusBox == null) return;
    var current = focusBox.parent;
    while (current != null) {
      if (identical(current, pageBox)) {
        _lastSettingsFocus = node;
        return;
      }
      current = current.parent;
    }
  }

  void _selectSection(_SettingsSection section) {
    setState(() => _section = section);
    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }
  }

  // Only the 1st sidebar entry needs an Up override (-> Settings tab pill).
  // Every other sidebar entry's Up/Down is plain default beam nav within
  // the vertical list, and Right into the content panel is plain default
  // beam nav too — no other overrides needed on this page.
  bool _firstNavItemUp(TraversalDirection d) {
    if (d != TraversalDirection.up) return false;
    final tab = ref.read(tabBarFocusRegistryProvider).forRoute('/settings');
    if (tab == null) return false;
    _focusSettingsNode(context, tab);
    return true;
  }

  bool _sidebarDirection(int index, TraversalDirection direction) {
    if (direction == TraversalDirection.up) {
      if (index == 0) return _firstNavItemUp(direction);
      _focusSettingsNode(context, _sidebarFocusNodes[index - 1]);
      return true;
    }
    if (direction == TraversalDirection.down) {
      if (index < _sidebarFocusNodes.length - 1) {
        _focusSettingsNode(context, _sidebarFocusNodes[index + 1]);
      }
      return true;
    }
    if (direction == TraversalDirection.right) {
      _focusContentEntry(_sections[index].id);
      return true;
    }
    if (direction == TraversalDirection.left) return true;
    return false;
  }

  bool _focusSidebar([_SettingsSection? section]) {
    final target = section ?? _section;
    final index = _sections.indexWhere((s) => s.id == target);
    if (index < 0) return false;
    _focusSettingsNode(context, _sidebarFocusNodes[index]);
    return true;
  }

  bool _focusScrollRail() {
    _focusSettingsNode(context, _scrollRailFocusNode);
    return true;
  }

  bool _focusMounted(FocusNode node) {
    if (node.context == null) return false;
    _focusSettingsNode(context, node);
    return true;
  }

  List<FocusNode> _contentNodesFor(_SettingsSection section) {
    return switch (section) {
      _SettingsSection.auth => [_traktFocusNode, _debridFocusNode],
      _SettingsSection.apiKeys => [
        for (final nodes in _apiKeyFocusNodes) ...[
          nodes.wrapper,
          if (nodes.hasVisibility) nodes.visibility,
          nodes.save,
        ],
      ],
      _SettingsSection.connection => [
        _connectionWrapperFocusNode,
        _connectionTestFocusNode,
        _connectionSaveFocusNode,
      ],
      _SettingsSection.catalog => [
        _catalogMovieFocusNode,
        _catalogShowFocusNode,
        ..._catalogConfigureFocusNodes,
        _catalogSaveFocusNode,
        _catalogRefreshFocusNode,
      ],
      _SettingsSection.providers || _SettingsSection.general => const [],
    };
  }

  bool _focusContentEntry([_SettingsSection? section]) {
    final target = section ?? _section;
    for (final node in _contentNodesFor(target)) {
      if (_focusMounted(node)) return true;
    }
    return _focusScrollRail();
  }

  bool _focusNearestContentToRail() {
    final nodes = _contentNodesFor(
      _section,
    ).where((node) => node.context != null).toList();
    if (nodes.isEmpty) return _focusSidebar();

    final railContext = _scrollRailFocusNode.context;
    final railBox = railContext?.findRenderObject();
    final railCenter = railBox is RenderBox && railBox.hasSize
        ? railBox.localToGlobal(railBox.size.center(Offset.zero)).dy
        : MediaQuery.sizeOf(context).height / 2;

    FocusNode? best;
    double bestDistance = double.infinity;
    double bestX = double.negativeInfinity;
    for (final node in nodes) {
      final nodeContext = node.context;
      if (nodeContext == null) continue;
      final box = nodeContext.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      final distance = (center.dy - railCenter).abs();
      if (distance < bestDistance - 0.5 ||
          ((distance - bestDistance).abs() <= 0.5 && center.dx > bestX)) {
        best = node;
        bestDistance = distance;
        bestX = center.dx;
      }
    }
    return best == null ? _focusSidebar() : _focusMounted(best);
  }

  void _scrollSettingsBody(double direction) {
    if (!_contentScrollController.hasClients) return;
    final position = _contentScrollController.position;
    final viewport = position.viewportDimension;
    final next = (position.pixels + viewport * 0.85 * direction).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    position.animateTo(
      next,
      duration: _settingsScrollDuration(context),
      curve: Curves.easeOutCubic,
    );
  }

  bool _scrollRailDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.up) {
      _scrollSettingsBody(-1);
      return true;
    }
    if (direction == TraversalDirection.down) {
      _scrollSettingsBody(1);
      return true;
    }
    if (direction == TraversalDirection.left) {
      return _focusNearestContentToRail();
    }
    if (direction == TraversalDirection.right) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final meta = _sections.firstWhere((s) => s.id == _section);
    final scaler = MediaQuery.textScalerOf(context);

    final sidebarW = scaler.scale((size.width * 0.175).clamp(240.0, 310.0));
    final hPadSide = scaler.scale((size.width * 0.012).clamp(16.0, 22.0));
    final vPadSide = scaler.scale((size.height * 0.015).clamp(14.0, 22.0));
    final bodyPad = (size.width * 0.0167).clamp(16.0, 28.0);

    return ColoredBox(
      color: const Color(0xFF181818),
      child: Column(
        children: [
          // Offset for the floating tab bar (same pattern as LibraryPage)
          SizedBox(height: t.tabBarHeight),

          Expanded(
            child: Row(
              children: [
                // ── Sidebar ──────────────────────────────────────────────────
                Container(
                  width: sidebarW,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white.withAlpha(18)),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xBF000000), Color(0xEB08080E)],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sidebar header
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPadSide,
                          vertical: vPadSide,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withAlpha(18),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: scaler.scale(
                                (size.width * 0.021).clamp(32.0, 40.0),
                              ),
                              height: scaler.scale(
                                (size.width * 0.021).clamp(32.0, 40.0),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0DB2E2).withAlpha(51),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.settings,
                                color: const Color(0xFF0DB2E2),
                                size: scaler.scale(15),
                              ),
                            ),
                            SizedBox(width: scaler.scale(12)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SETTINGS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: (size.width * 0.0065).clamp(
                                      11.0,
                                      13.0,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                Text(
                                  'Warp Media Center',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(77),
                                    fontSize: (size.width * 0.0055).clamp(
                                      9.0,
                                      11.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Nav items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            for (var i = 0; i < _sections.length; i++)
                              _NavItem(
                                meta: _sections[i],
                                selected: _section == _sections[i].id,
                                onTap: () => _selectSection(_sections[i].id),
                                screenSize: size,
                                focusNode: _sidebarFocusNodes[i],
                                autofocus: i == 0,
                                onDirection: (d) => _sidebarDirection(i, d),
                              ),
                          ],
                        ),
                      ),

                      // Footer version
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPadSide,
                          vertical: (size.height * 0.01).clamp(10.0, 14.0),
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white.withAlpha(18)),
                          ),
                        ),
                        child: Text(
                          'v1.0.0 · WARP MEDIA CENTER',
                          style: TextStyle(
                            color: Colors.white.withAlpha(51),
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content panel ─────────────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // Content header (icon + label + description)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: (size.width * 0.0167).clamp(20.0, 32.0),
                          vertical: (size.height * 0.015).clamp(14.0, 20.0),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(5),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withAlpha(18),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: (size.width * 0.025).clamp(38.0, 48.0),
                              height: (size.width * 0.025).clamp(38.0, 48.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0DB2E2).withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                meta.icon,
                                color: const Color(0xFF0DB2E2),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meta.label,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: (size.width * 0.011).clamp(
                                      15.0,
                                      20.0,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  meta.description,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(90),
                                    fontSize: (size.width * 0.0065).clamp(
                                      11.0,
                                      13.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Scrollable body
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _contentScrollController,
                                padding: EdgeInsets.all(bodyPad),
                                child: switch (_section) {
                                  _SettingsSection.auth => _AuthSectionPanel(
                                    t: t,
                                    traktFocusNode: _traktFocusNode,
                                    debridFocusNode: _debridFocusNode,
                                    onFocusSidebar: _focusSidebar,
                                    onFocusRail: _focusScrollRail,
                                  ),
                                  _SettingsSection.providers => _ProvidersPanel(
                                    t: t,
                                  ),
                                  _SettingsSection.apiKeys => _ApiKeysPanel(
                                    t: t,
                                    focusNodes: _apiKeyFocusNodes,
                                    onFocusSidebar: _focusSidebar,
                                    onFocusRail: _focusScrollRail,
                                  ),
                                  _SettingsSection.connection =>
                                    _ConnectionPanel(
                                      t: t,
                                      fieldFocusNode: _connectionFieldFocusNode,
                                      wrapperFocusNode:
                                          _connectionWrapperFocusNode,
                                      testFocusNode: _connectionTestFocusNode,
                                      saveFocusNode: _connectionSaveFocusNode,
                                      onFocusSidebar: _focusSidebar,
                                      onFocusRail: _focusScrollRail,
                                    ),
                                  _SettingsSection.catalog => _CatalogPanel(
                                    t: t,
                                    movieFocusNode: _catalogMovieFocusNode,
                                    showFocusNode: _catalogShowFocusNode,
                                    configureFocusNodes:
                                        _catalogConfigureFocusNodes,
                                    saveFocusNode: _catalogSaveFocusNode,
                                    refreshFocusNode: _catalogRefreshFocusNode,
                                    onFocusSidebar: _focusSidebar,
                                    onFocusRail: _focusScrollRail,
                                  ),
                                  _SettingsSection.general => _GeneralPanel(
                                    t: t,
                                  ),
                                },
                              ),
                            ),
                            _SettingsScrollRail(
                              focusNode: _scrollRailFocusNode,
                              tokens: t,
                              onDirection: _scrollRailDirection,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem — Tauri-style: left accent bar + icon box + label/description
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final _SectionMeta meta;
  final bool selected;
  final VoidCallback onTap;
  final Size screenSize;
  final FocusNode? focusNode;
  final bool autofocus;
  final DpadDirectionCallback? onDirection;

  const _NavItem({
    required this.meta,
    required this.selected,
    required this.onTap,
    required this.screenSize,
    this.focusNode,
    this.autofocus = false,
    this.onDirection,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.screenSize.width;
    final scaler = MediaQuery.textScalerOf(context);
    final selected = widget.selected;
    final meta = widget.meta;
    final iconBoxSize = scaler.scale((w * 0.025).clamp(36.0, 46.0));
    final labelFs = (w * 0.010).clamp(15.0, 17.0);
    final descFs = (w * 0.007).clamp(11.5, 13.0);
    final vPad = scaler.scale(
      (widget.screenSize.height * 0.012).clamp(10.0, 16.0),
    );
    final hPad = scaler.scale((w * 0.012).clamp(14.0, 22.0));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        effects: const [],
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onDirection: widget.onDirection,
        onSelect: widget.onTap,
        autoScroll: false,
        tapToSelect: false,
        builder: (context, state, child) => _buildContent(
          state.focused || _hovered,
          selected,
          meta,
          iconBoxSize,
          labelFs,
          descFs,
          vPad,
          hPad,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildContent(
    bool active,
    bool selected,
    _SectionMeta meta,
    double iconBoxSize,
    double labelFs,
    double descFs,
    double vPad,
    double hPad,
  ) {
    return AnimatedContainer(
      duration: _settingsFocusDuration(context),
      color: !selected && active
          ? Colors.white.withAlpha(18)
          : Colors.transparent,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            // Row content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF0DB2E2).withAlpha(64)
                          : (active
                                ? Colors.white.withAlpha(20)
                                : Colors.white.withAlpha(13)),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: selected
                          ? (_isTvScaled(context)
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0DB2E2,
                                      ).withAlpha(56),
                                      blurRadius: 14,
                                    ),
                                  ])
                          : null,
                    ),
                    child: Icon(
                      meta.icon,
                      size: MediaQuery.textScalerOf(context).scale(16),
                      color: selected
                          ? const Color(0xFF0DB2E2)
                          : (active
                                ? Colors.white.withAlpha(160)
                                : Colors.white.withAlpha(102)),
                    ),
                  ),
                  SizedBox(width: MediaQuery.textScalerOf(context).scale(12)),
                  // Label + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.label,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF0DB2E2)
                                : (active
                                      ? Colors.white.withAlpha(200)
                                      : Colors.white.withAlpha(140)),
                            fontSize: labelFs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          meta.description,
                          style: TextStyle(
                            color: Colors.white.withAlpha(64),
                            fontSize: descFs,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Left accent bar (active only)
            if (selected)
              Positioned(
                left: 0,
                top: vPad + iconBoxSize * 0.18,
                bottom: vPad + iconBoxSize * 0.18,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0DB2E2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsScrollRail extends StatelessWidget {
  final FocusNode focusNode;
  final WarpTokens tokens;
  final DpadDirectionCallback onDirection;

  const _SettingsScrollRail({
    required this.focusNode,
    required this.tokens,
    required this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: DpadFocusable(
          effects: const [],
          focusNode: focusNode,
          onDirection: onDirection,
          onSelect: () {},
          autoScroll: false,
          tapToSelect: false,
          builder: (context, state, child) {
            return AnimatedContainer(
              duration: _settingsFocusDuration(context),
              width: state.focused ? 8 : 4,
              height: 120,
              decoration: BoxDecoration(
                color: state.focused
                    ? const Color(0xFF0DB2E2)
                    : Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(999),
                boxShadow: state.focused
                    ? (_isTvScaled(context)
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF0DB2E2).withAlpha(120),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ])
                    : null,
              ),
            );
          },
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _ApiKeyFocus {
  final FocusNode field;
  final FocusNode wrapper;
  final FocusNode visibility;
  final FocusNode save;
  bool hasVisibility = true;

  _ApiKeyFocus(String key)
    : field = FocusNode(debugLabel: 'SettingsApiKeyField-$key'),
      wrapper = FocusNode(debugLabel: 'SettingsApiKeyWrapper-$key'),
      visibility = FocusNode(debugLabel: 'SettingsApiKeyVisibility-$key'),
      save = FocusNode(debugLabel: 'SettingsApiKeySave-$key');

  void dispose() {
    field.dispose();
    wrapper.dispose();
    visibility.dispose();
    save.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connection Panel — backend URL config + health test
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectionPanel extends ConsumerStatefulWidget {
  final WarpTokens t;
  final FocusNode fieldFocusNode;
  final FocusNode wrapperFocusNode;
  final FocusNode testFocusNode;
  final FocusNode saveFocusNode;
  final bool Function([_SettingsSection? section]) onFocusSidebar;
  final bool Function() onFocusRail;
  const _ConnectionPanel({
    required this.t,
    required this.fieldFocusNode,
    required this.wrapperFocusNode,
    required this.testFocusNode,
    required this.saveFocusNode,
    required this.onFocusSidebar,
    required this.onFocusRail,
  });

  @override
  ConsumerState<_ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends ConsumerState<_ConnectionPanel> {
  late final TextEditingController _urlCtrl;
  bool _testing = false;
  bool? _testOk;
  String? _testError;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ref.read(apiBaseUrlProvider));
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  bool _fieldDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.left) return widget.onFocusSidebar();
    if (direction == TraversalDirection.right) return widget.onFocusRail();
    if (direction == TraversalDirection.down) {
      _focusSettingsNode(context, widget.testFocusNode);
      return true;
    }
    if (direction == TraversalDirection.up) return true;
    return false;
  }

  bool _testDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.left) return widget.onFocusSidebar();
    if (direction == TraversalDirection.right) {
      _focusSettingsNode(context, widget.saveFocusNode);
      return true;
    }
    if (direction == TraversalDirection.up) {
      _focusSettingsNode(context, widget.wrapperFocusNode);
      return true;
    }
    if (direction == TraversalDirection.down) return true;
    return false;
  }

  bool _saveDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.left) {
      _focusSettingsNode(context, widget.testFocusNode);
      return true;
    }
    if (direction == TraversalDirection.right) return widget.onFocusRail();
    if (direction == TraversalDirection.up) {
      _focusSettingsNode(context, widget.wrapperFocusNode);
      return true;
    }
    if (direction == TraversalDirection.down) return true;
    return false;
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testOk = null;
      _testError = null;
    });
    try {
      final testClient = ApiClient(_urlCtrl.text.trim());
      await testClient.get<Map<String, dynamic>>('/api/v1/health');
      if (mounted) {
        setState(() {
          _testing = false;
          _testOk = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testing = false;
          _testOk = false;
          _testError = e.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    ref.read(apiBaseUrlProvider.notifier).update(url);
    await saveBaseUrl(url);
    if (mounted) setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Server Connection', t),
        const SizedBox(height: 8),
        Text(
          'The URL of your Warp MediaCenter backend (default: http://localhost:8000).',
          style: TextStyle(color: Colors.white54, fontSize: t.fontSubtitle),
        ),
        const SizedBox(height: 24),

        // URL field
        WarpDpadTextField(
          controller: _urlCtrl,
          fieldFocusNode: widget.fieldFocusNode,
          wrapperFocusNode: widget.wrapperFocusNode,
          tokens: t,
          onDirection: _fieldDirection,
          moveCursorToEndOnEnter: true,
          enableSelectAllContextMenu: true,
          onSubmitted: (_) => _save(),
          style: TextStyle(color: Colors.white, fontSize: t.fontBody),
          decoration: InputDecoration(
            labelText: 'Backend URL',
            labelStyle: const TextStyle(color: Colors.white38),
            hintText: 'http://localhost:8000',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withAlpha(8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withAlpha(30)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withAlpha(30)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0DB2E2)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Buttons
        Row(
          children: [
            _ActionButton(
              label: _testing ? 'Testing…' : 'Test Connection',
              icon: Icons.wifi_tethering,
              onTap: _testing ? null : _testConnection,
              t: t,
              focusNode: widget.testFocusNode,
              onDirection: _testDirection,
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: _saved ? 'Saved!' : 'Save',
              icon: Icons.save_outlined,
              onTap: _save,
              t: t,
              focusNode: widget.saveFocusNode,
              onDirection: _saveDirection,
            ),
          ],
        ),

        // Test result
        if (_testOk != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _testOk! ? Icons.check_circle_outline : Icons.error_outline,
                color: _testOk! ? const Color(0xFF10B981) : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _testOk!
                      ? 'Connection successful!'
                      : 'Connection failed: ${_testError ?? 'Unknown error'}',
                  style: TextStyle(
                    color: _testOk!
                        ? const Color(0xFF10B981)
                        : Colors.redAccent,
                    fontSize: t.fontSubtitle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API Keys Panel — masked text fields for all API keys
// ─────────────────────────────────────────────────────────────────────────────

class _ApiKeysPanel extends ConsumerWidget {
  final WarpTokens t;
  final List<_ApiKeyFocus> focusNodes;
  final bool Function([_SettingsSection? section]) onFocusSidebar;
  final bool Function() onFocusRail;
  const _ApiKeysPanel({
    required this.t,
    required this.focusNodes,
    required this.onFocusSidebar,
    required this.onFocusRail,
  });

  bool _focus(BuildContext context, FocusNode node) {
    return _focusSettingsNode(context, node);
  }

  bool _fieldDirection(
    BuildContext context,
    int index,
    bool hasVisibility,
    TraversalDirection direction,
  ) {
    if (direction == TraversalDirection.left) return onFocusSidebar();
    if (direction == TraversalDirection.right) {
      return _focus(
        context,
        hasVisibility ? focusNodes[index].visibility : focusNodes[index].save,
      );
    }
    if (direction == TraversalDirection.up) {
      if (index == 0) return true;
      return _focus(context, focusNodes[index - 1].wrapper);
    }
    if (direction == TraversalDirection.down) {
      if (index >= focusNodes.length - 1) return true;
      return _focus(context, focusNodes[index + 1].wrapper);
    }
    return false;
  }

  bool _visibilityDirection(
    BuildContext context,
    int index,
    TraversalDirection direction,
  ) {
    if (direction == TraversalDirection.left) {
      return _focus(context, focusNodes[index].wrapper);
    }
    if (direction == TraversalDirection.right) {
      return _focus(context, focusNodes[index].save);
    }
    if (direction == TraversalDirection.up) {
      if (index == 0) return true;
      return _focus(context, focusNodes[index - 1].wrapper);
    }
    if (direction == TraversalDirection.down) {
      if (index >= focusNodes.length - 1) return true;
      return _focus(context, focusNodes[index + 1].wrapper);
    }
    return false;
  }

  bool _saveDirection(
    BuildContext context,
    int index,
    bool hasVisibility,
    TraversalDirection direction,
  ) {
    if (direction == TraversalDirection.left) {
      return _focus(
        context,
        hasVisibility
            ? focusNodes[index].visibility
            : focusNodes[index].wrapper,
      );
    }
    if (direction == TraversalDirection.right) return onFocusRail();
    if (direction == TraversalDirection.up) {
      if (index == 0) return true;
      return _focus(context, focusNodes[index - 1].save);
    }
    if (direction == TraversalDirection.down) {
      if (index >= focusNodes.length - 1) return true;
      return _focus(context, focusNodes[index + 1].save);
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('API Keys', t),
        const SizedBox(height: 8),
        Text(
          'Configure API keys for media providers.',
          style: TextStyle(color: Colors.white54, fontSize: t.fontSubtitle),
        ),
        const SizedBox(height: 24),

        _KeyGroup(
          title: 'TMDB',
          t: t,
          fields: [
            _ApiKeyField(
              label: 'API Key',
              settingKey: _kTmdbApiKey,
              t: t,
              focusNodes: focusNodes[0],
              onFieldDirection: (d) => _fieldDirection(context, 0, true, d),
              onVisibilityDirection: (d) => _visibilityDirection(context, 0, d),
              onSaveDirection: (d) => _saveDirection(context, 0, true, d),
            ),
          ],
        ),
        _KeyGroup(
          title: 'Trakt.tv',
          t: t,
          fields: [
            _ApiKeyField(
              label: 'Client ID',
              settingKey: _kTraktClientId,
              t: t,
              focusNodes: focusNodes[1],
              onFieldDirection: (d) => _fieldDirection(context, 1, true, d),
              onVisibilityDirection: (d) => _visibilityDirection(context, 1, d),
              onSaveDirection: (d) => _saveDirection(context, 1, true, d),
            ),
            _ApiKeyField(
              label: 'Client Secret',
              settingKey: _kTraktClientSecret,
              t: t,
              focusNodes: focusNodes[2],
              onFieldDirection: (d) => _fieldDirection(context, 2, true, d),
              onVisibilityDirection: (d) => _visibilityDirection(context, 2, d),
              onSaveDirection: (d) => _saveDirection(context, 2, true, d),
            ),
          ],
        ),
        _KeyGroup(
          title: 'Real-Debrid',
          t: t,
          fields: [
            _ApiKeyField(
              label: 'Client ID',
              settingKey: _kDebridClientId,
              t: t,
              focusNodes: focusNodes[3],
              onFieldDirection: (d) => _fieldDirection(context, 3, true, d),
              onVisibilityDirection: (d) => _visibilityDirection(context, 3, d),
              onSaveDirection: (d) => _saveDirection(context, 3, true, d),
            ),
            _ApiKeyField(
              label: 'Client Secret',
              settingKey: _kDebridClientSecret,
              t: t,
              focusNodes: focusNodes[4],
              onFieldDirection: (d) => _fieldDirection(context, 4, true, d),
              onVisibilityDirection: (d) => _visibilityDirection(context, 4, d),
              onSaveDirection: (d) => _saveDirection(context, 4, true, d),
            ),
          ],
        ),
        _KeyGroup(
          title: 'Torrent API',
          t: t,
          fields: [
            _ApiKeyField(
              label: 'API URL',
              settingKey: _kTorrentApiUrl,
              t: t,
              focusNodes: focusNodes[5],
              obscure: false,
              onFieldDirection: (d) => _fieldDirection(context, 5, false, d),
              onSaveDirection: (d) => _saveDirection(context, 5, false, d),
            ),
            _ApiKeyField(
              label: 'API Key',
              settingKey: _kTorrentApiKey,
              t: t,
              focusNodes: focusNodes[6],
              onFieldDirection: (d) => _fieldDirection(context, 6, true, d),
              onVisibilityDirection: (d) => _visibilityDirection(context, 6, d),
              onSaveDirection: (d) => _saveDirection(context, 6, true, d),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyGroup extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final WarpTokens t;

  const _KeyGroup({required this.title, required this.fields, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white60,
              fontSize: t.fontSubtitle,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...fields,
        ],
      ),
    );
  }
}

class _ApiKeyField extends ConsumerStatefulWidget {
  final String label;
  final String settingKey;
  final bool obscure;
  final WarpTokens t;
  final _ApiKeyFocus focusNodes;
  final DpadDirectionCallback onFieldDirection;
  final DpadDirectionCallback? onVisibilityDirection;
  final DpadDirectionCallback onSaveDirection;

  const _ApiKeyField({
    required this.label,
    required this.settingKey,
    required this.t,
    required this.focusNodes,
    required this.onFieldDirection,
    required this.onSaveDirection,
    this.obscure = true,
    this.onVisibilityDirection,
  });

  @override
  ConsumerState<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends ConsumerState<_ApiKeyField> {
  late final TextEditingController _ctrl;
  bool _showText = false;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final val = _ctrl.text.trim();
    if (val.isEmpty) return;
    setState(() => _saving = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.put<Map<String, dynamic>>(
        '/api/v1/settings/${widget.settingKey}',
        body: {'value': val},
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _saved = false);
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    widget.focusNodes.hasVisibility = widget.obscure;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: WarpDpadTextField(
              controller: _ctrl,
              fieldFocusNode: widget.focusNodes.field,
              wrapperFocusNode: widget.focusNodes.wrapper,
              tokens: t,
              onDirection: widget.onFieldDirection,
              obscureText: widget.obscure && !_showText,
              style: TextStyle(
                color: Colors.white,
                fontSize: t.fontSubtitle,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(25)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0DB2E2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (widget.obscure) ...[
            WarpDpadButton(
              tokens: t,
              focusNode: widget.focusNodes.visibility,
              onDirection: widget.onVisibilityDirection,
              onSelect: () => setState(() => _showText = !_showText),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: Colors.white.withAlpha(8),
              borderColor: Colors.white.withAlpha(20),
              borderRadius: 8,
              child: Icon(
                _showText ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          WarpDpadButton(
            tokens: t,
            focusNode: widget.focusNodes.save,
            onDirection: widget.onSaveDirection,
            enabled: !_saving,
            onSelect: _save,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            backgroundColor: _saved
                ? const Color(0xFF10B981).withAlpha(30)
                : const Color(0xFF0DB2E2).withAlpha(20),
            borderColor: _saved
                ? const Color(0xFF10B981).withAlpha(80)
                : const Color(0xFF0DB2E2).withAlpha(60),
            borderRadius: 8,
            child: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF0DB2E2),
                    ),
                  )
                : Icon(
                    _saved ? Icons.check : Icons.save_outlined,
                    color: _saved
                        ? const Color(0xFF10B981)
                        : const Color(0xFF0DB2E2),
                    size: 16,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers Panel — shows status of TMDB, Trakt, RealDebrid, TorrentAPI
// ─────────────────────────────────────────────────────────────────────────────

class _ProvidersPanel extends ConsumerWidget {
  final WarpTokens t;
  const _ProvidersPanel({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(providersStatusProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0DB2E2),
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => Text(
        '$e',
        style: TextStyle(color: Colors.redAccent, fontSize: t.fontBody),
      ),
      data: (resp) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Provider Status', t),
          const SizedBox(height: 16),
          _ProviderRow(name: 'TMDB', status: resp.tmdb, t: t),
          _ProviderRow(name: 'Trakt.tv', status: resp.trakt, t: t),
          _ProviderRow(name: 'Real-Debrid', status: resp.realdebrid, t: t),
          _ProviderRow(name: 'Torrent API', status: resp.torrentApi, t: t),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final String name;
  final ProviderStatus status;
  final WarpTokens t;

  const _ProviderRow({
    required this.name,
    required this.status,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final ok =
        status.authenticated == true ||
        status.status == 'configured' ||
        status.status == 'available';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ok ? const Color(0xFF10B981) : Colors.white30,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: Colors.white, fontSize: t.fontBody),
            ),
          ),
          Text(
            status.status,
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trakt Panel — device flow auth
// ─────────────────────────────────────────────────────────────────────────────

class _TraktPanel extends ConsumerStatefulWidget {
  final WarpTokens t;
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;
  const _TraktPanel({
    required this.t,
    required this.focusNode,
    required this.onDirection,
  });

  @override
  ConsumerState<_TraktPanel> createState() => _TraktPanelState();
}

class _TraktPanelState extends ConsumerState<_TraktPanel> {
  bool _starting = false;
  TraktAuthStartResponse? _deviceFlow;
  Timer? _pollTimer;
  String? _error;
  bool _authed = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startFlow() async {
    setState(() {
      _starting = true;
      _error = null;
      _deviceFlow = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.post<Map<String, dynamic>>(
        '/api/v1/trakt/auth/start',
        body: {},
      );
      final resp = TraktAuthStartResponse.fromJson(raw);
      setState(() {
        _deviceFlow = resp;
        _starting = false;
      });
      _pollTimer = Timer.periodic(
        Duration(seconds: resp.interval),
        (_) => _pollStatus(),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _starting = false;
      });
    }
  }

  Future<void> _pollStatus() async {
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.get<Map<String, dynamic>>(
        '/api/v1/trakt/auth/status',
      );
      final status = AuthStatus.fromJson(raw);
      if (status.authenticated) {
        _pollTimer?.cancel();
        setState(() {
          _authed = true;
          _deviceFlow = null;
        });
        ref.invalidate(traktAuthStatusProvider);
      }
    } catch (_) {}
  }

  Future<void> _disconnect() async {
    try {
      final client = ref.read(apiClientProvider);
      await client.post<void>('/api/v1/trakt/auth/clear', body: {});
      ref.invalidate(traktAuthStatusProvider);
      ref.invalidate(traktAccountProvider);
      setState(() => _authed = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final authAsync = ref.watch(traktAuthStatusProvider);
    final accountAsync = ref.watch(traktAccountProvider);

    return authAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0DB2E2),
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => Text(
        '$e',
        style: TextStyle(color: Colors.redAccent, fontSize: t.fontBody),
      ),
      data: (status) {
        final isAuthed = _authed || status.authenticated;

        String? detail;
        if (isAuthed) {
          final profile = accountAsync.asData?.value;
          if (profile != null) {
            final vipTag = profile.vip ? ' · VIP' : '';
            detail = '@${profile.username}$vipTag';
          } else if (status.expiresAt != null) {
            detail = 'Token expires ${status.expiresAt}';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Trakt.tv', t),
            const SizedBox(height: 8),
            Text(
              'Connect your Trakt account to sync watch history and ratings.',
              style: TextStyle(color: Colors.white54, fontSize: t.fontSubtitle),
            ),
            const SizedBox(height: 24),
            if (isAuthed)
              _ConnectedBox(
                provider: 'Trakt.tv',
                detail: detail,
                onDisconnect: _disconnect,
                t: t,
                focusNode: widget.focusNode,
                onDirection: widget.onDirection,
              )
            else if (_deviceFlow != null)
              _DeviceFlowBox(flow: _deviceFlow!, t: t)
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              _ActionButton(
                label: _starting ? 'Connecting…' : 'Connect Trakt',
                icon: Icons.favorite_border,
                onTap: _starting ? null : _startFlow,
                t: t,
                focusNode: widget.focusNode,
                onDirection: widget.onDirection,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RealDebrid Panel — device flow (start → complete)
// ─────────────────────────────────────────────────────────────────────────────

class _DebridPanel extends ConsumerStatefulWidget {
  final WarpTokens t;
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;
  const _DebridPanel({
    required this.t,
    required this.focusNode,
    required this.onDirection,
  });

  @override
  ConsumerState<_DebridPanel> createState() => _DebridPanelState();
}

class _DebridPanelState extends ConsumerState<_DebridPanel> {
  bool _starting = false;
  Map<String, dynamic>? _flowData; // raw start response
  Timer? _pollTimer;
  String? _error;
  bool _authed = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startFlow() async {
    setState(() {
      _starting = true;
      _error = null;
      _flowData = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.post<Map<String, dynamic>>(
        '/api/v1/debrid/auth/start',
        body: {},
      );
      setState(() {
        _flowData = raw;
        _starting = false;
      });
      // Poll completion
      final interval = (raw['interval'] as num?)?.toInt() ?? 5;
      _pollTimer = Timer.periodic(
        Duration(seconds: interval),
        (_) => _pollStatus(),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _starting = false;
      });
    }
  }

  Future<void> _pollStatus() async {
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.get<Map<String, dynamic>>(
        '/api/v1/debrid/auth/status',
      );
      final status = AuthStatus.fromJson(raw);
      if (status.authenticated) {
        _pollTimer?.cancel();
        setState(() {
          _authed = true;
          _flowData = null;
        });
        ref.invalidate(debridAuthStatusProvider);
        ref.invalidate(debridAccountProvider);
      }
    } catch (_) {}
  }

  Future<void> _disconnect() async {
    try {
      final client = ref.read(apiClientProvider);
      await client.post<void>('/api/v1/debrid/auth/clear', body: {});
      ref.invalidate(debridAuthStatusProvider);
      ref.invalidate(debridAccountProvider);
      setState(() {
        _authed = false;
        _flowData = null;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final authAsync = ref.watch(debridAuthStatusProvider);
    final accountAsync = ref.watch(debridAccountProvider);

    return authAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0DB2E2),
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => Text(
        '$e',
        style: TextStyle(color: Colors.redAccent, fontSize: t.fontBody),
      ),
      data: (status) {
        final isAuthed = _authed || status.authenticated;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Real-Debrid', t),
            const SizedBox(height: 8),
            Text(
              'Link your Real-Debrid account to unlock cached torrent streaming.',
              style: TextStyle(color: Colors.white54, fontSize: t.fontSubtitle),
            ),
            const SizedBox(height: 24),
            if (isAuthed) ...[
              _ConnectedBox(
                provider: 'Real-Debrid',
                detail: accountAsync.asData?.value != null
                    ? '${accountAsync.asData!.value!.username} • Premium until ${accountAsync.asData!.value!.expiration}'
                    : null,
                onDisconnect: _disconnect,
                t: t,
                focusNode: widget.focusNode,
                onDirection: widget.onDirection,
              ),
            ] else if (_flowData != null)
              _DebridFlowBox(data: _flowData!, t: t)
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              _ActionButton(
                label: _starting ? 'Connecting…' : 'Connect Real-Debrid',
                icon: Icons.download_outlined,
                onTap: _starting ? null : _startFlow,
                t: t,
                focusNode: widget.focusNode,
                onDirection: widget.onDirection,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Section Panel — combines Trakt + Debrid (mirrors Tauri's auth section)
// ─────────────────────────────────────────────────────────────────────────────

class _AuthSectionPanel extends StatelessWidget {
  final WarpTokens t;
  final FocusNode traktFocusNode;
  final FocusNode debridFocusNode;
  final bool Function([_SettingsSection? section]) onFocusSidebar;
  final bool Function() onFocusRail;
  const _AuthSectionPanel({
    required this.t,
    required this.traktFocusNode,
    required this.debridFocusNode,
    required this.onFocusSidebar,
    required this.onFocusRail,
  });

  bool _traktDirection(BuildContext context, TraversalDirection direction) {
    if (direction == TraversalDirection.left) return onFocusSidebar();
    if (direction == TraversalDirection.right) return onFocusRail();
    if (direction == TraversalDirection.down) {
      _focusSettingsNode(context, debridFocusNode);
      return true;
    }
    if (direction == TraversalDirection.up) return true;
    return false;
  }

  bool _debridDirection(BuildContext context, TraversalDirection direction) {
    if (direction == TraversalDirection.left) return onFocusSidebar();
    if (direction == TraversalDirection.right) return onFocusRail();
    if (direction == TraversalDirection.up) {
      _focusSettingsNode(context, traktFocusNode);
      return true;
    }
    if (direction == TraversalDirection.down) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TraktPanel(
          t: t,
          focusNode: traktFocusNode,
          onDirection: (d) => _traktDirection(context, d),
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.white.withAlpha(18), height: 1),
        const SizedBox(height: 24),
        _DebridPanel(
          t: t,
          focusNode: debridFocusNode,
          onDirection: (d) => _debridDirection(context, d),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Catalog Panel — 6-slot widget configuration, mirrors CatalogConfigPanel.tsx
// ─────────────────────────────────────────────────────────────────────────────

class _CatalogPanel extends ConsumerStatefulWidget {
  final WarpTokens t;
  final FocusNode movieFocusNode;
  final FocusNode showFocusNode;
  final List<FocusNode> configureFocusNodes;
  final FocusNode saveFocusNode;
  final FocusNode refreshFocusNode;
  final bool Function([_SettingsSection? section]) onFocusSidebar;
  final bool Function() onFocusRail;
  const _CatalogPanel({
    required this.t,
    required this.movieFocusNode,
    required this.showFocusNode,
    required this.configureFocusNodes,
    required this.saveFocusNode,
    required this.refreshFocusNode,
    required this.onFocusSidebar,
    required this.onFocusRail,
  });

  @override
  ConsumerState<_CatalogPanel> createState() => _CatalogPanelState();
}

class _CatalogPanelState extends ConsumerState<_CatalogPanel> {
  String _mediaTab = 'movies'; // 'movies' | 'shows'
  bool _initialized = false;
  bool _saving = false;
  bool _savedOk = false;
  String? _saveError;

  // Local draft — edited locally, sent to backend only on Save
  List<WidgetConfig> _movies = List.of(kDefaultMovieWidgets);
  List<WidgetConfig> _shows = List.of(kDefaultShowWidgets);

  @override
  void initState() {
    super.initState();
    // Sync draft from server on first load (listen for data in build)
  }

  void _syncFromServer(WidgetsConfigResponse resp) {
    if (_initialized) return;
    _initialized = true;
    _movies = List.of(
      resp.movies.length == 6 ? resp.movies : kDefaultMovieWidgets,
    );
    _shows = List.of(resp.shows.length == 6 ? resp.shows : kDefaultShowWidgets);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _savedOk = false;
      _saveError = null;
    });
    try {
      await saveWidgets(ref.read(apiClientProvider), _movies, _shows);
      if (mounted) {
        setState(() {
          _saving = false;
          _savedOk = true;
        });
        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) setState(() => _savedOk = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = e.toString();
        });
      }
    }
  }

  void _refresh() {
    // Invalidate widget config so Movies/Shows pages pick up new catalogs
    ref.invalidate(widgetsConfigProvider);
    // Invalidate all catalog data so the ribbon content refreshes too
    ref.invalidate(catalogDataProvider);
    setState(() {
      _initialized = false;
    });
  }

  void _openConfigure(int idx) {
    final current = _mediaTab == 'movies' ? _movies[idx] : _shows[idx];
    showDialog<WidgetConfig>(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (_) => _ConfigureWidgetDialog(
        widgetIndex: idx,
        mediaType: _mediaTab,
        current: current,
        t: widget.t,
      ),
    ).then((selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && idx < widget.configureFocusNodes.length) {
          _focusSettingsNode(context, widget.configureFocusNodes[idx]);
        }
      });
      if (selected == null) return;
      setState(() {
        if (_mediaTab == 'movies') {
          _movies = List.of(_movies)..[idx] = selected;
        } else {
          _shows = List.of(_shows)..[idx] = selected;
        }
      });
    });
  }

  bool _toggleDirection(String tab, TraversalDirection direction) {
    if (direction == TraversalDirection.left && tab == 'movies') {
      return widget.onFocusSidebar();
    }
    if (direction == TraversalDirection.right && tab == 'movies') {
      _focusSettingsNode(context, widget.showFocusNode);
      return true;
    }
    if (direction == TraversalDirection.left && tab == 'shows') {
      _focusSettingsNode(context, widget.movieFocusNode);
      return true;
    }
    if (direction == TraversalDirection.right && tab == 'shows') {
      return widget.onFocusRail();
    }
    if (direction == TraversalDirection.down) {
      _focusSettingsNode(context, widget.configureFocusNodes.first);
      return true;
    }
    if (direction == TraversalDirection.up) return true;
    return false;
  }

  bool _configureDirection(int index, TraversalDirection direction) {
    if (direction == TraversalDirection.left) return widget.onFocusSidebar();
    if (direction == TraversalDirection.right) return widget.onFocusRail();
    if (direction == TraversalDirection.up) {
      final target = index == 0
          ? (_mediaTab == 'movies'
                ? widget.movieFocusNode
                : widget.showFocusNode)
          : widget.configureFocusNodes[index - 1];
      _focusSettingsNode(context, target);
      return true;
    }
    if (direction == TraversalDirection.down) {
      final target = index >= widget.configureFocusNodes.length - 1
          ? widget.saveFocusNode
          : widget.configureFocusNodes[index + 1];
      _focusSettingsNode(context, target);
      return true;
    }
    return false;
  }

  bool _saveDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.left) return widget.onFocusSidebar();
    if (direction == TraversalDirection.right) {
      _focusSettingsNode(context, widget.refreshFocusNode);
      return true;
    }
    if (direction == TraversalDirection.up) {
      _focusSettingsNode(context, widget.configureFocusNodes.last);
      return true;
    }
    if (direction == TraversalDirection.down) return true;
    return false;
  }

  bool _refreshDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.left) {
      _focusSettingsNode(context, widget.saveFocusNode);
      return true;
    }
    if (direction == TraversalDirection.right) return widget.onFocusRail();
    if (direction == TraversalDirection.up) {
      _focusSettingsNode(context, widget.configureFocusNodes.last);
      return true;
    }
    if (direction == TraversalDirection.down) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final configAsync = ref.watch(widgetsConfigProvider);

    // Sync draft once the server data arrives
    configAsync.whenData(_syncFromServer);

    final widgets = _mediaTab == 'movies' ? _movies : _shows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card container — "CATALOG CONFIGURATION"
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view_outlined,
                      color: const Color(0xFF0DB2E2),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'CATALOG CONFIGURATION',
                      style: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontSize: t.fontSubtitle,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withAlpha(13), height: 1),

              // Movies / Shows toggle — centered
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Center(
                  child: _MediaToggle(
                    selected: _mediaTab,
                    onChanged: (v) => setState(() => _mediaTab = v),
                    t: t,
                    movieFocusNode: widget.movieFocusNode,
                    showFocusNode: widget.showFocusNode,
                    onDirection: _toggleDirection,
                  ),
                ),
              ),

              // Loading / error state
              if (configAsync.isLoading && !_initialized)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0DB2E2),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                // 6 widget rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  itemCount: 6,
                  separatorBuilder: (context, i) => const SizedBox(height: 6),
                  itemBuilder: (_, idx) => _WidgetRow(
                    index: idx,
                    config: widgets[idx],
                    onConfigure: () => _openConfigure(idx),
                    t: t,
                    focusNode: idx < widget.configureFocusNodes.length
                        ? widget.configureFocusNodes[idx]
                        : null,
                    onDirection: (d) => _configureDirection(idx, d),
                  ),
                ),

              Divider(color: Colors.white.withAlpha(13), height: 1),

              // Action buttons: Save + Refresh Widgets
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  children: [
                    _ActionButton(
                      label: _saving
                          ? 'Saving…'
                          : (_savedOk ? 'Saved!' : 'Save'),
                      icon: _savedOk ? Icons.check : Icons.save_outlined,
                      onTap: _saving ? null : _save,
                      t: t,
                      accent: true,
                      focusNode: widget.saveFocusNode,
                      onDirection: _saveDirection,
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      label: 'Refresh Widgets',
                      icon: Icons.refresh_outlined,
                      onTap: _refresh,
                      t: t,
                      accent: false,
                      focusNode: widget.refreshFocusNode,
                      onDirection: _refreshDirection,
                    ),
                  ],
                ),
              ),

              // Save error
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    _saveError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Movies / Shows pill toggle ────────────────────────────────────────────────

class _MediaToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final WarpTokens t;
  final FocusNode movieFocusNode;
  final FocusNode showFocusNode;
  final bool Function(String tab, TraversalDirection direction) onDirection;
  const _MediaToggle({
    required this.selected,
    required this.onChanged,
    required this.t,
    required this.movieFocusNode,
    required this.showFocusNode,
    required this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['movies', 'shows'].map((tab) {
          final isActive = selected == tab;
          return WarpDpadButton(
            tokens: t,
            focusNode: tab == 'movies' ? movieFocusNode : showFocusNode,
            onDirection: (d) => onDirection(tab, d),
            onSelect: () => onChanged(tab),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            backgroundColor: isActive
                ? const Color(0xFF0DB2E2)
                : Colors.transparent,
            focusBackgroundColor: isActive
                ? const Color(0xFF0DB2E2)
                : Colors.white.withAlpha(20),
            borderColor: Colors.transparent,
            borderRadius: 8,
            child: Text(
              tab[0].toUpperCase() + tab.substring(1),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withAlpha(100),
                fontSize: t.fontBody,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Single widget row ─────────────────────────────────────────────────────────

class _WidgetRow extends StatelessWidget {
  final int index;
  final WidgetConfig config;
  final VoidCallback onConfigure;
  final WarpTokens t;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _WidgetRow({
    required this.index,
    required this.config,
    required this.onConfigure,
    required this.t,
    this.focusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    final providerLabel = config.provider == 'tmdb' ? 'TMDb' : 'Trakt';
    final categoryLabel = config.category.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0DB2E2).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF0DB2E2),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title + source label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: t.fontBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$providerLabel · $categoryLabel',
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: t.fontSubtitle,
                  ),
                ),
              ],
            ),
          ),

          // Configure button
          WarpDpadButton(
            tokens: t,
            focusNode: focusNode,
            onDirection: onDirection,
            onSelect: onConfigure,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            backgroundColor: Colors.white.withAlpha(8),
            borderColor: Colors.white.withAlpha(20),
            borderRadius: 8,
            child: Row(
              children: [
                Icon(Icons.tune, color: Colors.white.withAlpha(160), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Configure',
                  style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: t.fontSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Configure Widget Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CatalogDialogPosition {
  final int globalIndex;
  final int groupIndex;
  final int indexInGroup;
  final int row;
  final int column;

  const _CatalogDialogPosition({
    required this.globalIndex,
    required this.groupIndex,
    required this.indexInGroup,
    required this.row,
    required this.column,
  });
}

class _ConfigureWidgetDialog extends StatefulWidget {
  final int widgetIndex;
  final String mediaType; // 'movies' | 'shows'
  final WidgetConfig current;
  final WarpTokens t;

  const _ConfigureWidgetDialog({
    required this.widgetIndex,
    required this.mediaType,
    required this.current,
    required this.t,
  });

  @override
  State<_ConfigureWidgetDialog> createState() => _ConfigureWidgetDialogState();
}

class _ConfigureWidgetDialogState extends State<_ConfigureWidgetDialog>
    with WidgetsBindingObserver, ModalFocusRestore<_ConfigureWidgetDialog> {
  late String _providerTab; // 'tmdb' | 'trakt'
  final _closeFocusNode = FocusNode(debugLabel: 'SettingsCatalogDialogClose');
  final _tmdbFocusNode = FocusNode(debugLabel: 'SettingsCatalogDialogTmdb');
  final _traktFocusNode = FocusNode(debugLabel: 'SettingsCatalogDialogTrakt');
  final _dialogScrollController = ScrollController();
  final _dialogScrollRailFocusNode = FocusNode(
    debugLabel: 'SettingsCatalogDialogScrollRail',
  );
  final List<FocusNode> _cardFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _providerTab = widget.current.provider;
  }

  @override
  void dispose() {
    _closeFocusNode.dispose();
    _tmdbFocusNode.dispose();
    _traktFocusNode.dispose();
    _dialogScrollController.dispose();
    _dialogScrollRailFocusNode.dispose();
    for (final node in _cardFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncCardFocusNodes(int length) {
    while (_cardFocusNodes.length > length) {
      _cardFocusNodes.removeLast().dispose();
    }
    while (_cardFocusNodes.length < length) {
      final index = _cardFocusNodes.length;
      _cardFocusNodes.add(
        FocusNode(debugLabel: 'SettingsCatalogDialogCard-$index'),
      );
    }
  }

  List<CatalogDef> get _catalogs {
    if (_providerTab == 'tmdb') {
      return widget.mediaType == 'movies'
          ? kTmdbMovieCatalogs
          : kTmdbShowCatalogs;
    } else {
      return widget.mediaType == 'movies'
          ? kTraktMovieCatalogs
          : kTraktShowCatalogs;
    }
  }

  void _select(CatalogDef def) {
    Navigator.of(context).pop(
      WidgetConfig(provider: _providerTab, category: def.id, title: def.label),
    );
  }

  List<_CatalogDialogPosition> _positionsFor(
    Map<CatalogGroup, List<CatalogDef>> groups,
  ) {
    final positions = <_CatalogDialogPosition>[];
    var groupIndex = 0;
    for (final entry in groups.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final def = entry.value[i];
        final globalIndex = _catalogs.indexWhere(
          (catalog) => catalog.id == def.id,
        );
        if (globalIndex < 0) continue;
        positions.add(
          _CatalogDialogPosition(
            globalIndex: globalIndex,
            groupIndex: groupIndex,
            indexInGroup: i,
            row: i ~/ 2,
            column: i % 2,
          ),
        );
      }
      groupIndex += 1;
    }
    return positions;
  }

  bool _focusCatalogIndex(int index) {
    if (index < 0 || index >= _cardFocusNodes.length) return false;
    return _focusSettingsNode(context, _cardFocusNodes[index]);
  }

  _CatalogDialogPosition? _positionForIndex(
    List<_CatalogDialogPosition> positions,
    int index,
  ) {
    for (final position in positions) {
      if (position.globalIndex == index) return position;
    }
    return null;
  }

  _CatalogDialogPosition? _positionAt(
    List<_CatalogDialogPosition> positions, {
    required int groupIndex,
    required int row,
    required int column,
  }) {
    for (final position in positions) {
      if (position.groupIndex == groupIndex &&
          position.row == row &&
          position.column == column) {
        return position;
      }
    }
    return null;
  }

  _CatalogDialogPosition? _firstInNextGroup(
    List<_CatalogDialogPosition> positions,
    int groupIndex,
    int column,
  ) {
    final maxGroup = positions.fold<int>(
      -1,
      (max, position) => position.groupIndex > max ? position.groupIndex : max,
    );
    for (var group = groupIndex + 1; group <= maxGroup; group++) {
      final sameColumn = _positionAt(
        positions,
        groupIndex: group,
        row: 0,
        column: column,
      );
      if (sameColumn != null) return sameColumn;
      final fallback = _positionAt(
        positions,
        groupIndex: group,
        row: 0,
        column: 0,
      );
      if (fallback != null) return fallback;
    }
    return null;
  }

  _CatalogDialogPosition? _lastInPreviousGroup(
    List<_CatalogDialogPosition> positions,
    int groupIndex,
    int column,
  ) {
    for (var group = groupIndex - 1; group >= 0; group--) {
      final groupItems = positions
          .where((position) => position.groupIndex == group)
          .toList();
      if (groupItems.isEmpty) continue;
      final lastRow = groupItems.fold<int>(
        0,
        (max, position) => position.row > max ? position.row : max,
      );
      final sameColumn = _positionAt(
        positions,
        groupIndex: group,
        row: lastRow,
        column: column,
      );
      if (sameColumn != null) return sameColumn;
      final fallback = _positionAt(
        positions,
        groupIndex: group,
        row: lastRow,
        column: 0,
      );
      if (fallback != null) return fallback;
    }
    return null;
  }

  void _scrollDialog(double direction) {
    if (!_dialogScrollController.hasClients) return;
    final position = _dialogScrollController.position;
    final next =
        (position.pixels + position.viewportDimension * 0.85 * direction).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    position.animateTo(
      next,
      duration: _settingsScrollDuration(context),
      curve: Curves.easeOutCubic,
    );
  }

  bool _focusNearestSecondColumnFromRail(
    List<_CatalogDialogPosition> positions,
  ) {
    final railContext = _dialogScrollRailFocusNode.context;
    final railBox = railContext?.findRenderObject();
    final railCenter = railBox is RenderBox && railBox.hasSize
        ? railBox.localToGlobal(railBox.size.center(Offset.zero)).dy
        : MediaQuery.sizeOf(context).height / 2;

    _CatalogDialogPosition? best;
    var bestDistance = double.infinity;
    for (final position in positions.where(
      (position) => position.column == 1,
    )) {
      if (position.globalIndex >= _cardFocusNodes.length) continue;
      final nodeContext = _cardFocusNodes[position.globalIndex].context;
      if (nodeContext == null) continue;
      final box = nodeContext.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      final distance = (center.dy - railCenter).abs();
      if (distance < bestDistance) {
        best = position;
        bestDistance = distance;
      }
    }
    if (best != null) return _focusCatalogIndex(best.globalIndex);
    return positions.isEmpty
        ? true
        : _focusCatalogIndex(positions.last.globalIndex);
  }

  bool _dialogScrollRailDirection(
    List<_CatalogDialogPosition> positions,
    TraversalDirection direction,
  ) {
    if (direction == TraversalDirection.up) {
      _scrollDialog(-1);
      return true;
    }
    if (direction == TraversalDirection.down) {
      _scrollDialog(1);
      return true;
    }
    if (direction == TraversalDirection.left) {
      return _focusNearestSecondColumnFromRail(positions);
    }
    if (direction == TraversalDirection.right) return true;
    return false;
  }

  bool _closeDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.down ||
        direction == TraversalDirection.left) {
      _focusSettingsNode(
        context,
        _providerTab == 'tmdb' ? _tmdbFocusNode : _traktFocusNode,
      );
      return true;
    }
    return true;
  }

  bool _providerDirection(
    String tab,
    List<_CatalogDialogPosition> positions,
    TraversalDirection direction,
  ) {
    if (direction == TraversalDirection.up) {
      _focusSettingsNode(context, _closeFocusNode);
      return true;
    }
    if (direction == TraversalDirection.down) {
      final selectedPositionIndex = positions.indexWhere(
        (position) =>
            _catalogs[position.globalIndex].id == widget.current.category,
      );
      final index = selectedPositionIndex >= 0
          ? positions[selectedPositionIndex].globalIndex
          : (positions.isEmpty ? -1 : positions.first.globalIndex);
      _focusCatalogIndex(index);
      return true;
    }
    if (direction == TraversalDirection.left && tab == 'trakt') {
      _focusSettingsNode(context, _tmdbFocusNode);
      return true;
    }
    if (direction == TraversalDirection.right && tab == 'tmdb') {
      _focusSettingsNode(context, _traktFocusNode);
      return true;
    }
    if (direction == TraversalDirection.right && tab == 'trakt') {
      _focusSettingsNode(context, _dialogScrollRailFocusNode);
      return true;
    }
    return true;
  }

  bool _cardDirection(
    int index,
    List<_CatalogDialogPosition> positions,
    TraversalDirection direction,
  ) {
    final current = _positionForIndex(positions, index);
    if (current == null) return true;

    if (direction == TraversalDirection.up) {
      final sameGroupTarget = _positionAt(
        positions,
        groupIndex: current.groupIndex,
        row: current.row - 1,
        column: current.column,
      );
      final target =
          sameGroupTarget ??
          (current.row == 0
              ? _lastInPreviousGroup(
                  positions,
                  current.groupIndex,
                  current.column,
                )
              : null);
      if (target != null) {
        return _focusCatalogIndex(target.globalIndex);
      }
      _focusSettingsNode(
        context,
        _providerTab == 'tmdb' ? _tmdbFocusNode : _traktFocusNode,
      );
      return true;
    }

    if (direction == TraversalDirection.down) {
      final sameGroupTarget = _positionAt(
        positions,
        groupIndex: current.groupIndex,
        row: current.row + 1,
        column: current.column,
      );
      final target =
          sameGroupTarget ??
          _firstInNextGroup(positions, current.groupIndex, current.column);
      if (target != null) _focusCatalogIndex(target.globalIndex);
      return true;
    }

    if (direction == TraversalDirection.left) {
      final target = current.column == 1
          ? _positionAt(
              positions,
              groupIndex: current.groupIndex,
              row: current.row,
              column: 0,
            )
          : null;
      if (target != null) _focusCatalogIndex(target.globalIndex);
      return true;
    }

    if (direction == TraversalDirection.right) {
      final target = current.column == 0
          ? _positionAt(
              positions,
              groupIndex: current.groupIndex,
              row: current.row,
              column: 1,
            )
          : null;
      if (target != null) {
        _focusCatalogIndex(target.globalIndex);
      } else {
        _focusSettingsNode(context, _dialogScrollRailFocusNode);
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final modalScale = MediaQuery.textScalerOf(context).scale(1);
    final groups = _groupedCatalogs();
    final positions = _positionsFor(groups);
    _syncCardFocusNodes(_catalogs.length);

    return Dialog(
      backgroundColor: Colors.transparent,
      // Matches Tauri: clamp(520px, 54vw, 760px) — centre with generous vertical room
      insetPadding: EdgeInsets.symmetric(
        horizontal: ((size.width - 760) / 2).clamp(24.0, double.infinity),
        vertical: (size.height * 0.06).clamp(32.0, 60.0),
      ),
      child: TvModalChromeScale(
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).pop(),
            const SingleActivator(LogicalKeyboardKey.goBack): () =>
                Navigator.of(context).pop(),
            const SingleActivator(LogicalKeyboardKey.browserBack): () =>
                Navigator.of(context).pop(),
          },
          child: DpadRegion(
            memoryKey: 'settings-catalog-config-dialog',
            horizontalEdge: DpadEdgeBehavior.stop,
            verticalEdge: DpadEdgeBehavior.stop,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 760,
                maxHeight: size.height * 0.88 / modalScale,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(180),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dialog header
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 20, 16, 18),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withAlpha(18)),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0DB2E2), Color(0xFF0A8FBA)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Configure Widget ${widget.widgetIndex + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${widget.mediaType == 'movies' ? 'Movie' : 'Show'} catalog — click any source to assign it',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(180),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          WarpDpadButton(
                            tokens: widget.t,
                            focusNode: _closeFocusNode,
                            onDirection: _closeDirection,
                            onSelect: () => Navigator.of(context).pop(),
                            padding: const EdgeInsets.all(6),
                            backgroundColor: Colors.white.withAlpha(20),
                            borderColor: Colors.transparent,
                            focusBackgroundColor: const Color(0x330DB2E2),
                            focusBorderColor: Colors.white,
                            borderRadius: 6,
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // TMDb / Trakt tab toggle
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children:
                            ['tmdb', 'trakt']
                                .map((tab) {
                                  final isActive = _providerTab == tab;
                                  final label = tab == 'tmdb'
                                      ? 'TMDb Catalogs'
                                      : 'Trakt Catalogs';
                                  return Expanded(
                                    child: WarpDpadButton(
                                      tokens: widget.t,
                                      focusNode: tab == 'tmdb'
                                          ? _tmdbFocusNode
                                          : _traktFocusNode,
                                      autofocus: tab == _providerTab,
                                      entry: tab == _providerTab,
                                      onDirection: (d) =>
                                          _providerDirection(tab, positions, d),
                                      onSelect: () =>
                                          setState(() => _providerTab = tab),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      backgroundColor: isActive
                                          ? const Color(
                                              0xFF0DB2E2,
                                            ).withAlpha(30)
                                          : Colors.white.withAlpha(8),
                                      borderColor: isActive
                                          ? const Color(
                                              0xFF0DB2E2,
                                            ).withAlpha(100)
                                          : Colors.white.withAlpha(15),
                                      borderRadius: 10,
                                      child: Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isActive
                                              ? const Color(0xFF0DB2E2)
                                              : Colors.white.withAlpha(120),
                                          fontSize: 13,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  );
                                })
                                .expand((w) => [w, const SizedBox(width: 8)])
                                .toList()
                              ..removeLast(),
                      ),
                    ),

                    // Grouped catalog grid — scrollable
                    Flexible(
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _dialogScrollController,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: groups.entries.map((entry) {
                                  final group = entry.key;
                                  final items = entry.value;
                                  final label =
                                      kCatalogGroupLabels[group] ??
                                      group.name.toUpperCase();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Group header
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: Text(
                                            '$label(${items.length})',
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(
                                                100,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                        // 2-column grid
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                crossAxisSpacing: 8,
                                                mainAxisSpacing: 8,
                                                childAspectRatio: 5.5,
                                              ),
                                          itemCount: items.length,
                                          itemBuilder: (_, i) {
                                            final globalIndex = _catalogs
                                                .indexWhere(
                                                  (def) =>
                                                      def.id == items[i].id,
                                                );
                                            final safeIndex = globalIndex < 0
                                                ? 0
                                                : globalIndex;
                                            return _CatalogCard(
                                              def: items[i],
                                              isSelected:
                                                  widget.current.provider ==
                                                      _providerTab &&
                                                  widget.current.category ==
                                                      items[i].id,
                                              onTap: () => _select(items[i]),
                                              t: widget.t,
                                              focusNode:
                                                  safeIndex <
                                                      _cardFocusNodes.length
                                                  ? _cardFocusNodes[safeIndex]
                                                  : null,
                                              onDirection: (d) =>
                                                  _cardDirection(
                                                    safeIndex,
                                                    positions,
                                                    d,
                                                  ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          _SettingsScrollRail(
                            focusNode: _dialogScrollRailFocusNode,
                            tokens: widget.t,
                            onDirection: (d) =>
                                _dialogScrollRailDirection(positions, d),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<CatalogGroup, List<CatalogDef>> _groupedCatalogs() {
    final result = <CatalogGroup, List<CatalogDef>>{};
    for (final def in _catalogs) {
      result.putIfAbsent(def.group, () => []).add(def);
    }
    return result;
  }
}

// ── Single catalog source card inside the dialog ──────────────────────────────

class _CatalogCard extends StatelessWidget {
  final CatalogDef def;
  final bool isSelected;
  final VoidCallback onTap;
  final WarpTokens t;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _CatalogCard({
    required this.def,
    required this.isSelected,
    required this.onTap,
    required this.t,
    this.focusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    return WarpDpadButton(
      tokens: t,
      focusNode: focusNode,
      onDirection: onDirection,
      onSelect: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: isSelected
          ? const Color(0xFF0DB2E2).withAlpha(30)
          : Colors.white.withAlpha(8),
      borderColor: isSelected
          ? const Color(0xFF0DB2E2).withAlpha(120)
          : Colors.white.withAlpha(15),
      borderRadius: 10,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isSelected)
              const Positioned(
                top: -2,
                right: -2,
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                left: isSelected ? 16 : 0,
                right: isSelected ? 18 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    def.label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0DB2E2)
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    def.description,
                    style: TextStyle(
                      color: Colors.white.withAlpha(100),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// General Panel (was About)
// ─────────────────────────────────────────────────────────────────────────────

class _GeneralPanel extends StatelessWidget {
  final WarpTokens t;
  const _GeneralPanel({required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('General', t),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Warp MediaCenter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: t.fontHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Flutter client (macOS/Linux/Windows/Android TV)',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: t.fontSubtitle,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Version', value: 'v1.0.0', t: t),
              _InfoRow(label: 'Backend', value: 'FastAPI + Python', t: t),
              _InfoRow(label: 'Video', value: 'libmpv via media_kit', t: t),
              _InfoRow(
                label: 'Auth',
                value: 'Device flow (Trakt + RealDebrid)',
                t: t,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final WarpTokens t;
  const _SectionTitle(this.text, this.t);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: t.fontSection,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ConnectedBox extends StatelessWidget {
  final String provider;
  final String? detail;
  final VoidCallback onDisconnect;
  final WarpTokens t;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _ConnectedBox({
    required this.provider,
    required this.detail,
    required this.onDisconnect,
    required this.t,
    this.focusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF10B981),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected to $provider',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: t.fontBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: t.fontSubtitle,
                    ),
                  ),
              ],
            ),
          ),
          WarpDpadButton(
            tokens: t,
            focusNode: focusNode,
            onDirection: onDirection,
            onSelect: onDisconnect,
            backgroundColor: Colors.redAccent.withAlpha(16),
            focusBackgroundColor: Colors.redAccent.withAlpha(32),
            borderColor: Colors.redAccent.withAlpha(50),
            focusBorderColor: Colors.redAccent,
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceFlowBox extends StatelessWidget {
  final TraktAuthStartResponse flow;
  final WarpTokens t;

  const _DeviceFlowBox({required this.flow, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your Trakt account:',
            style: TextStyle(color: Colors.white70, fontSize: t.fontBody),
          ),
          const SizedBox(height: 14),
          Text(
            '1. Visit:',
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 4),
          SelectableText(
            flow.verificationUrl,
            style: const TextStyle(color: Color(0xFF0DB2E2), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            '2. Enter code:',
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0DB2E2).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              flow.userCode,
              style: const TextStyle(
                color: Color(0xFF0DB2E2),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 2,
                height: 2,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF0DB2E2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Waiting for authorisation…',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: t.fontSubtitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebridFlowBox extends StatelessWidget {
  final Map<String, dynamic> data;
  final WarpTokens t;

  const _DebridFlowBox({required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    final verUrl = data['verification_url'] as String? ?? '';
    final code =
        data['user_code'] as String? ?? data['device_code'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your Real-Debrid account:',
            style: TextStyle(color: Colors.white70, fontSize: t.fontBody),
          ),
          const SizedBox(height: 14),
          Text(
            '1. Visit:',
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 4),
          SelectableText(
            verUrl,
            style: const TextStyle(color: Color(0xFF0DB2E2), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            '2. Enter code:',
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0DB2E2).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Color(0xFF0DB2E2),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 2,
                height: 2,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF0DB2E2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Waiting for authorisation…',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: t.fontSubtitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final WarpTokens t;
  final bool accent;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.t,
    this.accent = true,
    this.focusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final fg = disabled
        ? Colors.white30
        : (accent ? const Color(0xFF0DB2E2) : Colors.white.withAlpha(180));
    final bg = disabled
        ? Colors.white.withAlpha(10)
        : (accent
              ? const Color(0xFF0DB2E2).withAlpha(30)
              : Colors.white.withAlpha(10));
    final border = disabled
        ? Colors.white.withAlpha(20)
        : (accent
              ? const Color(0xFF0DB2E2).withAlpha(80)
              : Colors.white.withAlpha(30));

    return WarpDpadButton(
      tokens: t,
      focusNode: focusNode,
      onDirection: onDirection,
      enabled: !disabled,
      onSelect: onTap ?? () {},
      backgroundColor: bg,
      borderColor: border,
      focusBackgroundColor: accent
          ? const Color(0xFF0DB2E2).withAlpha(45)
          : Colors.white.withAlpha(18),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: t.fontBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final WarpTokens t;

  const _InfoRow({required this.label, required this.value, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white70, fontSize: t.fontSubtitle),
          ),
        ],
      ),
    );
  }
}
