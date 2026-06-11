import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Harf çarkının üstündeki seçilen kelime kapsülü.
/// Yanlış kelimede sallanır; doğru kelimede büyüyüp solarak kaybolur.
class WordCapsule extends StatefulWidget {
  const WordCapsule({
    super.key,
    required this.text,
    required this.shakeTick,
    required this.successTick,
    required this.successText,
  });

  /// Aktif seçim (boşsa kapsül gizlenir).
  final String text;

  final int shakeTick;
  final int successTick;

  /// Başarı animasyonunda gösterilecek son çözülen kelime.
  final String successText;

  @override
  State<WordCapsule> createState() => _WordCapsuleState();
}

class _WordCapsuleState extends State<WordCapsule>
    with TickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _success = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _tick = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
  );

  /// Sallanma sırasında gösterilmeye devam eden son seçim.
  String _shakeText = '';

  @override
  void didUpdateWidget(covariant WordCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTick != oldWidget.shakeTick) {
      _shakeText = oldWidget.text.isNotEmpty ? oldWidget.text : _shakeText;
      _shake.forward(from: 0);
    }
    if (widget.successTick != oldWidget.successTick) {
      _success.forward(from: 0);
    }
    // Yeni harf eklendiğinde minik canlılık tıklaması
    if (widget.text.length > oldWidget.text.length) {
      _tick.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _success.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_shake, _success, _tick]),
          builder: (context, _) {
            String text = widget.text;
            double opacity = 1;
            double scale = 1 + 0.06 * sin(pi * _tick.value);
            double dx = 0;

            if (text.isEmpty && _shake.isAnimating) {
              text = _shakeText;
            }
            if (_shake.isAnimating) {
              final v = _shake.value;
              dx = sin(v * pi * 5) * 9 * (1 - v);
            }
            if (text.isEmpty && _success.isAnimating) {
              text = widget.successText;
              final v = _success.value;
              opacity = 1 - Curves.easeIn.transform(v);
              scale = 1 + 0.16 * Curves.easeOut.transform(v);
            }
            if (text.isEmpty) return const SizedBox.shrink();

            return Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0).toDouble(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.goldLight, AppColors.gold],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x59D9961A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                        color: Colors.white,
                        shadows: kSoftTextShadow,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
