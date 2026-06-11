import 'package:flutter/material.dart';

import '../theme.dart';
import 'round_icon_button.dart';

/// Üst oyun barı: solda geri + menü, ortada bölüm adı, sağda galeri + ayarlar.
/// Bölüm adı localization anahtarından gelir; gerçek Çeçence karşılık yoksa
/// teknik anahtar görünür (tasarım kuralı).
class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    this.onBack,
    this.onMenu,
    this.onGallery,
    this.onSettings,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onGallery;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 8),
          RoundIconButton(icon: Icons.menu_rounded, onTap: onMenu),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.darkPill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    shadows: kSoftTextShadow,
                  ),
                ),
              ),
            ),
          ),
          RoundIconButton(icon: Icons.collections_rounded, onTap: onGallery),
          const SizedBox(width: 8),
          RoundIconButton(icon: Icons.settings_rounded, onTap: onSettings),
        ],
      ),
    );
  }
}
