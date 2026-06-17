import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../theme.dart';
import '../widgets/scenic_background.dart';

/// Galeri ekranı: tüm seviyeler ızgara layout'ta gösterilir, her seviye
/// rozet + yıldız + durum ile gösterilir. Tamamlanmış seviyeler yeniden
/// oynanabilir; kilitli seviyeler o sıraya gelene kadar devre dışı.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({
    super.key,
    required this.levels,
    required this.store,
    required this.theme,
    required this.onPick,
    required this.onBack,
  });

  final List<Level> levels;
  final ProgressStore store;
  final SceneTheme theme;
  final ValueChanged<int> onPick;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScenicBackground(showPlayArea: false, theme: theme),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: GameConfig.maxContentWidth,
                ),
                child: Column(
                  children: [
                    _Header(onBack: onBack),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _GalleryGrid(
                        levels: levels,
                        store: store,
                        onPick: onPick,
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Semantics(
            label: 'Ana sayfaya dön',
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
          const Expanded(
            child: Center(
              child: Text(
                'Дош',
                style: TextStyle(
                  fontFamily: AppText.displayFamily,
                  fontFamilyFallback: AppText.displayFallback,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({
    required this.levels,
    required this.store,
    required this.onPick,
  });

  final List<Level> levels;
  final ProgressStore store;
  final ValueChanged<int> onPick;

  /// Tutorial seviyesi (id=0) hariç seviyeler.
  List<Level> get _gameLevels =>
      levels.where((l) => l.id != 0).toList();

  Map<int, List<Level>> get _packs {
    final map = <int, List<Level>>{};
    for (final l in _gameLevels) {
      map.putIfAbsent(l.pack, () => []).add(l);
    }
    return map;
  }

  String _packTitle(int pack) {
    switch (pack) {
      case 1:
        return 'Дога / Хьанж';
      case 2:
        return 'Хьанж / Боьярш';
      case 3:
        return 'ГӀирс / Ойла';
      case 4:
        return 'Уггаре дара / Зор';
      default:
        return 'Дешнаш';
    }
  }

  void _showLockedHint(BuildContext context, int levelId) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Strings.t('level_locked_hint')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packs = _packs;
    return CustomScrollView(
      slivers: [
        for (final entry in packs.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _packTitle(entry.key),
                    style: const TextStyle(
                      fontFamily: AppText.displayFamily,
                      fontFamilyFallback: AppText.displayFallback,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, i) {
                final level = entry.value[i];
                final stars = store.starsFor(level.id);
                final locked = !store.isLevelUnlocked(level.id);
                return _LevelTile(
                  level: level,
                  stars: stars,
                  locked: locked,
                  onTap: locked
                      ? () => _showLockedHint(context, level.id)
                      : () {
                          final originalIndex = levels.indexOf(level);
                          onPick(originalIndex);
                        },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.stars,
    required this.locked,
    required this.onTap,
  });

  final Level level;
  final int stars;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = stars > 0;
    return Semantics(
      label: 'Seviye ${level.id}, '
          '${completed ? "$stars yıldız" : locked ? "kilitli" : "tamamlanmadı"}',
      button: !locked,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: locked
                ? const Color(0x80D9D0C0)
                : const Color(0xEAFBF6EB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: completed
                  ? AppColors.gold
                  : locked
                      ? const Color(0x30FFFFFF)
                      : const Color(0x40FFFFFF),
              width: completed ? 1.6 : (locked ? 1.0 : 1.0),
            ),
            boxShadow: locked
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: locked ? const Color(0xFFBBBBBB) : null,
                  gradient: locked
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: completed
                              ? const [
                                  AppColors.goldLight,
                                  AppColors.gold,
                                  AppColors.goldDark,
                                ]
                              : const [
                                  Color(0xFFCCCCCC),
                                  Color(0xFFAAAAAA),
                                ],
                        ),
                ),
                child: locked
                    ? const Icon(Icons.lock_rounded,
                        size: 20, color: Color(0xFF999999))
                    : Text(
                        '${level.id}',
                        style: TextStyle(
                          color: completed ? AppColors.ink : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      locked
                          ? Icons.lock_rounded
                          : (i < stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded),
                      size: locked ? 12 : 14,
                      color: locked
                          ? const Color(0xFFAAAAAA)
                          : AppColors.goldDark,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
