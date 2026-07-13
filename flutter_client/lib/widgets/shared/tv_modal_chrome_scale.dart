import 'package:flutter/material.dart';

class TvModalChromeScale extends StatelessWidget {
  final Widget child;

  const TvModalChromeScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.textScaler.scale(1);
    if (scale <= 1.01) return child;

    return Transform.scale(
      scale: scale,
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.noScaling),
        child: child,
      ),
    );
  }
}
