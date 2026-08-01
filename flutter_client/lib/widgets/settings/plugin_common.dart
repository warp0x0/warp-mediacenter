import 'package:flutter/material.dart';

import '../../theme/warp_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared chrome for the plugin settings screens.
//
// Mirrors the private helpers in settings_page.dart so plugin-rendered pages sit
// visually flush with the hand-built ones.  Kept here rather than exported from
// settings_page.dart because those are private and widening them for this would
// be a bigger change than duplicating twenty lines of styling.
// ─────────────────────────────────────────────────────────────────────────────

const kAccent = Color(0xFF0DB2E2);

class PluginSectionTitle extends StatelessWidget {
  final String text;
  final WarpTokens t;
  const PluginSectionTitle(this.text, this.t, {super.key});

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

class PluginCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const PluginCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: child,
    );
  }
}

class PluginHelpText extends StatelessWidget {
  final String text;
  final WarpTokens t;
  const PluginHelpText(this.text, this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
      ),
    );
  }
}

class PluginStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final WarpTokens t;
  const PluginStatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: t.fontSubtitle,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PluginEmptyHint extends StatelessWidget {
  final String text;
  final WarpTokens t;
  const PluginEmptyHint(this.text, this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(color: Colors.white30, fontSize: t.fontBody),
      ),
    );
  }
}
