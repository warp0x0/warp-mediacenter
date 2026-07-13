import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/api_client.dart';
import '../../models/files.dart';
import '../../theme/warp_tokens.dart';
import '../shared/dpad_controls.dart';
import '../shared/modal_focus_restore.dart';
import '../shared/tv_modal_chrome_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FileBrowserModal — browse server filesystem via GET /api/v1/files/browse
// Returns the chosen file path, or null if dismissed.
// ─────────────────────────────────────────────────────────────────────────────

class FileBrowserModal extends ConsumerStatefulWidget {
  final String? initialPath;

  /// When true, only directories are shown and "Select Folder" returns the
  /// current directory path. When false, clicking a file returns its path.
  final bool dirsOnly;

  const FileBrowserModal({super.key, this.initialPath, this.dirsOnly = false});

  static Future<String?> show(
    BuildContext context, {
    String? initialPath,
    bool dirsOnly = false,
  }) {
    return showDialog<String?>(
      context: context,
      builder: (_) =>
          FileBrowserModal(initialPath: initialPath, dirsOnly: dirsOnly),
    );
  }

  @override
  ConsumerState<FileBrowserModal> createState() => _FileBrowserModalState();
}

class _FileBrowserModalState extends ConsumerState<FileBrowserModal>
    with WidgetsBindingObserver, ModalFocusRestore<FileBrowserModal> {
  String _path = '/';
  List<FileBrowseEntry> _entries = [];
  String? _parent;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath ?? '/';
    _browse(_path);
  }

  Future<void> _browse(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.get<Map<String, dynamic>>(
        '/api/v1/files/browse',
        params: {'path': path},
      );
      final resp = FileBrowseResponse.fromJson(raw);
      setState(() {
        _path = resp.path;
        _parent = resp.parent;
        _entries = resp.entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navigateTo(FileBrowseEntry entry) {
    if (entry.isDir) {
      _browse(entry.path);
    } else if (!widget.dirsOnly) {
      Navigator.of(context).pop(entry.path);
    }
    // In dirsOnly mode, clicking a file does nothing — use "Select Folder"
  }

  List<String> _breadcrumbLabels() {
    if (_path == '/' || _path.isEmpty) return ['/'];
    return ['/', ..._path.split('/').where((p) => p.isNotEmpty)];
  }

  String _pathForCrumb(int index) {
    if (index == 0) return '/';
    final parts = _path.split('/').where((p) => p.isNotEmpty).toList();
    return '/${parts.take(index).join('/')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final w = (size.width * 0.85).clamp(380.0, 780.0);
    final h = (size.height * 0.75).clamp(400.0, 700.0);

    return Dialog(
      backgroundColor: Colors.transparent,
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
            memoryKey: 'modal-file-browser',
            horizontalEdge: DpadEdgeBehavior.stop,
            verticalEdge: DpadEdgeBehavior.stop,
            child: Center(
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  children: [
                    // Header
                    _Header(
                      path: _path,
                      dirsOnly: widget.dirsOnly,
                      onClose: () => Navigator.of(context).pop(),
                      t: t,
                    ),

                    // Breadcrumb navigation
                    _BreadcrumbRow(
                      labels: _breadcrumbLabels(),
                      onTap: (i) => _browse(_pathForCrumb(i)),
                      t: t,
                    ),

                    // Up button
                    if (_parent != null)
                      _UpRow(onTap: () => _browse(_parent!), t: t),

                    // Body
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0DB2E2),
                                strokeWidth: 2,
                              ),
                            )
                          : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: t.fontSubtitle,
                                ),
                              ),
                            )
                          : _EntryList(
                              entries: _entries,
                              dirsOnly: widget.dirsOnly,
                              onTap: _navigateTo,
                              t: t,
                            ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white.withAlpha(15)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _path,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: t.fontSubtitle,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          WarpDpadButton(
                            tokens: t,
                            onSelect: () => Navigator.of(context).pop(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            backgroundColor: Colors.transparent,
                            borderColor: Colors.white.withAlpha(20),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          if (widget.dirsOnly) ...[
                            const SizedBox(width: 8),
                            WarpDpadButton(
                              tokens: t,
                              onSelect: () => Navigator.of(context).pop(_path),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              backgroundColor: const Color(
                                0xFF0DB2E2,
                              ).withAlpha(30),
                              borderColor: const Color(
                                0xFF0DB2E2,
                              ).withAlpha(80),
                              child: const Text(
                                'Select Folder',
                                style: TextStyle(
                                  color: Color(0xFF0DB2E2),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
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
}

class _Header extends StatelessWidget {
  final String path;
  final bool dirsOnly;
  final VoidCallback onClose;
  final WarpTokens t;

  const _Header({
    required this.path,
    required this.dirsOnly,
    required this.onClose,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(15))),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open, color: Color(0xFF0DB2E2), size: 20),
          const SizedBox(width: 10),
          Text(
            dirsOnly ? 'Select Folder' : 'Browse Files',
            style: TextStyle(
              color: Colors.white,
              fontSize: t.fontBody,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          WarpDpadButton(
            tokens: t,
            onSelect: onClose,
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
            child: const Icon(Icons.close, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbRow extends StatelessWidget {
  final List<String> labels;
  final void Function(int index) onTap;
  final WarpTokens t;

  const _BreadcrumbRow({
    required this.labels,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(8))),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, _) =>
              const Icon(Icons.chevron_right, color: Colors.white24, size: 14),
          itemBuilder: (_, i) {
            final isLast = i == labels.length - 1;
            return DpadFocusable(
              enabled: !isLast,
              onSelect: isLast ? () {} : () => onTap(i),
              builder: (context, state, child) => GestureDetector(
                onTap: isLast ? null : () => onTap(i),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: isLast
                          ? Colors.white70
                          : (state.focused
                                ? Colors.white
                                : const Color(0xFF0DB2E2)),
                      fontSize: 12,
                      fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              child: const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

class _UpRow extends StatelessWidget {
  final VoidCallback onTap;
  final WarpTokens t;

  const _UpRow({required this.onTap, required this.t});

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onSelect: onTap,
      builder: (context, state, child) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: state.focused ? Colors.white.withAlpha(15) : null,
            border: Border(
              bottom: BorderSide(color: Colors.white.withAlpha(10)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.arrow_upward, color: Colors.white54, size: 16),
              const SizedBox(width: 10),
              Text(
                '..',
                style: TextStyle(color: Colors.white54, fontSize: t.fontBody),
              ),
            ],
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

class _EntryList extends StatelessWidget {
  final List<FileBrowseEntry> entries;
  final bool dirsOnly;
  final void Function(FileBrowseEntry) onTap;
  final WarpTokens t;

  const _EntryList({
    required this.entries,
    required this.dirsOnly,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final visible = dirsOnly ? entries.where((e) => e.isDir).toList() : entries;
    final sorted = [...visible]
      ..sort((a, b) {
        if (a.isDir == b.isDir) return a.name.compareTo(b.name);
        return a.isDir ? -1 : 1;
      });

    if (sorted.isEmpty) {
      return Center(
        child: Text(
          dirsOnly ? 'No subdirectories' : 'Empty directory',
          style: TextStyle(color: Colors.white38, fontSize: t.fontBody),
        ),
      );
    }

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final entry = sorted[i];
        return DpadFocusable(
          autofocus: i == 0,
          entry: i == 0,
          onSelect: () => onTap(entry),
          builder: (context, state, child) => InkWell(
            onTap: () => onTap(entry),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: state.focused ? Colors.white.withAlpha(15) : null,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withAlpha(8)),
                  left: BorderSide(
                    color: state.focused
                        ? const Color(0xFF0DB2E2)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    entry.isDir
                        ? Icons.folder
                        : Icons.insert_drive_file_outlined,
                    color: entry.isDir
                        ? const Color(0xFF0DB2E2)
                        : Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: TextStyle(
                        color: entry.isDir ? Colors.white : Colors.white70,
                        fontSize: t.fontBody,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.isDir)
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
          child: const SizedBox.shrink(),
        );
      },
    );
  }
}
