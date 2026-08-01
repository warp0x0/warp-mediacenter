import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plugin.dart';
import '../../providers/plugin_provider.dart';
import '../../theme/warp_tokens.dart';
import '../shared/dpad_controls.dart';
import 'plugin_common.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PluginAuthPanel — generalised device-code login.
//
// Modelled on the hand-written Trakt panel, but every URL is derived from the
// plugin id, so any plugin declaring `auth.kind: "device_code"` gets this screen
// for free.  The host runs the actual polling on a background thread; this only
// reads the resulting state, so polling here costs nothing upstream and cannot
// trip a rate limit.
//
// The original Trakt panel polled forever on a denied or expired code because it
// only ever stopped on success.  This one stops on every terminal state.
// ─────────────────────────────────────────────────────────────────────────────

class PluginAuthPanel extends ConsumerStatefulWidget {
  final String pluginId;
  final String label;
  final String? help;
  final PluginAuthState state;
  final WarpTokens t;
  final FocusNode focusNode;
  final DpadDirectionCallback? onDirection;
  final VoidCallback? onChanged;

  const PluginAuthPanel({
    super.key,
    required this.pluginId,
    required this.label,
    required this.state,
    required this.t,
    required this.focusNode,
    this.help,
    this.onDirection,
    this.onChanged,
  });

  @override
  ConsumerState<PluginAuthPanel> createState() => _PluginAuthPanelState();
}

class _PluginAuthPanelState extends ConsumerState<PluginAuthPanel> {
  Timer? _poll;
  PluginAuthFlow? _flow;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final raw = await ref.read(pluginActionsProvider).authStart(widget.pluginId);
      if (!mounted) return;
      setState(() {
        _flow = PluginAuthFlow.fromJson(raw);
        _busy = false;
      });
      _schedulePoll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _describe(e);
      });
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    final seconds = (_flow?.interval ?? 5).clamp(2, 30);
    _poll = Timer.periodic(Duration(seconds: seconds), (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    try {
      final status = await ref.read(pluginActionsProvider).authPoll(widget.pluginId);
      if (!mounted) return;

      final flowStatus = status.flow?.status ?? 'none';
      final done = status.connected || flowStatus == 'authorized';
      final failed = flowStatus == 'denied' || flowStatus == 'expired';

      if (done || failed) {
        _poll?.cancel();
        setState(() {
          _flow = failed ? status.flow : null;
          _error = failed
              ? (flowStatus == 'denied'
                    ? 'Authorisation was denied.'
                    : 'The code expired. Start again.')
              : null;
        });
        if (done) {
          ref.invalidate(pluginAuthStatusProvider(widget.pluginId));
          ref.invalidate(pluginSettingsSchemaProvider(widget.pluginId));
          ref.invalidate(pluginCategoriesProvider);
          widget.onChanged?.call();
        }
      }
    } catch (_) {
      // A dropped poll is not worth surfacing; the next tick retries.
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(pluginActionsProvider).authClear(widget.pluginId);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _flow = null;
      });
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
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
    final state = widget.state;
    final flow = _flow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.help != null) ...[
          Text(
            widget.help!,
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 10),
        ],
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Colors.redAccent, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 10),
        ],
        if (!state.configured && state.required)
          PluginCard(
            child: Text(
              'Enter this plugin\'s API credentials below, then connect.',
              style: TextStyle(color: Colors.white54, fontSize: t.fontBody),
            ),
          )
        else if (state.connected)
          _ConnectedBox(
            label: widget.label,
            detail: state.detail ?? state.username,
            plan: state.plan,
            t: t,
            busy: _busy,
            focusNode: widget.focusNode,
            onDirection: widget.onDirection,
            onDisconnect: _disconnect,
          )
        else if (flow != null && flow.userCode != null)
          _DeviceCodeBox(label: widget.label, flow: flow, t: t)
        else
          WarpDpadButton(
            tokens: t,
            focusNode: widget.focusNode,
            onDirection: widget.onDirection,
            onSelect: _start,
            enabled: !_busy,
            child: Text(
              _busy ? 'Starting…' : 'Connect ${widget.label}',
              style: TextStyle(color: Colors.white, fontSize: t.fontBody),
            ),
          ),
        if (state.reauthRequired) ...[
          const SizedBox(height: 10),
          Text(
            'Your session expired — reconnect to resume syncing.',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: t.fontSubtitle,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConnectedBox extends StatelessWidget {
  final String label;
  final String? detail;
  final String? plan;
  final WarpTokens t;
  final bool busy;
  final FocusNode focusNode;
  final DpadDirectionCallback? onDirection;
  final VoidCallback onDisconnect;

  const _ConnectedBox({
    required this.label,
    required this.detail,
    required this.t,
    required this.busy,
    required this.focusNode,
    required this.onDirection,
    required this.onDisconnect,
    this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final isVip = plan != null && plan!.toLowerCase() != 'free';
    return PluginCard(
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF3DDC84), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$label connected',
                      style: TextStyle(color: Colors.white, fontSize: t.fontBody),
                    ),
                    if (isVip) ...[
                      const SizedBox(width: 8),
                      PluginStatusChip(
                        label: plan!.toUpperCase(),
                        color: const Color(0xFFFFC24B),
                        t: t,
                      ),
                    ],
                  ],
                ),
                if (detail != null && detail!.isNotEmpty)
                  Text(
                    detail!,
                    style: TextStyle(
                      color: Colors.white38,
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
            enabled: !busy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Disconnect',
              style: TextStyle(color: Colors.white70, fontSize: t.fontSubtitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCodeBox extends StatelessWidget {
  final String label;
  final PluginAuthFlow flow;
  final WarpTokens t;

  const _DeviceCodeBox({
    required this.label,
    required this.flow,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return PluginCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your $label account:',
            style: TextStyle(color: Colors.white70, fontSize: t.fontBody),
          ),
          const SizedBox(height: 14),
          Text(
            '1. Visit:',
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 4),
          SelectableText(
            flow.verificationUrl ?? '',
            style: const TextStyle(color: kAccent, fontSize: 14),
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
              color: kAccent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              flow.userCode ?? '',
              style: const TextStyle(
                color: kAccent,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  color: kAccent,
                  strokeWidth: 2,
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
