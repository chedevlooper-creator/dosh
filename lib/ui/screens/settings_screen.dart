import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/game_sound.dart';
import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/progress_store.dart';
import '../theme.dart';
import '../widgets/scenic_background.dart';

/// Ayarlar ekranı: tema seçimi, ses, nasıl oynanır (tutorial tekrarı),
/// oyun verilerini sıfırlama.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.sound,
    required this.themeIndex,
    required this.onThemeChanged,
    required this.onHowToPlay,
    required this.onBack,
  });

  final ProgressStore store;
  final GameSound sound;
  final int themeIndex;
  final ValueChanged<int> onThemeChanged;
  final VoidCallback onHowToPlay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScenicBackground(
            showPlayArea: false,
            theme: SceneTheme.values[themeIndex],
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: GameConfig.maxContentWidth,
                ),
                child: Column(
                  children: [
                    _SettingsHeader(onBack: onBack),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _SettingsBody(
                        store: store,
                        sound: sound,
                        themeIndex: themeIndex,
                        onThemeChanged: onThemeChanged,
                        onHowToPlay: onHowToPlay,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Semantics(
            label: 'Geri',
            button: true,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xDDFBF6EB),
                  border: Border.all(color: const Color(0xAAFFFFFF), width: 1.5),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Strings.t('settings'),
              style: const TextStyle(
                fontFamily: AppText.displayFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.store,
    required this.sound,
    required this.themeIndex,
    required this.onThemeChanged,
    required this.onHowToPlay,
  });

  final ProgressStore store;
  final GameSound sound;
  final int themeIndex;
  final ValueChanged<int> onThemeChanged;
  final VoidCallback onHowToPlay;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // ── Tema Seçimi ──
        _SectionLabel(text: Strings.t('settings_theme')),
        const SizedBox(height: 10),
        _ThemeSelector(
          currentIndex: themeIndex,
          onChanged: onThemeChanged,
        ),
        const SizedBox(height: 28),

        // ── Ses ──
        _SectionLabel(text: Strings.t('settings_sound')),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: sound,
          builder: (context, _) => _SettingsTile(
            icon: sound.enabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            title: sound.enabled ? 'Açık' : 'Kapalı',
            trailing: Switch.adaptive(
              value: sound.enabled,
              activeColor: AppColors.gold,
              onChanged: (_) => sound.toggle(),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Nasıl Oynanır ──
        _SectionLabel(text: Strings.t('settings_tutorial')),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.school_rounded,
          title: Strings.t('settings_how_to_play'),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
          onTap: onHowToPlay,
        ),
        const SizedBox(height: 28),

        // ── Oyun Sıfırlama ──
        _SectionLabel(text: Strings.t('settings_reset')),
        const SizedBox(height: 10),
        _ResetTile(
            store: store,
            sound: sound,
            onThemeChanged: onThemeChanged,
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0x99122C3D),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xEAFBF6EB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x14D9961A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.goldDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// 3 tema arasından seçim yapmak için yatay kaydırmalı kartlar.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final themes = [
      _ThemeOption(
        index: 0,
        label: Strings.t('settings_theme_caucasus'),
        icon: Icons.wb_sunny_rounded,
        colors: const [Color(0xFF3F86C7), Color(0xFFF6E3BE)],
      ),
      _ThemeOption(
        index: 1,
        label: Strings.t('settings_theme_night'),
        icon: Icons.nightlight_round,
        colors: const [Color(0xFF0A1628), Color(0xFF2A5280)],
      ),
      _ThemeOption(
        index: 2,
        label: Strings.t('settings_theme_forest'),
        icon: Icons.forest_rounded,
        colors: const [Color(0xFF5B9F6B), Color(0xFFD4E8C8)],
      ),
    ];

    return Row(
      children: [
        for (final theme in themes) ...[
          if (theme.index > 0) const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(theme.index),
              child: AnimatedContainer(
                duration: AppMotion.base,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: currentIndex == theme.index
                        ? AppColors.gold
                        : const Color(0x30FFFFFF),
                    width: currentIndex == theme.index ? 2.0 : 1.0,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: theme.colors,
                  ),
                  boxShadow: currentIndex == theme.index
                      ? [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      theme.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      theme.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeOption {
  const _ThemeOption({
    required this.index,
    required this.label,
    required this.icon,
    required this.colors,
  });

  final int index;
  final String label;
  final IconData icon;
  final List<Color> colors;
}

/// Oyun verilerini sıfırlama kartı (onay dialog'u ile).
class _ResetTile extends StatefulWidget {
  const _ResetTile({
    required this.store,
    required this.sound,
    this.onThemeChanged,
  });

  final ProgressStore store;
  final GameSound sound;
  final ValueChanged<int>? onThemeChanged;

  @override
  State<_ResetTile> createState() => _ResetTileState();
}

class _ResetTileState extends State<_ResetTile> {
  bool _resetting = false;

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFBF6EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          Strings.t('settings_reset_confirm'),
          style: const TextStyle(
            fontFamily: AppText.displayFamily,
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hayır',
              style: const TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Evet, sıfırla',
              style: TextStyle(color: Color(0xFFCC3333), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _resetting = true);
      try {
        final soundOn = widget.sound.enabled;
        await widget.store.clearAll();
        await widget.store.setSoundOn(soundOn);
        // Tema varsayılana döndü — üst state'i de güncelle
        widget.onThemeChanged?.call(0);
        HapticFeedback.heavyImpact();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Strings.t('settings_reset_done')),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1500),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _resetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.delete_sweep_rounded,
      title: _resetting ? 'Sıfırlanıyor...' : Strings.t('settings_reset'),
      trailing: _resetting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded, color: Color(0xFFCC6666)),
      onTap: _resetting ? null : () => _confirmReset(context),
    );
  }
}
