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
    this.settingsIcon = Icons.settings_rounded,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onGallery;
  final VoidCallback? onSettings;
  final IconData settingsIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _BarSlot(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 8),
          _BarSlot(icon: Icons.menu_rounded, onTap: onMenu),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x661E2B33), Color(0x401E2B33)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x55FFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
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
          _BarSlot(icon: Icons.collections_rounded, onTap: onGallery),
          const SizedBox(width: 8),
          _BarSlot(icon: settingsIcon, onTap: onSettings),
        ],
      ),
    );
  }
}

class _BarSlot extends StatelessWidget {
  const _BarSlot({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return const SizedBox(width: 44, height: 44);
    return RoundIconButton(icon: icon, onTap: onTap);
  }
}
