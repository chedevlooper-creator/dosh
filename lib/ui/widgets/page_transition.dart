import 'package:flutter/material.dart';

/// Yön bilinçli sayfa geçişi — ileri giderken slide-right,
/// geri gelirken slide-left, fade ile harmanlanır.
///
/// Kullanım: `PageTransitionSwitcher` widget'ını `AnimatedSwitcher`
/// yerine kullan, `direction` parametresiyle yönü belirt.
enum TransitionDirection { forward, backward, none }

class PageTransitionSwitcher extends StatelessWidget {
  const PageTransitionSwitcher({
    super.key,
    required this.child,
    required this.direction,
    this.duration = const Duration(milliseconds: 380),
  });

  final Widget child;
  final TransitionDirection direction;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final offset = switch (direction) {
      TransitionDirection.forward => const Offset(0.12, 0),
      TransitionDirection.backward => const Offset(-0.12, 0),
      TransitionDirection.none => Offset.zero,
    };

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        if (direction == TransitionDirection.none) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: offset,
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
