import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/api_client.dart';
import '../../models/library.dart';
import '../../providers/library_provider.dart';
import '../../theme/warp_tokens.dart';
import '../shared/dpad_controls.dart';
import '../shared/modal_focus_restore.dart';
import 'file_browser_modal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScanDialog — dual-panel library scanner (Movies | Shows)
// Matches React ScanDialog: folder selection, scan now, live logs, cancel.
// POST /api/v1/settings/library/scan { paths: [folder] }
// GET  /api/v1/settings/library/scan/status → ScanStatusResponse
// POST /api/v1/settings/library/scan/cancel
// ─────────────────────────────────────────────────────────────────────────────

enum _ScanPanel { movies, shows }

class ScanDialog extends ConsumerStatefulWidget {
  const ScanDialog({super.key});

  @override
  ConsumerState<ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends ConsumerState<ScanDialog>
    with WidgetsBindingObserver, ModalFocusRestore<ScanDialog> {
  String? _moviesFolder;
  String? _showsFolder;
  _ScanPanel? _activePanel;
  bool _scanning = false;
  ScanStatusResponse? _status;
  final List<String> _logs = [];
  Timer? _pollTimer;
  String? _error;
  final _logScroll = ScrollController();

  @override
  void dispose() {
    _pollTimer?.cancel();
    _logScroll.dispose();
    super.dispose();
  }

  Future<void> _selectFolder(_ScanPanel panel) async {
    final path = await FileBrowserModal.show(context, dirsOnly: true);
    if (path == null || !mounted) return;
    setState(() {
      if (panel == _ScanPanel.movies) {
        _moviesFolder = path;
      } else {
        _showsFolder = path;
      }
    });
  }

  Future<void> _startScan(_ScanPanel panel) async {
    final folder = panel == _ScanPanel.movies ? _moviesFolder : _showsFolder;
    if (folder == null) return;

    setState(() {
      _scanning = true;
      _activePanel = panel;
      _status = null;
      _logs.clear();
      _error = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      await client.post<void>(
        '/api/v1/settings/library/scan',
        body: {
          'paths': [folder],
        },
      );
      _pollTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _pollStatus(),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _pollStatus() async {
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.get<Map<String, dynamic>>(
        '/api/v1/settings/library/scan/status',
      );
      final status = ScanStatusResponse.fromJson(raw);

      if (!mounted) return;
      setState(() {
        _status = status;
        _logs
          ..clear()
          ..addAll(status.logs);
        if (!status.running) {
          _scanning = false;
          _pollTimer?.cancel();
        }
      });

      // Auto-scroll log to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients && _logScroll.position.maxScrollExtent > 0) {
          _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
        }
      });
    } catch (_) {}
  }

  Future<void> _cancelScan() async {
    _pollTimer?.cancel();
    try {
      final client = ref.read(apiClientProvider);
      await client.post<void>('/api/v1/settings/library/scan/cancel', body: {});
    } catch (_) {}
    if (mounted) {
      setState(() {
        _scanning = false;
        _status = null;
        _logs.clear();
      });
    }
  }

  void _addToLibrary() {
    ref.invalidate(libraryMoviesProvider);
    ref.invalidate(libraryShowsProvider);
    ref.invalidate(libraryMoviesAzProvider);
    ref.invalidate(libraryShowsAzProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final w = (size.width * 0.90).clamp(560.0, 900.0);
    final isDone = _status?.running == false && _status != null;

    return Dialog(
      backgroundColor: Colors.transparent,
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
          memoryKey: 'modal-scan',
          horizontalEdge: DpadEdgeBehavior.stop,
          verticalEdge: DpadEdgeBehavior.stop,
          child: Center(
            child: Container(
              width: w,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(
                        Icons.manage_search,
                        color: Color(0xFF0DB2E2),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Library Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: t.fontHeading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      WarpDpadButton(
                        tokens: t,
                        onSelect: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(4),
                        backgroundColor: Colors.transparent,
                        borderColor: Colors.transparent,
                        focusBackgroundColor: const Color(0x330DB2E2),
                        focusBorderColor: Colors.white,
                        focusBoxShadow: [
                          BoxShadow(
                            color: Colors.white.withAlpha(130),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: const Color(0xFF0DB2E2).withAlpha(140),
                            blurRadius: 22,
                            spreadRadius: 4,
                          ),
                        ],
                        child: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Dual panels ─────────────────────────────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _PanelWidget(
                            label: 'Movies',
                            icon: Icons.movie_outlined,
                            folder: _moviesFolder,
                            isActive:
                                _activePanel == _ScanPanel.movies && _scanning,
                            canScan: _moviesFolder != null && !_scanning,
                            onSelectFolder: () =>
                                _selectFolder(_ScanPanel.movies),
                            onScan: () => _startScan(_ScanPanel.movies),
                            autofocusFolder: true,
                            t: t,
                          ),
                        ),
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.white.withAlpha(15),
                        ),
                        Expanded(
                          child: _PanelWidget(
                            label: 'Shows',
                            icon: Icons.tv_outlined,
                            folder: _showsFolder,
                            isActive:
                                _activePanel == _ScanPanel.shows && _scanning,
                            canScan: _showsFolder != null && !_scanning,
                            onSelectFolder: () =>
                                _selectFolder(_ScanPanel.shows),
                            onScan: () => _startScan(_ScanPanel.shows),
                            t: t,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Progress + Logs ─────────────────────────────────────────────
                  if (_scanning || _status != null) ...[
                    const SizedBox(height: 20),
                    _ScanProgressArea(
                      scanning: _scanning,
                      status: _status,
                      logs: _logs,
                      logScroll: _logScroll,
                      t: t,
                    ),
                  ],

                  // ── Error ────────────────────────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.redAccent.withAlpha(80),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: t.fontSubtitle,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Footer ───────────────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_scanning)
                        WarpDpadButton(
                          tokens: t,
                          onSelect: _cancelScan,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor: Colors.redAccent.withAlpha(16),
                          borderColor: Colors.redAccent.withAlpha(50),
                          focusBorderColor: Colors.redAccent,
                          child: const Text(
                            'Cancel Scan',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      if (isDone && _status?.result != null) ...[
                        const SizedBox(width: 8),
                        WarpDpadButton(
                          tokens: t,
                          onSelect: _addToLibrary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor: const Color(
                            0xFF0DB2E2,
                          ).withAlpha(30),
                          borderColor: const Color(0xFF0DB2E2).withAlpha(80),
                          child: const Text(
                            'Add to Library',
                            style: TextStyle(
                              color: Color(0xFF0DB2E2),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      WarpDpadButton(
                        tokens: t,
                        onSelect: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        backgroundColor: Colors.transparent,
                        borderColor: Colors.white.withAlpha(20),
                        child: Text(
                          _scanning ? 'Dismiss' : 'Close',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PanelWidget — one side of the dual-panel layout
// ─────────────────────────────────────────────────────────────────────────────

class _PanelWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? folder;
  final bool isActive;
  final bool canScan;
  final VoidCallback onSelectFolder;
  final VoidCallback onScan;
  final WarpTokens t;
  final bool autofocusFolder;

  const _PanelWidget({
    required this.label,
    required this.icon,
    required this.folder,
    required this.isActive,
    required this.canScan,
    required this.onSelectFolder,
    required this.onScan,
    required this.t,
    this.autofocusFolder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0DB2E2), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: t.fontBody,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Folder selector
        WarpDpadButton(
          tokens: t,
          autofocus: autofocusFolder,
          entry: autofocusFolder,
          onSelect: onSelectFolder,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: Colors.white.withAlpha(10),
          borderColor: Colors.white.withAlpha(25),
          borderRadius: 8,
          child: Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                color: Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folder ?? 'Select folder…',
                  style: TextStyle(
                    color: folder != null ? Colors.white : Colors.white38,
                    fontSize: t.fontSubtitle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Scan Now button — global rule: CTA button, dark/cyan-border by
        // default, reveals cyan fill only when focused.
        SizedBox(
          width: double.infinity,
          child: WarpDpadButton(
            tokens: t,
            enabled: canScan,
            onSelect: onScan,
            padding: const EdgeInsets.symmetric(vertical: 10),
            backgroundColor: canScan
                ? const Color(0xCC333232)
                : Colors.white.withAlpha(8),
            focusBackgroundColor: const Color(0xFF0DB2E2),
            borderColor: canScan
                ? const Color(0xFF0DB2E2)
                : Colors.white.withAlpha(15),
            borderRadius: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isActive)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.play_arrow,
                    color: canScan ? Colors.white : Colors.white30,
                    size: 16,
                  ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'Scanning…' : 'Scan Now',
                  style: TextStyle(
                    color: canScan ? Colors.white : Colors.white30,
                    fontSize: t.fontSubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScanProgressArea — progress bar + log output
// ─────────────────────────────────────────────────────────────────────────────

class _ScanProgressArea extends StatelessWidget {
  final bool scanning;
  final ScanStatusResponse? status;
  final List<String> logs;
  final ScrollController logScroll;
  final WarpTokens t;

  const _ScanProgressArea({
    required this.scanning,
    required this.status,
    required this.logs,
    required this.logScroll,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status?.running == false && status != null;
    final progress = isDone
        ? 1.0
        : (status?.running == true ? status!.progress.clamp(0.0, 1.0) : null);
    final summary = status?.result;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status line
          Row(
            children: [
              if (isDone)
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF10B981),
                  size: 16,
                )
              else
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFF0DB2E2),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDone ? 'Scan complete' : (status?.message ?? 'Starting…'),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: t.fontSubtitle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status?.filesDone != null && status?.filesTotal != null)
                Text(
                  '${status!.filesDone}/${status!.filesTotal}',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withAlpha(20),
            valueColor: AlwaysStoppedAnimation(
              isDone ? const Color(0xFF10B981) : const Color(0xFF0DB2E2),
            ),
            minHeight: 3,
          ),

          // Summary stats when done
          if (isDone && summary != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _StatChip('Added', summary.newTitles, t),
                _StatChip('Updated', summary.updatedTitles, t),
                _StatChip('Episodes', summary.newEpisodes, t),
                if (status?.filesDone != null)
                  _StatChip('Files', status!.filesDone!, t),
              ],
            ),
          ],

          // Log output
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(60),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ListView.builder(
                controller: logScroll,
                padding: const EdgeInsets.all(8),
                itemCount: logs.length,
                itemBuilder: (_, i) => Text(
                  logs[i],
                  style: const TextStyle(
                    color: Color(0xFF7EAF9F),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final WarpTokens t;

  const _StatChip(this.label, this.value, this.t);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: t.fontSubtitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
