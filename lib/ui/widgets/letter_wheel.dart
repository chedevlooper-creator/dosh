import 'dart:math';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _shuffleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: 1,
  );

  late List<double> _fromAngles;
  late List<double> _toAngles;

  Offset? _pointer;
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
          _dragging = true;
          setState(() => _pointer = event.localPosition);
          _hitTest(event.localPosition, _positions(_currentAngles()));
        },
        onPointerMove: (event) {
          if (!_dragging) return;
          setState(() => _pointer = event.localPosition);
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
                // Çark zemini
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.wheelDisc,
                    border: Border.all(
                      color: const Color(0x66FFFFFF),
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
                // Çeçen koçboynuzu motifli orta madalyon (dekoratif)
                const Positioned.fill(
                  child: CustomPaint(painter: _OrnamentPainter()),
                ),
                // Seçim çizgisi (baloncukların altında)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SelectionLinePainter(
                      points: selectedPoints,
                      pointer: _dragging && widget.selection.isNotEmpty
                          ? _pointer
                          : null,
                      strokeWidth:
                          (bubbleR * 0.55).clamp(10.0, 18.0).toDouble(),
                    ),
                  ),
                ),
                for (var i = 0; i < widget.letters.length; i++)
                  Positioned(
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
    _dragging = false;
    setState(() => _pointer = null);
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

    return MouseRegion(
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
            // Seçili harfler için altın parlama efekti; seçilmemişler için şeffaf zemin.
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
                : null,
            border: selected
                ? Border.all(color: const Color(0xCCFFF6D8), width: 1.6)
                : null,
            boxShadow: [
              if (selected)
                const BoxShadow(
                  color: Color(0x99F5B62B),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(r * 0.16),
              // Digraflar (ХЬ, КӀ...) tek karakterden geniştir; scaleDown
              // yalnızca sığmayanı küçültür, tek harfleri büyütmez.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: AppText.displayFamily,
                    fontFamilyFallback: AppText.displayFallback,
                    fontSize: r * 0.96,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.ink,
                    shadows: selected
                        ? const [
                            Shadow(
                              color: Color(0x59000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
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
      ..color = const Color(0x6BD9961A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = const Color(0x59D9961A);

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
