import 'package:flutter/material.dart';

import '../theme.dart';

/// Ekranın altındaki kelime bilgisi şeridi.
/// Yalnızca gerçek Çeçence açıklama varsa görünür; yoksa hiç yer kaplamaz
/// (tasarım kuralı: sahte/çeviri metin gösterilmez).
class InfoStrip extends StatelessWidget {
  const InfoStrip({super.key, required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final value = text;
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(value),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkPill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
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
    );
  }
}
