import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../../core/graphemes.dart';
import '../theme.dart';

/// Harf çarkı: yarı şeffaf daire üzerinde altın harf baloncukları.
/// Parmak veya mouse ile sürükleyerek harfler birleştirilir; seçilen harfler
/// arasında kalın altın çizgi çizilir. Karıştırmada baloncuklar dönerek yeni
/// konumlarına taşınır.
class LetterWheel extends StatefulWidget {
  const LetterWheel({
    super.key,
    required this.letters,
    required this.order,
    required this.selection,
    required this.size,
    required this.onEnterBubble,
    required this.onRelease,
    this.enabled = true,
  });

  /// Çark grafemleri (seviye harfleri, indeksle anılır).
  final List<String> letters;

  /// Baloncukların çark üzerindeki yerleşim permütasyonu.
  final List<int> order;

  /// Seçili harf indeksleri (çizgi bu sırayla çizilir).
  final List<int> selection;

  final double size;
  final ValueChanged<int> onEnterBubble;
  final VoidCallback onRelease;
  final bool enabled;

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel>
    with TickerProviderStateMixin {
  late final AnimationController _shuffleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: 1,
  );

  late List<double> _fromAngles;
  late List<double> _toAngles;

  // Parmak konumunu sürükleme sırasında sadece seçim çizgisinin yeniden
  // boyanmasını tetiklemek için izole bir notifier kullanıyoruz; böylece
  // baloncuklar ve şekiller gereksiz yere yeniden inşa edilmiyor.
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _fromAngles = _anglesFor(widget.order);
    _toAngles = List.of(_fromAngles);
  }

  @override
  void didUpdateWidget(covariant LetterWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.length != oldWidget.order.length) {
      _fromAngles = _anglesFor(widget.order);
      _toAngles = List.of(_fromAngles);
      _shuffleCtrl.value = 1;
    } else if (!_sameOrder(oldWidget.order, widget.order)) {
      _fromAngles = _currentAngles();
      _toAngles = _anglesFor(widget.order);
      _shuffleCtrl.forward(from: 0);
    }
  }

  bool _sameOrder(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Harf indeksine göre hedef açılar: slot s → -90° + s * 360°/n.
  List<double> _anglesFor(List<int> order) {
    final n = order.length;
    final angles = List<double>.filled(n, 0);
    for (var slot = 0; slot < n; slot++) {
      angles[order[slot]] = -pi / 2 + 2 * pi * slot / n;
    }
    return angles;
  }

  List<double> _currentAngles() {
    final t = Curves.easeInOutCubic.transform(_shuffleCtrl.value);
    return [
      for (var i = 0; i < _toAngles.length; i++)
        _fromAngles[i] + _shortDelta(_fromAngles[i], _toAngles[i]) * t,
    ];
  }

  double _shortDelta(double from, double to) {
    var d = (to - from) % (2 * pi);
    if (d > pi) d -= 2 * pi;
    return d;
  }

  double get _bubbleRadius {
    final n = widget.letters.length;
    final factor = n <= 4 ? 0.115 : (n == 5 ? 0.105 : 0.095);
    return widget.size * factor;
  }

  List<Offset> _positions(List<double> angles) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final ringR = widget.size / 2 - _bubbleRadius - 6;
    return [
      for (final a in angles) center + Offset(cos(a), sin(a)) * ringR,
    ];
  }

  void _hitTest(Offset local, List<Offset> positions) {
    var bestIndex = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < positions.length; i++) {
      final d = (positions[i] - local).distance;
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }
    if (bestIndex >= 0 && bestDist <= _bubbleRadius * 1.3) {
      widget.onEnterBubble(bestIndex);
    }
  }

  @override
  void dispose() {
    _shuffleCtrl.dispose();
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (!widget.enabled) return;
          setState(() => _dragging = true);
          _pointer.value = event.localPosition;
          _hitTest(event.localPosition, _positions(_currentAngles()));
        },
        onPointerMove: (event) {
          if (!_dragging) return;
          _pointer.value = event.localPosition;
          _hitTest(event.localPosition, _positions(_currentAngles()));
        },
        onPointerUp: (_) => _endDrag(),
        onPointerCancel: (_) => _endDrag(),
        child: AnimatedBuilder(
          animation: _shuffleCtrl,
          builder: (context, _) {
            final positions = _positions(_currentAngles());
            final bubbleR = _bubbleRadius;
            final selectedPoints = [
              for (final i in widget.selection) positions[i],
            ];

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Çark zemini (frosted glass on mobile, high opacity solid on web)
                ClipOval(
                  child: kIsWeb
                      ? Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xE6050C1A), // Dark translucent glass background
                            border: Border.all(
                              color: AppColors.wheelBorder,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                        )
                      : BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                          child: Container(
                            width: widget.size,
                            height: widget.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.wheelDisc,
                              border: Border.all(
                                color: AppColors.wheelBorder,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                // Çeçen koçboynuzu motifli orta madalyon (dekoratif)
                const Positioned.fill(
                  child: CustomPaint(painter: _OrnamentPainter()),
                ),
                // Seçim çizgisi (baloncukların altında) — sürükleme sırasında
                // parmak konumu yalnızca bu katmanı yeniden boyar; baloncuklar
                // ve diğer katmanlar etkilenmez.
                Positioned.fill(
                  child: RepaintBoundary(
                    child: ValueListenableBuilder<Offset?>(
                      valueListenable: _pointer,
                      builder: (context, pointer, _) {
                        return CustomPaint(
                          painter: _SelectionLinePainter(
                            points: selectedPoints,
                            pointer: _dragging && widget.selection.isNotEmpty
                                ? pointer
                                : null,
                            strokeWidth:
                                (bubbleR * 0.55).clamp(10.0, 18.0).toDouble(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                for (var i = 0; i < widget.letters.length; i++)
                  Positioned(
                    key: ValueKey('bubble_$i'),
                    left: positions[i].dx - bubbleR,
                    top: positions[i].dy - bubbleR,
                    child: _Bubble(
                      label: displayGrapheme(widget.letters[i]),
                      radius: bubbleR,
                      selected: widget.selection.contains(i),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _endDrag() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _pointer.value = null;
    widget.onRelease();
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({
    required this.label,
    required this.radius,
    required this.selected,
  });

  final String label;
  final double radius;
  final bool selected;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.radius;
    final selected = widget.selected;

    return Semantics(
      label: 'Harf ${widget.label}${widget.selected ? ", seçili" : ""}',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: selected ? 1.18 : (_hovered ? 1.08 : 1.0),
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          child: Container(
            width: r * 2,
            height: r * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected
                  ? const RadialGradient(
                      center: Alignment(-0.35, -0.42),
                      radius: 1.25,
                      colors: [
                        Color(0xFFFFF3C0),
                        Color(0xFFFFE48A),
                        AppColors.goldLight,
                        AppColors.gold,
                      ],
                      stops: [0, 0.35, 0.72, 1],
                    )
                  : const RadialGradient(
                      center: Alignment(-0.35, -0.42),
                      radius: 1.25,
                      colors: [
                        Color(0x3DFFFFFF),
                        Color(0x14FFFFFF),
                      ],
                    ),
              border: Border.all(
                color: selected ? const Color(0xCCFFF6D8) : const Color(0x33FFFFFF),
                width: selected ? 1.6 : 1.2,
              ),
              boxShadow: [
                if (selected)
                  const BoxShadow(
                    color: Color(0x99F5B62B),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                else
                  const BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(r * 0.16),
                child: FittedBox(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: AppText.displayFamily,
                      fontFamilyFallback: AppText.displayFallback,
                      fontSize: r * 0.96,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : const Color(0xFFE2F0FD),
                      shadows: selected
                          ? const [
                              Shadow(
                                color: Color(0x59000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : const [
                              Shadow(
                                color: Color(0x40000000),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionLinePainter extends CustomPainter {
  const _SelectionLinePainter({
    required this.points,
    required this.pointer,
    required this.strokeWidth,
  });

  final List<Offset> points;
  final Offset? pointer;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (pointer != null) {
      path.lineTo(pointer!.dx, pointer!.dy);
    }

    // Dış parlama + ana çizgi
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x66FFD75E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Tek nokta seçiliyken küçük bir başlangıç vurgusu
    if (points.length == 1 && pointer == null) {
      canvas.drawCircle(
        points.first,
        strokeWidth * 0.6,
        Paint()..color = AppColors.gold,
      );
    }

    // Çizgi ve sürükleme son noktası etrafında parıldayan parçacık izi (Particle Trail)
    if (pointer != null) {
      final rand = Random(pointer!.dx.hashCode ^ pointer!.dy.hashCode);
      final particlePaint = Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.82)
        ..style = PaintingStyle.fill;

      for (var i = 0; i < 8; i++) {
        final angle = rand.nextDouble() * 2 * pi;
        final distance = rand.nextDouble() * 20.0;
        final size = 1.2 + rand.nextDouble() * 3.2;
        final offset = pointer! + Offset(cos(angle), sin(angle)) * distance;
        
        if (i.isEven) {
          final glow = Paint()
            ..color = AppColors.goldLight.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
          canvas.drawCircle(offset, size * 2.0, glow);
        }
        canvas.drawCircle(offset, size, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionLinePainter oldDelegate) =>
      oldDelegate.pointer != pointer ||
      oldDelegate.strokeWidth != strokeWidth ||
      !_listEquals(oldDelegate.points, points);

  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Çark merkezindeki dekoratif madalyon: geleneksel Çeçen/Vainakh
/// ornamentlerindeki koçboynuzu (çift kıvrım) motifinin sadeleştirilmiş hali.
/// Tamamen vektörel; baloncukların ve seçim çizgisinin altında kalır.
class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ring = Paint()
      ..color = const Color(0x38FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.42, ring);
    canvas.drawCircle(center, radius * 0.27, ring);

    final horn = Paint()
      ..color = const Color(0xB3F5B62B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = const Color(0x80F5B62B);

    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(2 * pi * i / 8);
      canvas.translate(0, -radius * 0.345);
      final d = radius * 0.052;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(-d, 0), radius: d),
        -pi / 2,
        pi * 1.25,
        false,
        horn,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(d, 0), radius: d),
        -pi / 2,
        -pi * 1.25,
        false,
        horn,
      );
      canvas.drawCircle(Offset.zero, d * 0.22 < 1.2 ? 1.2 : d * 0.22, dot);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentPainter oldDelegate) => false;
}
