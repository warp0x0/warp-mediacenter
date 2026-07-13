import 'dart:async';
import 'dart:io';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' show Options;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../navigation/tab_bar_focus_registry.dart';
import '../theme/warp_theme.dart';
import '../theme/warp_tokens.dart';
import '../widgets/layout/backdrop_layer.dart';
import '../widgets/shared/warp_accent_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PowerPage — mirrors Tauri PowerTab.tsx
// ─────────────────────────────────────────────────────────────────────────────

class PowerPage extends ConsumerStatefulWidget {
  const PowerPage({super.key});

  @override
  ConsumerState<PowerPage> createState() => _PowerPageState();
}

class _PowerPageState extends ConsumerState<PowerPage>
    with WidgetsBindingObserver {
  final _sessionStart = DateTime.now();
  Timer? _uptimeTimer;
  Duration _uptime = Duration.zero;
  FocusNode? _lastPowerFocus;
  bool _appActive = true;

  bool _apiRunning = false;
  bool _apiChecking = true;
  Timer? _healthTimer;

  String _torrentApiUrl = 'http://localhost:8009';
  bool _torrentRunning = false;
  bool _torrentChecking = true;

  // Shared across all three action buttons: Up from ANY of them focuses
  // this page's own tab pill.
  bool _upToTab(TraversalDirection d) {
    if (d != TraversalDirection.up) return false;
    final tab = ref.read(tabBarFocusRegistryProvider).forRoute('/power');
    if (tab == null) return false;
    Dpad.of(context).requestFocus(tab);
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_rememberPowerFocus);
    // Clear backdrop — Power page uses an opaque dark background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(backdropProvider.notifier).clear();
    });
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _uptime = DateTime.now().difference(_sessionStart));
      }
    });
    _checkHealth();
    _healthTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkHealth();
      _checkTorrentHealth();
    });
    _loadSettings();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_rememberPowerFocus);
    WidgetsBinding.instance.removeObserver(this);
    _uptimeTimer?.cancel();
    _healthTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final node = _lastPowerFocus;
        if (mounted && node?.context != null) node?.requestFocus();
      });
    }
  }

  void _rememberPowerFocus() {
    if (!_appActive || !mounted) {
      return;
    }
    final node = FocusManager.instance.primaryFocus;
    final nodeContext = node?.context;
    if (node == null || node is FocusScopeNode || nodeContext == null) {
      return;
    }
    final pageBox = context.findRenderObject();
    final focusBox = nodeContext.findRenderObject();
    if (pageBox == null || focusBox == null) {
      return;
    }
    var current = focusBox.parent;
    while (current != null) {
      if (identical(current, pageBox)) {
        _lastPowerFocus = node;
        return;
      }
      current = current.parent;
    }
  }

  Future<void> _checkHealth() async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.get<Map<String, dynamic>>('/api/v1/health');
      if (mounted) {
        setState(() {
          _apiRunning = resp['status'] == 'ok' || resp['status'] == 'degraded';
          _apiChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _apiRunning = false;
          _apiChecking = false;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.get<Map<String, dynamic>>('/api/v1/settings');
      final settings = resp['settings'] as Map<String, dynamic>?;
      final url = settings?['torrent_api_url'] as String?;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _torrentApiUrl = url);
      }
    } catch (_) {}
    // Check torrent health after URL is resolved
    _checkTorrentHealth();
  }

  Future<void> _checkTorrentHealth() async {
    final url = _torrentApiUrl;
    try {
      final dio = ref.read(apiClientProvider).dio;
      final resp = await dio.get<dynamic>(
        '$url/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (mounted) {
        setState(() {
          _torrentRunning =
              resp.statusCode != null &&
              resp.statusCode! >= 200 &&
              resp.statusCode! < 300;
          _torrentChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _torrentRunning = false;
          _torrentChecking = false;
        });
      }
    }
  }

  String _formatUptime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _openApiDocs() async {
    final baseUrl = ref.read(apiBaseUrlProvider);
    final uri = Uri.parse('$baseUrl/docs');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open browser')));
      }
    }
  }

  Future<void> _clearCache() async {
    await DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _quitApp() => exit(0);

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final baseUrl = ref.watch(apiBaseUrlProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: t.tabBarHeight),
                _HeaderCard(
                  uptime: _formatUptime(_uptime),
                  apiRunning: _apiRunning,
                  apiChecking: _apiChecking,
                  t: t,
                ),
                SizedBox(height: t.cardGap * 2),
                _TwoColumnRow(
                  left: _ServerStatusCard(
                    apiRunning: _apiRunning,
                    apiChecking: _apiChecking,
                    torrentRunning: _torrentRunning,
                    torrentChecking: _torrentChecking,
                    baseUrl: baseUrl,
                    t: t,
                  ),
                  right: _SystemInfoCard(
                    baseUrl: baseUrl,
                    torrentApiUrl: _torrentApiUrl,
                    torrentRunning: _torrentRunning,
                    torrentChecking: _torrentChecking,
                    uptime: _formatUptime(_uptime),
                    t: t,
                  ),
                ),
                SizedBox(height: t.cardGap * 2),
                _ActionsCard(
                  onOpenDocs: _openApiDocs,
                  onClearCache: _clearCache,
                  onQuit: _quitApp,
                  onDirection: _upToTab,
                  t: t,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header card
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.uptime,
    required this.apiRunning,
    required this.apiChecking,
    required this.t,
  });

  final String uptime;
  final bool apiRunning;
  final bool apiChecking;
  final WarpTokens t;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return _Card(
      t: t,
      child: Row(
        children: [
          Container(
            width: scaler.scale(56),
            height: scaler.scale(56),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0DB2E2).withAlpha(30),
              border: Border.all(
                color: const Color(0xFF0DB2E2).withAlpha(80),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.power_settings_new,
              color: const Color(0xFF0DB2E2),
              size: scaler.scale(28),
            ),
          ),
          SizedBox(width: scaler.scale(20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warp Media Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: t.fontSection,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v0.1.0 · Power & System',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: t.fontSubtitle,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _HeaderStat(
                icon: apiChecking
                    ? null
                    : Icon(
                        Icons.circle,
                        size: 8,
                        color: apiRunning
                            ? const Color(0xFF4ADE80)
                            : Colors.red,
                      ),
                label: apiChecking ? '…' : (apiRunning ? 'Running' : 'Offline'),
                sublabel: 'API Server',
                valueColor: apiChecking
                    ? Colors.white54
                    : (apiRunning ? const Color(0xFF4ADE80) : Colors.red),
                t: t,
              ),
              const SizedBox(width: 32),
              _HeaderStat(
                label: uptime,
                sublabel: 'Session uptime',
                valueColor: Colors.white,
                t: t,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.sublabel,
    required this.valueColor,
    required this.t,
    this.icon,
  });

  final Widget? icon;
  final String label;
  final String sublabel;
  final Color valueColor;
  final WarpTokens t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 5)],
            Text(
              label,
              style: TextStyle(
                color: valueColor,
                fontSize: t.fontBody,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Text(
          sublabel,
          style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle - 1),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Two-column row
// ─────────────────────────────────────────────────────────────────────────────

class _TwoColumnRow extends StatelessWidget {
  const _TwoColumnRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Server Status card
// ─────────────────────────────────────────────────────────────────────────────

class _ServerStatusCard extends StatelessWidget {
  const _ServerStatusCard({
    required this.apiRunning,
    required this.apiChecking,
    required this.torrentRunning,
    required this.torrentChecking,
    required this.baseUrl,
    required this.t,
  });

  final bool apiRunning;
  final bool apiChecking;
  final bool torrentRunning;
  final bool torrentChecking;
  final String baseUrl;
  final WarpTokens t;

  @override
  Widget build(BuildContext context) {
    return _Card(
      t: t,
      topAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.dns_outlined, label: 'SERVER STATUS', t: t),
          const SizedBox(height: 16),
          _StatusRow(
            name: 'API Server',
            detail: baseUrl,
            status: apiChecking
                ? 'Checking…'
                : (apiRunning ? 'Running' : 'Offline'),
            statusColor: apiChecking
                ? Colors.white38
                : (apiRunning ? const Color(0xFF4ADE80) : Colors.red),
            dotColor: apiChecking
                ? Colors.white38
                : (apiRunning ? const Color(0xFF4ADE80) : Colors.red),
            t: t,
          ),
          const SizedBox(height: 12),
          const _Divider(),
          const SizedBox(height: 12),
          _StatusRow(
            name: 'Torrent-API-Py',
            detail: 'Sub-process',
            status: torrentChecking
                ? 'Checking…'
                : (torrentRunning ? 'Healthy' : 'Offline'),
            statusColor: torrentChecking
                ? Colors.white38
                : (torrentRunning ? const Color(0xFF4ADE80) : Colors.red),
            dotColor: torrentChecking
                ? Colors.white38
                : (torrentRunning ? const Color(0xFF4ADE80) : Colors.red),
            t: t,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.name,
    required this.detail,
    required this.status,
    required this.statusColor,
    required this.dotColor,
    required this.t,
  });

  final String name;
  final String detail;
  final String status;
  final Color statusColor;
  final Color dotColor;
  final WarpTokens t;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return Row(
      children: [
        Icon(Icons.circle, size: scaler.scale(7), color: dotColor),
        SizedBox(width: scaler.scale(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: t.fontBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: t.fontSubtitle,
                ),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontSize: t.fontSubtitle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// System Information card
// ─────────────────────────────────────────────────────────────────────────────

class _SystemInfoCard extends StatelessWidget {
  const _SystemInfoCard({
    required this.baseUrl,
    required this.torrentApiUrl,
    required this.torrentRunning,
    required this.torrentChecking,
    required this.uptime,
    required this.t,
  });

  final String baseUrl;
  final String torrentApiUrl;
  final bool torrentRunning;
  final bool torrentChecking;
  final String uptime;
  final WarpTokens t;

  @override
  Widget build(BuildContext context) {
    final torrentStatus = torrentChecking
        ? 'Checking…'
        : (torrentRunning ? 'Healthy' : 'Offline');
    final torrentStatusColor = torrentChecking
        ? Colors.white38
        : (torrentRunning ? const Color(0xFF4ADE80) : Colors.red);

    return _Card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.info_outline,
            label: 'SYSTEM INFORMATION',
            t: t,
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'API Server', value: baseUrl, t: t),
          const SizedBox(height: 10),
          const _Divider(),
          const SizedBox(height: 10),
          _InfoRow(label: 'Torrent-API-Py', value: torrentApiUrl, t: t),
          const SizedBox(height: 10),
          const _Divider(),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Torrent Status',
            value: torrentStatus,
            valueColor: torrentStatusColor,
            t: t,
          ),
          const SizedBox(height: 10),
          const _Divider(),
          const SizedBox(height: 10),
          _InfoRow(label: 'Application', value: 'Warp v0.1.0', t: t),
          const SizedBox(height: 10),
          const _Divider(),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Session uptime',
            value: uptime,
            monospace: true,
            t: t,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.t,
    this.monospace = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool monospace;
  final Color? valueColor;
  final WarpTokens t;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return Row(
      children: [
        SizedBox(
          width: scaler.scale(120),
          child: Text(
            label,
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white70,
              fontSize: t.fontSubtitle,
              fontWeight: FontWeight.w500,
              fontFeatures: monospace
                  ? const [FontFeature.tabularFigures()]
                  : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Actions card
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.onOpenDocs,
    required this.onClearCache,
    required this.onQuit,
    required this.onDirection,
    required this.t,
  });

  final VoidCallback onOpenDocs;
  final VoidCallback onClearCache;
  final VoidCallback onQuit;
  final DpadDirectionCallback onDirection;
  final WarpTokens t;

  @override
  Widget build(BuildContext context) {
    return _Card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.terminal_outlined, label: 'ACTIONS', t: t),
          const SizedBox(height: 20),
          DpadRegion(
            memoryKey: 'power-actions',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                WarpAccentButton(
                  label: 'Open API Docs',
                  icon: Icons.open_in_new,
                  accentColor: WarpColors.accent,
                  fontSize: t.fontSubtitle,
                  paddingHorizontal: 20,
                  paddingVertical: 12,
                  onDirection: onDirection,
                  onSelect: onOpenDocs,
                ),
                WarpAccentButton(
                  label: 'Clear Cache',
                  icon: Icons.delete_outline,
                  accentColor: WarpColors.accent,
                  fontSize: t.fontSubtitle,
                  paddingHorizontal: 20,
                  paddingVertical: 12,
                  onDirection: onDirection,
                  onSelect: onClearCache,
                ),
                WarpAccentButton(
                  label: 'Quit App',
                  icon: Icons.power_settings_new,
                  accentColor: WarpColors.danger,
                  fontSize: t.fontSubtitle,
                  paddingHorizontal: 20,
                  paddingVertical: 12,
                  autofocus: true,
                  onDirection: onDirection,
                  onSelect: onQuit,
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
// Shared card widgets
// ─────────────────────────────────────────────────────────────────────────────

// Flutter requires all Border sides to have the same color when borderRadius
// is set. For the Server Status card's cyan top accent, we use a uniform outer
// border + a Positioned overlay inside ClipRRect.
class _Card extends StatelessWidget {
  const _Card({required this.child, required this.t, this.topAccent = false});

  final Widget child;
  final WarpTokens t;
  final bool topAccent;

  static const _accentColor = Color(0xFF0DB2E2);
  static const _borderColor = Color(0x12FFFFFF); // white ~7%

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withAlpha(8),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                scaler.scale(24),
                scaler.scale(
                  topAccent ? 26 : 24,
                ), // extra top padding for accent line
                scaler.scale(24),
                scaler.scale(24),
              ),
              child: child,
            ),
            if (topAccent)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 2,
                  child: ColoredBox(color: _accentColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.label, required this.t});

  final IconData icon;
  final String label;
  final WarpTokens t;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return Row(
      children: [
        Icon(icon, size: scaler.scale(14), color: const Color(0xFF0DB2E2)),
        SizedBox(width: scaler.scale(8)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: t.fontSubtitle - 1,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white.withAlpha(12));
  }
}
