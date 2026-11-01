import 'package:flutter/material.dart';

/// Entrance only: never retains outgoing evidence or an invalidated result.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = delayMs.clamp(0, 300);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delay),
      child: child,
      builder: (context, value, child) {
        final t = Curves.easeOutCubic
            .transform(((value * (300 + delay) - delay) / 300).clamp(0, 1));
        return Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 20 * (1 - t)), child: child));
      },
    );
  }
}
