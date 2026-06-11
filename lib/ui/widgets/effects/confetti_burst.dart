import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Bağımlılıksız, hafif konfeti efekti. [trigger] her değiştiğinde üstten
/// aşağı süzülen altın/beyaz/yeşil parçacıklarla kutlama oynatır.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.trigger});

  final int trigger;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  List<_Particle> _particles = const [];

  @override
  void didUpdateWidget(covariant ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      final random = Random(widget.trigger * 9973);
      _particles = List.generate(90, (_) => _Particle.random(random));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          if (!_ctrl.isAnimating) return const SizedBox.shrink();
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_particles, _ctrl.value),
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x0,
    required this.y0,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.spin,
    required this.circle,
  });

  /// Konumlar 0..1 normalize; painter ekran boyutuna ölçekler.
  final double x0;
  final double y0;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double spin;
  final bool circle;

  factory _Particle.random(Random r) {
    const colors = [
      AppColors.gold,
      AppColors.goldLight,
      Colors.white,
      AppColors.ridgeNearDark,
      AppColors.skyMid,
    ];
    return _Particle(
      x0: r.nextDouble(),
      y0: -0.05 - r.nextDouble() * 0.18,
      vx: (r.nextDouble() - 0.5) * 0.22,
      vy: 0.40 + r.nextDouble() * 0.55,
      size: 5 + r.nextDouble() * 7,
      color: colors[r.nextInt(colors.length)],
      spin: (r.nextDouble() - 0.5) * 10,
      circle: r.nextBool(),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = t < 0.72 ? 1.0 : (1 - (t - 0.72) / 0.28).clamp(0.0, 1.0);
    final paint = Paint();
    for (final p in particles) {
      final x = (p.x0 + p.vx * t) * size.width;
      final y = (p.y0 + p.vy * t + 0.42 * t * t) * size.height;
      if (y < -20 || y > size.height + 20) continue;
      paint.color = p.color.withAlpha((255 * opacity).round());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.62,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.particles != particles;
}
