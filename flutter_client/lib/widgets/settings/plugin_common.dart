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

  /// A quieter variant for chips that label a *rule* rather than a state
  /// ("one at a time"), so they read as metadata beside a heading instead of
  /// competing with the status chips that report something live.
  final bool quiet;

  /// Small leading dot — used by state chips (Active/Enabled) so the status
  /// reads at a glance from across the room without relying on colour alone.
  final bool dot;

  const PluginStatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.t,
    this.quiet = false,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = quiet ? t.fontSubtitle * 0.82 : t.fontSubtitle * 0.92;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: quiet ? 8 : 10,
        vertical: quiet ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: quiet ? Colors.white.withAlpha(10) : color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: quiet ? Colors.white.withAlpha(28) : color.withAlpha(90),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: size * 0.4),
          ],
          Text(
            quiet ? label.toUpperCase() : label,
            style: TextStyle(
              color: quiet ? Colors.white54 : color,
              fontSize: size,
              fontWeight: FontWeight.w600,
              letterSpacing: quiet ? 0.8 : 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded-square glyph tile, matching the settings sidebar's own rows so the
/// plugin screens read as part of the same list rather than a bolted-on page.
class PluginIconTile extends StatelessWidget {
  final IconData icon;
  final WarpTokens t;

  /// Accent-tinted treatment, mirroring the sidebar's selected row.
  final bool active;
  final double scale;

  const PluginIconTile({
    super.key,
    required this.icon,
    required this.t,
    this.active = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final box = (t.fontBody * 2.0) * scale;
    return Container(
      width: box,
      height: box,
      decoration: BoxDecoration(
        color: active ? kAccent.withAlpha(38) : Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(box * 0.28),
        border: Border.all(
          color: active ? kAccent.withAlpha(110) : Colors.white.withAlpha(22),
        ),
      ),
      child: Icon(
        icon,
        size: box * 0.5,
        color: active ? kAccent : Colors.white54,
      ),
    );
  }
}

/// Hairline rule used to separate a category's heading from its contents.
class PluginDivider extends StatelessWidget {
  const PluginDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: Colors.white.withAlpha(16));
}

/// Small accent glyph + uppercase label, matching the Power page's card
/// headers exactly (`_CardHeader` there).
///
/// Every plugin settings page is assembled from these, so a tracker written by
/// someone else lands in the same visual grammar as the built-in screens
/// instead of inventing its own.
class PluginCardHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final WarpTokens t;

  const PluginCardHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return Row(
      children: [
        Icon(icon, size: scaler.scale(14), color: kAccent),
        SizedBox(width: scaler.scale(8)),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white54,
              fontSize: t.fontSubtitle - 1,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class PluginEmptyHint extends StatelessWidget {
  final String text;
  final WarpTokens t;

  /// Optional glyph — when given, the hint renders as a contained placeholder
  /// slot rather than a loose line of grey text, so an empty category still
  /// looks like a place something belongs instead of an unfinished screen.
  final IconData? icon;

  const PluginEmptyHint(this.text, this.t, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          text,
          style: TextStyle(color: Colors.white30, fontSize: t.fontBody),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: t.fontBody,
        vertical: t.fontBody * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: t.fontBody * 1.1, color: Colors.white24),
          SizedBox(width: t.fontBody * 0.6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white30, fontSize: t.fontSubtitle),
            ),
          ),
        ],
      ),
    );
  }
}
