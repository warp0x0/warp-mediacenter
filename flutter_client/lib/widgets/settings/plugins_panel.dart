import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plugin.dart';
import '../../providers/plugin_provider.dart';
import '../../theme/warp_tokens.dart';
import '../media/file_browser_modal.dart';
import '../shared/dpad_controls.dart';
import 'plugin_common.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PluginsPanel — one group per category (Trackers, Providers, Catalogs, Skins).
//
// Empty categories still render their header and Install button.  That is
// deliberate: it shows what the app can be extended with before anything is
// installed, instead of an empty screen that looks broken.
//
// In an exclusive category the switches behave as a radio group — turning one on
// turns the others off.  The backend enforces this with a unique index, so the
// UI reconciles from the server's response rather than assuming its optimistic
// guess was right.
// ─────────────────────────────────────────────────────────────────────────────

typedef PluginFocusResolver = FocusNode Function(String key);

class PluginsPanel extends ConsumerStatefulWidget {
  final WarpTokens t;
  final PluginFocusResolver focusFor;
  final DpadDirectionCallback? Function(String key) directionFor;

  const PluginsPanel({
    super.key,
    required this.t,
    required this.focusFor,
    required this.directionFor,
  });

  @override
  ConsumerState<PluginsPanel> createState() => _PluginsPanelState();
}

class _PluginsPanelState extends ConsumerState<PluginsPanel> {
  String? _busyPluginId;
  String? _error;

  Future<void> _install(String category) async {
    final path = await FileBrowserModal.show(
      context,
      title: 'Select a plugin package',
      ext: 'zip',
    );
    if (path == null || !mounted) return;

    setState(() {
      _busyPluginId = 'install:$category';
      _error = null;
    });
    try {
      final plugin = await ref.read(pluginActionsProvider).install(path);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Installed ${plugin.name} ${plugin.version}')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = _describe(e));
    } finally {
      if (mounted) setState(() => _busyPluginId = null);
    }
  }

  Future<void> _toggle(PluginCategory category, PluginSummary plugin) async {
    setState(() {
      _busyPluginId = plugin.pluginId;
      _error = null;
    });
    try {
      final actions = ref.read(pluginActionsProvider);
      if (category.exclusive) {
        // Turning the active one off means "no plugin in this category", which
        // is a valid, selectable state — not something to be talked out of.
        await actions.setActive(
          category.id,
          plugin.enabled ? null : plugin.pluginId,
        );
      } else {
        await actions.setEnabled(plugin.pluginId, !plugin.enabled);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _describe(e));
    } finally {
      if (mounted) setState(() => _busyPluginId = null);
    }
  }

  Future<void> _uninstall(PluginSummary plugin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15181C),
        title: Text(
          'Remove ${plugin.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Its settings and stored credentials are deleted too. '
          'This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busyPluginId = plugin.pluginId;
      _error = null;
    });
    try {
      await ref
          .read(pluginActionsProvider)
          .uninstall(plugin.pluginId, force: plugin.enabled);
    } catch (e) {
      if (mounted) setState(() => _error = _describe(e));
    } finally {
      if (mounted) setState(() => _busyPluginId = null);
    }
  }

  String _describe(Object error) {
    final text = '$error';
    // Surface the backend's own message ("Plugin manifest missing 'category'")
    // rather than a Dio stack trace — the user picked the wrong file and needs
    // to know which part of it was wrong.
    final match = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(text);
    return match?.group(1) ?? text;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final async = ref.watch(pluginCategoriesProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: kAccent, strokeWidth: 2),
        ),
      ),
      error: (e, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PluginSectionTitle('Plugins', t),
          const SizedBox(height: 16),
          Text(
            'Could not load plugins: ${_describe(e)}',
            style: TextStyle(color: Colors.redAccent, fontSize: t.fontBody),
          ),
        ],
      ),
      // No title block here on purpose: the settings page header directly
      // above already reads "Plugins / Trackers, providers & skins", so
      // repeating it verbatim was pure duplication and pushed the real
      // content down the screen.
      data: (categories) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            PluginCard(
              padding: EdgeInsets.all(t.fontBody * 0.8),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: t.fontBody,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: t.fontBody * 0.5),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: t.fontSubtitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: t.fontBody),
          ],
          for (var i = 0; i < categories.length; i++) ...[
            _CategoryGroup(
              category: categories[i],
              t: t,
              busyPluginId: _busyPluginId,
              focusFor: widget.focusFor,
              directionFor: widget.directionFor,
              onInstall: () => _install(categories[i].id),
              onToggle: (plugin) => _toggle(categories[i], plugin),
              onUninstall: _uninstall,
            ),
            if (i != categories.length - 1) ...[
              // TV only: at viewing distance the categories ran together into
              // one undifferentiated column, so they get a real rule and much
              // more air between them. Desktop keeps its existing rhythm.
              if (t.isTV) ...[
                SizedBox(height: t.fontBody * 1.9),
                const PluginDivider(),
                SizedBox(height: t.fontBody * 1.9),
              ] else
                SizedBox(height: t.fontBody * 1.7),
            ],
          ],
        ],
      ),
    );
  }
}

/// Category glyphs, chosen to echo the settings sidebar's own iconography.
IconData _categoryIcon(String id) => switch (id) {
  'tracker' => Icons.sync_outlined,
  'provider' => Icons.bolt_outlined,
  'catalog' => Icons.grid_view_outlined,
  'skin' => Icons.palette_outlined,
  _ => Icons.extension_outlined,
};

class _CategoryGroup extends StatelessWidget {
  final PluginCategory category;
  final WarpTokens t;
  final String? busyPluginId;
  final PluginFocusResolver focusFor;
  final DpadDirectionCallback? Function(String key) directionFor;
  final VoidCallback onInstall;
  final void Function(PluginSummary) onToggle;
  final void Function(PluginSummary) onUninstall;

  const _CategoryGroup({
    required this.category,
    required this.t,
    required this.busyPluginId,
    required this.focusFor,
    required this.directionFor,
    required this.onInstall,
    required this.onToggle,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final installKey = 'plugins:${category.id}:install';
    final gap = t.fontBody;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PluginIconTile(icon: _categoryIcon(category.id), t: t),
            SizedBox(width: gap * 0.7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: t.fontBody,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (category.exclusive) ...[
                        SizedBox(width: gap * 0.5),
                        PluginStatusChip(
                          label: 'one at a time',
                          color: Colors.white38,
                          t: t,
                          quiet: true,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: gap * 0.15),
                  Text(
                    category.description,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: t.fontSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: gap * 0.7),
            // Accent-tinted: installing is this screen's primary action, and
            // a transparent button repeated four times read as chrome rather
            // than something to press.
            WarpDpadButton(
              tokens: t,
              focusNode: focusFor(installKey),
              onDirection: directionFor(installKey),
              onSelect: onInstall,
              enabled: busyPluginId == null,
              padding: EdgeInsets.symmetric(
                horizontal: gap * 0.85,
                vertical: gap * 0.5,
              ),
              backgroundColor: kAccent.withAlpha(26),
              borderColor: kAccent.withAlpha(90),
              focusBackgroundColor: kAccent.withAlpha(64),
              focusBorderColor: kAccent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: t.fontBody, color: kAccent),
                  SizedBox(width: gap * 0.35),
                  Text(
                    'Install',
                    style: TextStyle(
                      color: kAccent,
                      fontSize: t.fontSubtitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: gap * (t.isTV ? 0.85 : 0.7)),
        // TV only: entries sit inset to the width of the category's icon tile,
        // so they line up under its label and read as belonging to it rather
        // than as a flat list that happens to follow a heading.
        Padding(
          padding: EdgeInsets.only(left: t.isTV ? gap * 2.7 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category.installed.isEmpty)
                PluginEmptyHint(
                  'No ${category.label.toLowerCase()} installed yet.',
                  t,
                  icon: _categoryIcon(category.id),
                )
              else
                for (final plugin in category.installed)
                  _PluginRow(
                    plugin: plugin,
                    category: category,
                    t: t,
                    busy: busyPluginId == plugin.pluginId,
                    disabled: busyPluginId != null,
                    focusFor: focusFor,
                    directionFor: directionFor,
                    onToggle: () => onToggle(plugin),
                    onUninstall: () => onUninstall(plugin),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PluginRow extends StatelessWidget {
  final PluginSummary plugin;
  final PluginCategory category;
  final WarpTokens t;
  final bool busy;
  final bool disabled;
  final PluginFocusResolver focusFor;
  final DpadDirectionCallback? Function(String key) directionFor;
  final VoidCallback onToggle;
  final VoidCallback onUninstall;

  const _PluginRow({
    required this.plugin,
    required this.category,
    required this.t,
    required this.busy,
    required this.disabled,
    required this.focusFor,
    required this.directionFor,
    required this.onToggle,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final toggleKey = 'plugins:${category.id}:row:${plugin.pluginId}';
    final removeKey = 'plugins:${category.id}:remove:${plugin.pluginId}';
    final auth = plugin.auth;

    final gap = t.fontBody;
    final on = plugin.enabled;

    return Padding(
      padding: EdgeInsets.only(bottom: gap * 0.55),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: gap * 0.9,
          vertical: gap * 0.75,
        ),
        decoration: BoxDecoration(
          // An enabled plugin gets a faint accent wash and a brighter edge, so
          // "which one is on" survives a glance from across the room — the
          // chip and the switch alone were too small to carry that at TV
          // viewing distance.
          color: on ? kAccent.withAlpha(16) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? kAccent.withAlpha(70) : Colors.white.withAlpha(20),
          ),
        ),
        child: Row(
          children: [
            PluginIconTile(
              icon: _categoryIcon(category.id),
              t: t,
              active: on,
              scale: 0.92,
            ),
            SizedBox(width: gap * 0.7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          plugin.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: t.fontBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: gap * 0.45),
                      Text(
                        'v${plugin.version}',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: t.fontSubtitle * 0.88,
                        ),
                      ),
                      if (on) ...[
                        SizedBox(width: gap * 0.5),
                        PluginStatusChip(
                          label: category.exclusive ? 'Active' : 'Enabled',
                          color: kAccent,
                          t: t,
                          dot: true,
                        ),
                      ],
                      if (auth?.reauthRequired == true) ...[
                        SizedBox(width: gap * 0.4),
                        PluginStatusChip(
                          label: 'Sign in again',
                          color: Colors.orangeAccent,
                          t: t,
                          dot: true,
                        ),
                      ],
                    ],
                  ),
                  if (plugin.description != null) ...[
                    SizedBox(height: gap * 0.2),
                    Text(
                      plugin.description!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: t.fontSubtitle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: gap * 0.7),
            if (busy)
              SizedBox(
                width: t.fontBody * 1.1,
                height: t.fontBody * 1.1,
                child: const CircularProgressIndicator(
                  color: kAccent,
                  strokeWidth: 2,
                ),
              )
            else ...[
              WarpDpadButton(
                tokens: t,
                focusNode: focusFor(removeKey),
                onDirection: directionFor(removeKey),
                onSelect: onUninstall,
                enabled: !disabled,
                padding: EdgeInsets.all(gap * 0.45),
                focusBackgroundColor: Colors.redAccent.withAlpha(38),
                focusBorderColor: Colors.redAccent,
                child: Icon(
                  Icons.delete_outline,
                  size: t.fontBody,
                  color: Colors.white54,
                ),
              ),
              SizedBox(width: gap * 0.5),
              WarpDpadButton(
                tokens: t,
                focusNode: focusFor(toggleKey),
                onDirection: directionFor(toggleKey),
                onSelect: onToggle,
                enabled: !disabled,
                padding: EdgeInsets.symmetric(
                  horizontal: gap * 0.4,
                  vertical: gap * 0.4,
                ),
                backgroundColor: Colors.transparent,
                borderColor: Colors.transparent,
                child: _ToggleTrack(on: on, t: t),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A switch drawn by hand so it inherits D-pad focus from [WarpDpadButton]
/// instead of competing with it for a tap target.
class _ToggleTrack extends StatelessWidget {
  final bool on;
  final WarpTokens t;
  const _ToggleTrack({required this.on, required this.t});

  @override
  Widget build(BuildContext context) {
    // Sized from the type scale rather than fixed pixels — at TV density the
    // old 40x22 switch was a speck next to text twice its former size.
    final h = t.fontBody * 1.25;
    final w = h * 1.85;
    final knob = h - 6;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: on ? kAccent.withAlpha(80) : Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? kAccent : Colors.white.withAlpha(45),
          width: 1.5,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: Container(
            width: knob,
            height: knob,
            decoration: BoxDecoration(
              color: on ? Colors.white : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
