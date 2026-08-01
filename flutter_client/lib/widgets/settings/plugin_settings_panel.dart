import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plugin.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/plugin_provider.dart';
import '../../theme/warp_tokens.dart';
import '../shared/dpad_controls.dart';
import 'plugin_auth_panel.dart';
import 'plugin_common.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PluginSettingsPanel — renders a plugin's settings page from its schema.
//
// Nothing here knows what any particular plugin does.  The backend asks the
// plugin to describe its own fields and their current values; this walks that
// description and draws it.  A plugin installed long after this build shipped
// still gets a working, D-pad-navigable settings page.
//
// Values are written back through the plugin too — the host stores no plugin
// configuration, so "Save" hands the values to the plugin to persist in its own
// tables.
// ─────────────────────────────────────────────────────────────────────────────

const _secretPlaceholder = '__set__';

class PluginSettingsPanel extends ConsumerStatefulWidget {
  final String pluginId;
  final WarpTokens t;
  final FocusNode Function(String key) focusFor;
  final DpadDirectionCallback? Function(String key) directionFor;

  const PluginSettingsPanel({
    super.key,
    required this.pluginId,
    required this.t,
    required this.focusFor,
    required this.directionFor,
  });

  @override
  ConsumerState<PluginSettingsPanel> createState() => _PluginSettingsPanelState();
}

class _PluginSettingsPanelState extends ConsumerState<PluginSettingsPanel> {
  /// Edited values, keyed by field id.  Only touched fields land here, so an
  /// untouched password keeps its `__set__` placeholder and the backend leaves
  /// the stored secret alone.
  final Map<String, Object?> _edits = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  String? _error;
  String? _notice;
  String? _schemaKey;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(PluginField field) {
    return _controllers.putIfAbsent(field.id, () {
      final value = field.type == PluginFieldType.password &&
              field.stringValue == _secretPlaceholder
          ? ''
          : field.stringValue;
      return TextEditingController(text: value);
    });
  }

  /// Drop cached edits when the schema is replaced (plugin reinstalled, or a
  /// save round-tripped), so stale text does not linger over fresh values.
  void _syncTo(PluginSettingsSchema schema) {
    final key = '${schema.pluginId}:${schema.version}:${schema.sections.length}';
    if (_schemaKey == key) return;
    _schemaKey = key;
    _edits.clear();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  Object? _valueOf(PluginField field) =>
      _edits.containsKey(field.id) ? _edits[field.id] : field.value;

  /// Gathers everything to send on Save.
  ///
  /// Toggle/select fields are discrete button presses, tracked reliably in
  /// [_edits] the instant they happen. Text/password/number fields are not:
  /// relying on a text field's `onSubmitted` (i.e. an explicit Enter/Done) to
  /// record a typed value means D-pad users who type then navigate straight
  /// to the Save button — the normal way to use this screen — would have
  /// nothing recorded at all. So those are read directly from the live
  /// [TextEditingController] at save time instead, which needs no explicit
  /// commit step from the user.
  Map<String, Object?> _collectValues(PluginSettingsSchema schema) {
    final values = <String, Object?>{};
    for (final field in schema.editableFields) {
      switch (field.type) {
        case PluginFieldType.toggle:
        case PluginFieldType.select:
          if (_edits.containsKey(field.id)) values[field.id] = _edits[field.id];
          break;
        case PluginFieldType.password:
          final text = _controllers[field.id]?.text.trim() ?? '';
          // Empty means "left untouched" — the controller starts empty for an
          // already-stored secret (see _controllerFor), so an empty field
          // must never be sent as a value or it would wipe the stored secret.
          if (text.isNotEmpty) values[field.id] = text;
          break;
        case PluginFieldType.number:
          final text = _controllers[field.id]?.text.trim() ?? '';
          if (text.isNotEmpty) values[field.id] = num.tryParse(text) ?? text;
          break;
        case PluginFieldType.text:
          final controller = _controllers[field.id];
          if (controller != null) values[field.id] = controller.text;
          break;
        case PluginFieldType.actionButton:
        case PluginFieldType.authPanel:
        case PluginFieldType.info:
        case PluginFieldType.unknown:
          break;
      }
    }
    return values;
  }

  Future<void> _save() async {
    final schema = ref.read(pluginSettingsSchemaProvider(widget.pluginId)).asData?.value;
    if (schema == null) return;

    final values = _collectValues(schema);
    if (values.isEmpty) {
      setState(() => _notice = 'Nothing to save.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(pluginActionsProvider).saveSettings(widget.pluginId, values);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _edits.clear();
        _schemaKey = null; // force a resync against the saved values
        _notice = 'Saved.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _describe(e);
      });
    }
  }

  Future<void> _runAction(PluginField field) async {
    if (field.confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF15181C),
          title: Text(
            field.label,
            style: const TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This cannot be undone. Continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(pluginActionsProvider).runAction(widget.pluginId, field.id);
      // A plugin action named exactly this reloads both the Movies and Shows
      // tabs (every catalog row, not just this plugin's own rows) — the same
      // provider invalidation the Catalog panel's own "Refresh Widgets"
      // button uses. The convention lives here, generically, rather than
      // special-cased per plugin.
      if (field.id == 'refresh_widgets') {
        ref.invalidate(catalogDataProvider);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _notice = '${field.label} — done.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _describe(e);
      });
    }
  }

  String _describe(Object error) {
    final text = '$error';
    final match = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(text);
    return match?.group(1) ?? text;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final async = ref.watch(pluginSettingsSchemaProvider(widget.pluginId));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: kAccent, strokeWidth: 2),
        ),
      ),
      error: (e, _) => Text(
        'Could not load settings: ${_describe(e)}',
        style: TextStyle(color: Colors.redAccent, fontSize: t.fontBody),
      ),
      data: (schema) {
        _syncTo(schema);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PluginSectionTitle(schema.title, t),
                const SizedBox(width: 10),
                PluginStatusChip(
                  label: schema.active ? 'Active' : 'Inactive',
                  color: schema.active ? kAccent : Colors.white38,
                  t: t,
                ),
              ],
            ),
            if (schema.description != null) ...[
              const SizedBox(height: 6),
              Text(
                schema.description!,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: t.fontSubtitle,
                ),
              ),
            ],
            if (schema.sections.isEmpty) ...[
              const SizedBox(height: 20),
              PluginEmptyHint('This plugin has no settings.', t),
            ],
            for (final section in schema.sections) ...[
              const SizedBox(height: 24),
              Text(
                section.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: t.fontBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (section.description != null)
                PluginHelpText(section.description!, t),
              const SizedBox(height: 12),
              for (final field in section.fields)
                _buildField(schema, section, field),
            ],
            if (schema.editableFields.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  WarpDpadButton(
                    tokens: t,
                    focusNode: widget.focusFor(_saveKey),
                    onDirection: widget.directionFor(_saveKey),
                    onSelect: _save,
                    enabled: !_saving,
                    child: Text(
                      _saving ? 'Saving…' : 'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: t.fontBody,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  if (_notice != null)
                    Text(
                      _notice!,
                      style: TextStyle(
                        color: const Color(0xFF3DDC84),
                        fontSize: t.fontSubtitle,
                      ),
                    ),
                  if (_error != null)
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
            ] else if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: t.fontSubtitle,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String get _saveKey => 'plugin:${widget.pluginId}:save';

  String _fieldKey(PluginField field, [String suffix = '']) =>
      'plugin:${widget.pluginId}:field:${field.id}${suffix.isEmpty ? '' : ':$suffix'}';

  Widget _buildField(
    PluginSettingsSchema schema,
    PluginSection section,
    PluginField field,
  ) {
    final t = widget.t;

    switch (field.type) {
      case PluginFieldType.info:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            field.text ?? field.label,
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
        );

      case PluginFieldType.authPanel:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PluginAuthPanel(
            pluginId: widget.pluginId,
            label: field.label,
            help: field.help,
            state: field.authState ?? schema.auth ?? const PluginAuthState(),
            t: t,
            focusNode: widget.focusFor(_fieldKey(field)),
            onDirection: widget.directionFor(_fieldKey(field)),
            onChanged: () => setState(() => _schemaKey = null),
          ),
        );

      case PluginFieldType.actionButton:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WarpDpadButton(
                tokens: t,
                focusNode: widget.focusFor(_fieldKey(field)),
                onDirection: widget.directionFor(_fieldKey(field)),
                onSelect: () => _runAction(field),
                enabled: !_saving,
                child: Text(
                  field.label,
                  style: TextStyle(
                    color: field.style == 'danger'
                        ? Colors.redAccent
                        : Colors.white,
                    fontSize: t.fontBody,
                  ),
                ),
              ),
              if (field.help != null) PluginHelpText(field.help!, t),
            ],
          ),
        );

      case PluginFieldType.toggle:
        final value = _valueOf(field) == true;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: t.fontBody,
                      ),
                    ),
                    if (field.help != null) PluginHelpText(field.help!, t),
                  ],
                ),
              ),
              WarpDpadButton(
                tokens: t,
                focusNode: widget.focusFor(_fieldKey(field)),
                onDirection: widget.directionFor(_fieldKey(field)),
                onSelect: () => setState(() => _edits[field.id] = !value),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  value ? 'On' : 'Off',
                  style: TextStyle(
                    color: value ? kAccent : Colors.white54,
                    fontSize: t.fontSubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

      case PluginFieldType.select:
        final current = '${_valueOf(field) ?? ''}';
        final index = field.options.indexWhere((o) => o.value == current);
        final label = index >= 0 ? field.options[index].label : current;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: t.fontBody,
                      ),
                    ),
                    if (field.help != null) PluginHelpText(field.help!, t),
                  ],
                ),
              ),
              WarpDpadButton(
                tokens: t,
                focusNode: widget.focusFor(_fieldKey(field)),
                onDirection: widget.directionFor(_fieldKey(field)),
                // Cycling beats a dropdown on a remote: one button, no popup to
                // trap focus in.
                onSelect: () {
                  if (field.options.isEmpty) return;
                  final next = (index + 1) % field.options.length;
                  setState(() => _edits[field.id] = field.options[next].value);
                },
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.isEmpty ? '—' : label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: t.fontSubtitle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.unfold_more,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case PluginFieldType.text:
      case PluginFieldType.password:
      case PluginFieldType.number:
        final controller = _controllerFor(field);
        final isSecret = field.type == PluginFieldType.password;
        final stored = isSecret && field.stringValue == _secretPlaceholder;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    field.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: t.fontBody,
                    ),
                  ),
                  if (field.required) ...[
                    const SizedBox(width: 6),
                    Text(
                      '*',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: t.fontBody,
                      ),
                    ),
                  ],
                  if (stored) ...[
                    const SizedBox(width: 10),
                    PluginStatusChip(label: 'saved', color: Colors.white38, t: t),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              WarpDpadTextField(
                controller: controller,
                tokens: t,
                fieldFocusNode: widget.focusFor(_fieldKey(field, 'field')),
                wrapperFocusNode: widget.focusFor(_fieldKey(field)),
                onDirection: widget.directionFor(_fieldKey(field)),
                obscureText: isSecret,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: stored ? 'Stored — type to replace' : null,
                  hintStyle: const TextStyle(color: Colors.white24),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                  ),
                ),
                style: TextStyle(color: Colors.white, fontSize: t.fontBody),
                // Save already reads every field's live controller text
                // directly (see _collectValues) — nothing to stash here.
                // Enter/Done is wired straight to Save as a convenience for
                // anyone who does explicitly submit the field.
                onSubmitted: (_) => _save(),
              ),
              if (field.help != null) PluginHelpText(field.help!, t),
            ],
          ),
        );

      case PluginFieldType.unknown:
        // Forward-compatibility: a newer plugin can declare a field type this
        // build has never seen.  Say so plainly rather than dropping it, so the
        // user knows why an option they read about is missing.
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${field.label} — this setting needs a newer app version.',
            style: TextStyle(color: Colors.white24, fontSize: t.fontSubtitle),
          ),
        );
    }
  }
}
