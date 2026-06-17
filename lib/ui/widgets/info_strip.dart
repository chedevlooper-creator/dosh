import 'package:flutter/material.dart';

import '../theme.dart';

/// Ekranın altındaki kelime bilgisi şeridi.
/// Yalnızca gerçek Çeçence açıklama varsa görünür; yoksa hiç yer kaplamaz.
/// [isBonus] = true ise yanında ✨ Bonus rozeti gösterilir.
class InfoStrip extends StatelessWidget {
  const InfoStrip({super.key, required this.text, this.isBonus = false});

  final String? text;
  final bool isBonus;

  @override
  Widget build(BuildContext context) {
    final value = text;
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey('${value}_$isBonus'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkPill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBonus) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '✦ Bonus',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.3,
                  shadows: kSoftTextShadow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
