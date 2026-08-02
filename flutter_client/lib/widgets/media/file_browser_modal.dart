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

  /// Comma-separated extensions to show ("zip"). Directories are always listed
  /// regardless, otherwise there would be no way to navigate to the file.
  final String? ext;

  /// Optional heading, e.g. "Select a plugin package".
  final String? title;

  const FileBrowserModal({
    super.key,
    this.initialPath,
    this.dirsOnly = false,
    this.ext,
    this.title,
  });

  static Future<String?> show(
    BuildContext context, {
    String? initialPath,
    bool dirsOnly = false,
    String? ext,
    String? title,
  }) {
    return showDialog<String?>(
      context: context,
      builder: (_) => FileBrowserModal(
        initialPath: initialPath,
        dirsOnly: dirsOnly,
        ext: ext,
        title: title,
      ),
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
  // True while `_entries` holds a browse-remote result rather than a local
  // directory listing — suppresses breadcrumbs/Up (a URL has no filesystem
  // parent chain) and labels the section accordingly. Cleared the moment the
  // user browses locally again (breadcrumb, Up, or a folder tap).
  bool _remoteMode = false;

  final _remoteUrlController = TextEditingController();
  final _remoteFieldFocusNode = FocusNode(
    debugLabel: 'FileBrowser-remote-field',
  );
  final _remoteWrapperFocusNode = FocusNode(
    debugLabel: 'FileBrowser-remote-wrapper',
  );
  final _browseButtonFocusNode = FocusNode(
    debugLabel: 'FileBrowser-remote-browse',
  );

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath ?? '/';
    _browse(_path);
  }

  @override
  void dispose() {
    _remoteUrlController.dispose();
    _remoteFieldFocusNode.dispose();
    _remoteWrapperFocusNode.dispose();
    _browseButtonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _browse(String path) async {
    setState(() {
      _loading = true;
      _error = null;
      _remoteMode = false;
    });
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.get<Map<String, dynamic>>(
        '/api/v1/files/browse',
        params: {
          'path': path,
          if (widget.ext != null && widget.ext!.isNotEmpty) 'ext': widget.ext,
        },
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

  Future<void> _browseRemote() async {
    final url = _remoteUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _entries = [];
      _remoteMode = true;
      _parent = null;
      _path = url;
    });
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.get<Map<String, dynamic>>(
        '/api/v1/files/browse-remote',
        params: {'url': url},
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
    final modalScale = MediaQuery.textScalerOf(context).scale(1);
    // The ceilings are what actually bind here, not the percentages: under the
    // TV viewport scale the reported size is the (large) virtual one, so the
    // clamp always wins. Desktop's 780x700 left barely one directory entry
    // visible once the remote-URL row, the OR rule, breadcrumbs and the footer
    // had taken their share, so TV gets its own, much larger pair.
    final maxW = t.isTV ? 1000.0 : 780.0;
    final maxH = t.isTV ? 1100.0 : 700.0;
    final w = (size.width * 0.85).clamp(380.0, maxW);
    final h = (size.height * 0.8).clamp(400.0, maxH) / modalScale;

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
                      title: widget.title,
                      onClose: () => Navigator.of(context).pop(),
                      t: t,
                    ),

                    // Remote URL — a direct link to a file (a plugin .zip
                    // published on GitHub Pages, a network-share URL for a
                    // library scan) as an alternative to browsing the
                    // backend's own filesystem below.
                    _RemoteUrlRow(
                      controller: _remoteUrlController,
                      fieldFocusNode: _remoteFieldFocusNode,
                      wrapperFocusNode: _remoteWrapperFocusNode,
                      browseFocusNode: _browseButtonFocusNode,
                      onBrowse: _browseRemote,
                      t: t,
                    ),
                    const _OrDivider(),

                    // Breadcrumb navigation
                    if (!_remoteMode) ...[
                      _BreadcrumbRow(
                        labels: _breadcrumbLabels(),
                        onTap: (i) => _browse(_pathForCrumb(i)),
                        t: t,
                      ),

                      // Up button
                      if (_parent != null)
                        _UpRow(onTap: () => _browse(_parent!), t: t),
                    ] else
                      _RemoteResultLabel(t: t),

                    // Body
                    Expanded(
                      child: _loading
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Color(0xFF0DB2E2),
                                    strokeWidth: 2,
                                  ),
                                  if (_remoteMode) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Searching…',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(170),
                                        fontSize: t.fontSubtitle,
                                      ),
                                    ),
                                  ],
                                ],
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
                                color: Colors.white.withAlpha(170),
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

class _RemoteUrlRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode fieldFocusNode;
  final FocusNode wrapperFocusNode;
  final FocusNode browseFocusNode;
  final VoidCallback onBrowse;
  final WarpTokens t;

  const _RemoteUrlRow({
    required this.controller,
    required this.fieldFocusNode,
    required this.wrapperFocusNode,
    required this.browseFocusNode,
    required this.onBrowse,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter a remote URL — a network share for library scans, or a '
            'direct link to a plugin package (e.g. hosted on GitHub Pages).',
            style: TextStyle(
              color: Colors.white.withAlpha(150),
              fontSize: t.fontSubtitle,
            ),
          ),
          const SizedBox(height: 10),
          // IntrinsicHeight + stretch so Browse matches the field's height
          // exactly. They were laid out independently before, so the button
          // sat shorter than the field and the row read as misaligned.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: WarpDpadTextField(
                    controller: controller,
                    tokens: t,
                    fieldFocusNode: fieldFocusNode,
                    wrapperFocusNode: wrapperFocusNode,
                    onSubmitted: (_) => onBrowse(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'https://example.com/plugin.zip',
                      hintStyle: const TextStyle(color: Colors.white24),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withAlpha(30),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withAlpha(30),
                        ),
                      ),
                    ),
                    style: TextStyle(color: Colors.white, fontSize: t.fontBody),
                  ),
                ),
                const SizedBox(width: 10),
                WarpDpadButton(
                  tokens: t,
                  focusNode: browseFocusNode,
                  onSelect: onBrowse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  backgroundColor: const Color(0xFF0DB2E2).withAlpha(30),
                  borderColor: const Color(0xFF0DB2E2).withAlpha(80),
                  focusBackgroundColor: const Color(0xFF0DB2E2).withAlpha(60),
                  focusBorderColor: const Color(0xFF0DB2E2),
                  child: Text(
                    'Browse',
                    style: TextStyle(
                      color: const Color(0xFF0DB2E2),
                      fontWeight: FontWeight.w600,
                      fontSize: t.isTV ? t.fontSubtitle : 13,
                    ),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.white.withAlpha(15), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'OR',
              style: TextStyle(
                color: Colors.white.withAlpha(90),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.white.withAlpha(15), height: 1),
          ),
        ],
      ),
    );
  }
}

class _RemoteResultLabel extends StatelessWidget {
  final WarpTokens t;

  const _RemoteResultLabel({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(8))),
      ),
      child: Text(
        'Remote result',
        style: TextStyle(
          color: Colors.white.withAlpha(140),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String path;
  final bool dirsOnly;
  final String? title;
  final VoidCallback onClose;
  final WarpTokens t;

  const _Header({
    required this.path,
    required this.dirsOnly,
    required this.onClose,
    required this.t,
    this.title,
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
            title ?? (dirsOnly ? 'Select Folder' : 'Browse Files'),
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
          style: TextStyle(
            color: Colors.white.withAlpha(170),
            fontSize: t.fontBody,
          ),
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
                        : Colors.white.withAlpha(170),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: TextStyle(
                        color: entry.isDir
                            ? Colors.white
                            : Colors.white.withAlpha(210),
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
