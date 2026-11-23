import 'package:flutter/material.dart';

/// Staggered fade-up animation used for list and grid items across the app.
class FadeUp extends StatelessWidget {
  const FadeUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 16.0,
    this.duration = const Duration(milliseconds: 300),
  });

  final Widget child;
  final Duration delay;
  final double offsetY;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, offsetY * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
