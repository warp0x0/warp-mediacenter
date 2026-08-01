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
      await ref.read(pluginActionsProvider).uninstall(
        plugin.pluginId,
        force: plugin.enabled,
      );
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
      data: (categories) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PluginSectionTitle('Plugins', t),
          const SizedBox(height: 6),
          Text(
            'Extend Warp with trackers, providers, catalogs and skins.',
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            PluginCard(
              padding: const EdgeInsets.all(14),
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
          for (final category in categories) ...[
            _CategoryGroup(
              category: category,
              t: t,
              busyPluginId: _busyPluginId,
              focusFor: widget.focusFor,
              directionFor: widget.directionFor,
              onInstall: () => _install(category.id),
              onToggle: (plugin) => _toggle(category, plugin),
              onUninstall: _uninstall,
            ),
            const SizedBox(height: 26),
          ],
        ],
      ),
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: t.fontBody,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (category.exclusive) ...[
                        const SizedBox(width: 8),
                        PluginStatusChip(
                          label: 'one at a time',
                          color: Colors.white38,
                          t: t,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
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
            const SizedBox(width: 12),
            WarpDpadButton(
              tokens: t,
              focusNode: focusFor(installKey),
              onDirection: directionFor(installKey),
              onSelect: onInstall,
              enabled: busyPluginId == null,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    'Install new Plugin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: t.fontSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (category.installed.isEmpty)
          PluginEmptyHint('No ${category.label.toLowerCase()} installed yet.', t)
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PluginCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
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
                      const SizedBox(width: 8),
                      Text(
                        'v${plugin.version}',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: t.fontSubtitle,
                        ),
                      ),
                      if (plugin.enabled) ...[
                        const SizedBox(width: 10),
                        PluginStatusChip(
                          label: category.exclusive ? 'Active' : 'Enabled',
                          color: kAccent,
                          t: t,
                        ),
                      ],
                      if (auth?.reauthRequired == true) ...[
                        const SizedBox(width: 8),
                        PluginStatusChip(
                          label: 'Sign in again',
                          color: Colors.orangeAccent,
                          t: t,
                        ),
                      ],
                    ],
                  ),
                  if (plugin.description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      plugin.description!,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: t.fontSubtitle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(width: 10),
              WarpDpadButton(
                tokens: t,
                focusNode: focusFor(toggleKey),
                onDirection: directionFor(toggleKey),
                onSelect: onToggle,
                enabled: !disabled,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                child: _ToggleTrack(on: plugin.enabled),
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
  const _ToggleTrack({required this.on});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 40,
      height: 22,
      decoration: BoxDecoration(
        color: on ? kAccent.withAlpha(90) : Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? kAccent : Colors.white.withAlpha(40),
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 140),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: on ? kAccent : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
