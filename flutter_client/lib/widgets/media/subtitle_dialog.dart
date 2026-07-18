import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/subtitle.dart' as subtitle_models;
import '../../player/backend/warp_playback_backend.dart';
import '../../theme/warp_tokens.dart';
import 'file_browser_modal.dart';
import '../shared/modal_focus_restore.dart';
import '../shared/tv_modal_chrome_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SubtitleDialog — subtitle search, file load, and track switcher, driven by
// a WarpPlaybackBackend (media_kit on desktop, native Media3 on Android TV).
// ─────────────────────────────────────────────────────────────────────────────

const _accent = Color(0xFF0DB2E2);
const _accentLight = Color(0xFF78F4FF);
const _glass = Color(0xE50A0E14);

class SubtitleDialog extends ConsumerStatefulWidget {
  final WarpPlaybackBackend backend;
  final String tmdbId;
  final String mediaKind; // 'movie' or 'show'
  final String? title;
  final int? season;
  final int? episode;
  final String? sourceUrl;

  const SubtitleDialog({
    super.key,
    required this.backend,
    required this.tmdbId,
    required this.mediaKind,
    this.title,
    this.season,
    this.episode,
    this.sourceUrl,
  });

  @override
  ConsumerState<SubtitleDialog> createState() => _SubtitleDialogState();
}

class _SubtitleDialogState extends ConsumerState<SubtitleDialog>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        ModalFocusRestore<SubtitleDialog> {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final width = (size.width * 0.86).clamp(460.0, 880.0);
    final height = (size.height * 0.82).clamp(500.0, 740.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: TvModalChromeScale(
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).pop(),
            const SingleActivator(LogicalKeyboardKey.backspace): () =>
                Navigator.of(context).pop(),
            const SingleActivator(LogicalKeyboardKey.goBack): () =>
                Navigator.of(context).pop(),
            const SingleActivator(LogicalKeyboardKey.browserBack): () =>
                Navigator.of(context).pop(),
          },
          child: DpadRegion(
            memoryKey: 'modal-subtitle',
            horizontalEdge: DpadEdgeBehavior.stop,
            verticalEdge: DpadEdgeBehavior.stop,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width, maxHeight: height),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xF20A0E14), Color(0xE5091A24)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: _accent.withAlpha(76)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 36,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _DialogHeader(
                            title: 'Subtitles',
                            subtitle: _headerSubtitle(),
                            onClose: () => Navigator.of(context).pop(),
                            t: t,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                            child: _Tabs(controller: _tabs, t: t),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabs,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _SearchTab(
                                  backend: widget.backend,
                                  tmdbId: widget.tmdbId,
                                  mediaKind: widget.mediaKind == 'show'
                                      ? 'show'
                                      : 'movie',
                                  title: widget.title,
                                  season: widget.season,
                                  episode: widget.episode,
                                  sourceUrl: widget.sourceUrl,
                                  t: t,
                                ),
                                _BrowseTab(backend: widget.backend, t: t),
                                _ActiveTracksTab(backend: widget.backend, t: t),
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
          ),
        ),
      ),
    );
  }

  String _headerSubtitle() {
    final title = widget.title?.trim();
    if (title == null || title.isEmpty) return 'Search, load, or switch tracks';
    if (widget.mediaKind == 'show' &&
        widget.season != null &&
        widget.episode != null) {
      return '$title  •  S${widget.season} E${widget.episode}';
    }
    return title;
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final WarpTokens t;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.t,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _accent.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withAlpha(62)),
          ),
          child: const Center(
            child: _GradientIcon(icon: Icons.subtitles, size: 24),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: t.fontBody + 3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withAlpha(145),
                  fontSize: t.fontSubtitle,
                ),
              ),
            ],
          ),
        ),
        DpadFocusable(
          onSelect: onClose,
          tapToSelect: false,
          builder: (context, state, child) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.focused
                  ? Colors.white.withAlpha(24)
                  : Colors.transparent,
              border: Border.all(
                color: state.focused
                    ? Colors.white.withAlpha(220)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: state.focused
                  ? [
                      BoxShadow(
                        color: Colors.white.withAlpha(130),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: _accent.withAlpha(140),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                color: state.focused ? Colors.white : Colors.white70,
              ),
            ),
          ),
          child: const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

class _Tabs extends StatefulWidget {
  final TabController controller;
  final WarpTokens t;

  const _Tabs({required this.controller, required this.t});

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  static const _labels = ['Search', 'Browse File', 'Tracks'];
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      _labels.length,
      (i) => FocusNode(debugLabel: 'SubtitleTab-${_labels[i]}'),
    );
    widget.controller.addListener(_handleTabChanged);
  }

  @override
  void didUpdateWidget(_Tabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTabChanged);
      widget.controller.addListener(_handleTabChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTabChanged);
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleTabChanged() {
    if (mounted) setState(() {});
  }

  void _selectTab(int index) {
    widget.controller.animateTo(index);
  }

  bool _tabDirection(int index, TraversalDirection direction) {
    if (direction == TraversalDirection.left) {
      if (index == 0) return true;
      Dpad.of(context).requestFocus(_focusNodes[index - 1]);
      return true;
    }
    if (direction == TraversalDirection.right) {
      if (index == _focusNodes.length - 1) return true;
      Dpad.of(context).requestFocus(_focusNodes[index + 1]);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withAlpha(22)),
    ),
    child: Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          Expanded(
            child: _SubtitleTabPill(
              label: _labels[i],
              selected: widget.controller.index == i,
              focusNode: _focusNodes[i],
              autofocus: i == 0,
              onTap: () => _selectTab(i),
              onDirection: (direction) => _tabDirection(i, direction),
              t: widget.t,
            ),
          ),
          if (i != _labels.length - 1) const SizedBox(width: 4),
        ],
      ],
    ),
  );
}

class _SubtitleTabPill extends StatefulWidget {
  final String label;
  final bool selected;
  final FocusNode focusNode;
  final bool autofocus;
  final VoidCallback onTap;
  final DpadDirectionCallback onDirection;
  final WarpTokens t;

  const _SubtitleTabPill({
    required this.label,
    required this.selected,
    required this.focusNode,
    required this.autofocus,
    required this.onTap,
    required this.onDirection,
    required this.t,
  });

  @override
  State<_SubtitleTabPill> createState() => _SubtitleTabPillState();
}

class _SubtitleTabPillState extends State<_SubtitleTabPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: DpadFocusable(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      entry: widget.autofocus,
      onDirection: widget.onDirection,
      onSelect: widget.onTap,
      tapToSelect: false,
      builder: (context, state, child) => GestureDetector(
        onTap: () {
          widget.focusNode.requestFocus();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? _accent
                : (_hovered ? Colors.white.withAlpha(20) : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: state.focused
                ? Border.all(
                    color: widget.selected ? Colors.white : _accentLight,
                    width: 2.5,
                  )
                : (widget.selected
                      ? null
                      : Border.all(color: Colors.transparent)),
            boxShadow: state.focused
                ? const [
                    BoxShadow(
                      color: Color(0xCC000000),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                    BoxShadow(color: Color(0x9901B4E4), blurRadius: 18),
                  ]
                : widget.selected
                ? const [BoxShadow(color: Color(0x5901B4E4), blurRadius: 14)]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.selected
                    ? Colors.black
                    : Colors.white.withAlpha(_hovered ? 190 : 145),
                fontSize: widget.t.fontSubtitle,
                fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    ),
  );
}

class _SearchTab extends ConsumerStatefulWidget {
  final WarpPlaybackBackend backend;
  final String tmdbId;
  final String mediaKind;
  final String? title;
  final int? season;
  final int? episode;
  final String? sourceUrl;
  final WarpTokens t;

  const _SearchTab({
    required this.backend,
    required this.tmdbId,
    required this.mediaKind,
    required this.t,
    this.title,
    this.season,
    this.episode,
    this.sourceUrl,
  });

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  String _language = 'eng';
  bool _searching = false;
  String? _loadingKey;
  List<subtitle_models.SubtitleSearchResult> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  Future<void> _search() async {
    final query = widget.title?.trim() ?? '';
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = 'Missing media title for subtitle search.';
        _searching = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final params = <String, dynamic>{
        'query': query,
        'media_kind': widget.mediaKind == 'show' ? 'show' : 'movie',
        'language': _language,
        if (widget.tmdbId.isNotEmpty) 'tmdb_id': widget.tmdbId,
        if (widget.season != null) 'season': widget.season,
        if (widget.episode != null) 'episode': widget.episode,
        if (widget.sourceUrl != null && widget.sourceUrl!.isNotEmpty)
          'media_src': widget.sourceUrl,
      };
      final resp = await client.dio.get<Map<String, dynamic>>(
        '/api/v1/subtitles/search',
        queryParameters: params,
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      final searchResp = subtitle_models.SubtitleSearchResponse.fromJson(
        resp.data ?? {},
      );
      if (!mounted) return;
      setState(() {
        _results = searchResp.results;
        _searching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _searching = false;
      });
    }
  }

  Future<void> _downloadAndLoad(
    subtitle_models.SubtitleSearchResult result,
  ) async {
    final key = '${result.provider}:${result.downloadLink}';
    setState(() {
      _loadingKey = key;
      _error = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.dio.post<Map<String, dynamic>>(
        '/api/v1/subtitles/download',
        data: {
          'provider': result.provider,
          'language': result.language,
          'score': result.score,
          'release': result.release,
          'download_link': result.downloadLink,
          'file_name': result.fileName,
          'hearing_impaired': result.hearingImpaired,
          'rating': result.rating,
          'metadata': result.metadata,
        },
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      final download = subtitle_models.SubtitleDownloadResponse.fromJson(
        resp.data ?? {},
      );
      final uri = _subtitleUri(
        download.url.isNotEmpty ? download.url : download.path,
      );
      // addExternalSubtitle resolves only once the track is actually
      // selectable (both backends handle their own async-registration
      // timing internally — see WarpPlaybackBackend's doc comment), so no
      // poll-and-hope workaround is needed here anymore.
      final trackId = await widget.backend.addExternalSubtitle(
        uri,
        title: result.release.isNotEmpty ? result.release : download.fileName,
        language: result.language,
      );
      await widget.backend.selectSubtitleTrack(trackId);

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingKey = null;
        _error = 'Subtitle load failed: ${_friendlyError(error)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: Row(
            children: [
              Text(
                'Language',
                style: TextStyle(
                  color: Colors.white.withAlpha(155),
                  fontSize: t.fontSubtitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              _LangChip(
                code: 'eng',
                label: 'English',
                selected: _language == 'eng',
                onTap: () => _selectLanguage('eng'),
              ),
              const SizedBox(width: 7),
              _LangChip(
                code: 'fra',
                label: 'French',
                selected: _language == 'fra',
                onTap: () => _selectLanguage('fra'),
              ),
              const SizedBox(width: 7),
              _LangChip(
                code: 'deu',
                label: 'German',
                selected: _language == 'deu',
                onTap: () => _selectLanguage('deu'),
              ),
              const SizedBox(width: 7),
              _LangChip(
                code: 'spa',
                label: 'Spanish',
                selected: _language == 'spa',
                onTap: () => _selectLanguage('spa'),
              ),
              const Spacer(),
              _GlassIconButton(icon: Icons.refresh, onTap: _search),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: _InlineError(message: _error!),
          ),
        Expanded(child: _buildBody(t)),
      ],
    );
  }

  Widget _buildBody(WarpTokens t) {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: _accentLight, strokeWidth: 2),
      );
    }
    if (_results.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off,
        title: 'No subtitles found',
        subtitle: 'Try another language or refresh the search.',
        t: t,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final result = _results[index];
        final key = '${result.provider}:${result.downloadLink}';
        return _SubtitleResultRow(
          result: result,
          loading: _loadingKey == key,
          onLoad: () => _downloadAndLoad(result),
          t: t,
        );
      },
    );
  }

  void _selectLanguage(String code) {
    if (_language == code) return;
    setState(() => _language = code);
    _search();
  }
}

class _LangChip extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: onTap,
    builder: (context, state, child) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _accent.withAlpha(40) : Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: state.focused
                ? _accentLight
                : (selected
                      ? _accentLight.withAlpha(130)
                      : Colors.white.withAlpha(26)),
            width: state.focused ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _accentLight : Colors.white.withAlpha(165),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _SubtitleResultRow extends StatelessWidget {
  final subtitle_models.SubtitleSearchResult result;
  final bool loading;
  final VoidCallback onLoad;
  final WarpTokens t;

  const _SubtitleResultRow({
    required this.result,
    required this.loading,
    required this.onLoad,
    required this.t,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: loading ? () {} : onLoad,
    tapToSelect: false,
    builder: (context, state, child) => GestureDetector(
      onTap: loading ? null : onLoad,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: state.focused ? _accentLight : Colors.white.withAlpha(22),
            width: state.focused ? 2 : 1,
          ),
          boxShadow: state.focused
              ? [
                  BoxShadow(
                    color: _accent.withAlpha(120),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withAlpha(48)),
              ),
              child: const Center(
                child: _GradientIcon(icon: Icons.subtitles, size: 21),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.release.isNotEmpty
                        ? result.release
                        : result.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: t.fontSubtitle,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Tag(label: result.provider),
                      _Tag(label: result.language.toUpperCase()),
                      if (result.hearingImpaired)
                        _Tag(label: 'HI', color: Colors.amber),
                      _Tag(
                        label: _scoreLabel(result.score),
                        color: _accentLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (loading) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: state.focused ? _accentLight : Colors.white70,
                  strokeWidth: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _BrowseTab extends ConsumerStatefulWidget {
  final WarpPlaybackBackend backend;
  final WarpTokens t;

  const _BrowseTab({required this.backend, required this.t});

  @override
  ConsumerState<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<_BrowseTab> {
  bool _loading = false;
  String? _error;

  Future<void> _chooseFile() async {
    final path = await FileBrowserModal.show(context);
    if (path == null || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trackId = await widget.backend.addExternalSubtitle(
        _subtitleUri(path),
        title: _fileName(path),
      );
      await widget.backend.selectSubtitleTrack(trackId);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load subtitle: ${_friendlyError(error)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(22),
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent.withAlpha(58)),
                  ),
                  child: const Center(
                    child: _GradientIcon(icon: Icons.folder_open, size: 34),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Load an external subtitle file',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.t.fontBody,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    'Choose a subtitle path reachable by this client. Downloaded search results use backend-hosted URLs automatically.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(145),
                      fontSize: widget.t.fontSubtitle,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 22),
                _GlassButton(
                  label: _loading ? 'Loading' : 'Choose File',
                  icon: Icons.folder_open,
                  busy: _loading,
                  onTap: _loading ? null : _chooseFile,
                ),
              ],
            ),
          ),
        ),
        if (_error != null) _InlineError(message: _error!),
      ],
    ),
  );
}

class _ActiveTracksTab extends StatefulWidget {
  final WarpPlaybackBackend backend;
  final WarpTokens t;

  const _ActiveTracksTab({required this.backend, required this.t});

  @override
  State<_ActiveTracksTab> createState() => _ActiveTracksTabState();
}

class _ActiveTracksTabState extends State<_ActiveTracksTab> {
  WarpTrackList _tracks = const WarpTrackList();
  StreamSubscription<WarpTrackList>? _subscription;

  @override
  void initState() {
    super.initState();
    // getTracks() gives the initial snapshot; tracksStream only fires on
    // subsequent changes (it won't necessarily re-emit just because this
    // dialog opened), so both are needed — matches the same pattern used in
    // playback_page.dart's _AudioTracksDialog.
    widget.backend.getTracks().then((tracks) {
      if (mounted) setState(() => _tracks = tracks);
    });
    _subscription = widget.backend.tracksStream.listen((tracks) {
      if (mounted) setState(() => _tracks = tracks);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = _tracks.text;
    final noneSelected = tracks.every((t) => !t.selected);

    if (tracks.isEmpty) {
      return _EmptyState(
        icon: Icons.subtitles_off,
        title: 'No subtitle tracks',
        subtitle: 'This file has not exposed any subtitle tracks yet.',
        t: widget.t,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      itemCount: tracks.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SubtitleTrackRow(
            track: null,
            selected: noneSelected,
            onTap: () => widget.backend.selectSubtitleTrack(null),
            t: widget.t,
          );
        }
        final track = tracks[index - 1];
        return _SubtitleTrackRow(
          track: track,
          selected: track.selected,
          onTap: () => widget.backend.selectSubtitleTrack(track.id),
          t: widget.t,
        );
      },
    );
  }
}

class _SubtitleTrackRow extends StatelessWidget {
  // null represents the synthesized "Disabled" row — native track lists
  // (unlike mpv's) don't include a sentinel "no subtitle" entry, so the UI
  // adds one itself rather than requiring every backend to fake one.
  final WarpTextTrack? track;
  final bool selected;
  final VoidCallback onTap;
  final WarpTokens t;

  const _SubtitleTrackRow({
    required this.track,
    required this.selected,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: onTap,
    builder: (context, state, child) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _accent.withAlpha(34) : Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: state.focused
                ? _accentLight
                : (selected
                      ? _accentLight.withAlpha(120)
                      : Colors.white.withAlpha(22)),
            width: state.focused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? _accent.withAlpha(44)
                    : Colors.white.withAlpha(14),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: selected
                    ? const Icon(Icons.check, color: _accentLight, size: 21)
                    : const _GradientIcon(icon: Icons.subtitles, size: 21),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _subtitleTrackTitle(track),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: t.fontSubtitle,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleTrackSubtitle(track),
                    style: TextStyle(
                      color: Colors.white.withAlpha(145),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;

  const _GlassButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    enabled: onTap != null,
    onSelect: onTap ?? () {},
    builder: (context, state, child) => GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.65 : 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: state.focused ? _accent : _glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: state.focused ? _accentLight : _accent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withAlpha(state.focused ? 130 : 48),
                blurRadius: state.focused ? 24 : 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: state.focused ? Colors.black : Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  color: state.focused ? Colors.black : Colors.white,
                  size: 16,
                ),
              if (busy || icon != null) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: state.focused ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: onTap,
    builder: (context, state, child) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(24)),
          boxShadow: state.focused
              ? [
                  BoxShadow(
                    color: _accent.withAlpha(140),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(child: _GradientIcon(icon: icon, size: 19)),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _GradientIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (bounds) => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFF3FFFF), _accentLight],
      stops: [0, 0.72, 1],
    ).createShader(bounds),
    child: Icon(icon, size: size),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;

  const _Tag({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withAlpha(32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white.withAlpha(160),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.redAccent.withAlpha(24),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.redAccent.withAlpha(80)),
    ),
    child: Text(
      message,
      style: TextStyle(color: Colors.redAccent.shade100, height: 1.25),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final WarpTokens t;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.t,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(24)),
          ),
          child: Center(child: _GradientIcon(icon: icon, size: 32)),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: t.fontBody,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withAlpha(145),
            fontSize: t.fontSubtitle,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

String _subtitleUri(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('file://')) {
    return trimmed;
  }
  return Uri.file(trimmed).toString();
}

String _fileName(String value) {
  final normalized = value.replaceAll('\\', '/');
  final parts = normalized.split('/').where((p) => p.isNotEmpty).toList();
  return parts.isEmpty ? 'Subtitle' : parts.last;
}

String _scoreLabel(double score) {
  if (score <= 1) return '${(score * 100).round()}%';
  return score.round().toString();
}

String _friendlyError(Object error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiError) return inner.message;
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (data is String && data.isNotEmpty) return data;
  }
  if (error is ApiError) return error.message;
  return error.toString();
}

String _subtitleTrackTitle(WarpTextTrack? track) {
  if (track == null) return 'Disabled';
  final label = track.label?.trim();
  if (label != null && label.isNotEmpty) return label;
  final language = track.language?.trim();
  if (language != null && language.isNotEmpty) return language.toUpperCase();
  return 'Subtitle ${track.id}';
}

String _subtitleTrackSubtitle(WarpTextTrack? track) {
  if (track == null) return 'Disable subtitle rendering.';
  final parts = <String>[];
  final language = track.language?.trim();
  if (language != null && language.isNotEmpty) {
    parts.add(language.toUpperCase());
  }
  if (track.isExternal) parts.add('External');
  return parts.isEmpty ? 'Track id ${track.id}' : parts.join(' · ');
}
