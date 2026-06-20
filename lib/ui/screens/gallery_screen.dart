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
                    _Header(onBack: onBack, store: store, levels: levels),
                    const SizedBox(height: 8),
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
  const _Header({
    required this.onBack,
    required this.store,
    required this.levels,
  });

  final VoidCallback onBack;
  final ProgressStore store;
  final List<Level> levels;

  @override
  Widget build(BuildContext context) {
    final completed = store.completedLevels(levels.length);
    final total = levels.length - 1; // tutorial hariç
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          Row(
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
                      border: Border.all(
                        color: const Color(0xAAFFFFFF),
                        width: 1.5,
                      ),
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
          const SizedBox(height: 8),
          // Toplam ilerleme
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 22,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0x66FBF6EB)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.goldDark,
                            AppColors.gold,
                            AppColors.goldLight,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '$completed / $total ${Strings.t('level').toLowerCase()}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Color(0x99FFFFFF),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
  List<Level> get _gameLevels => levels.where((l) => l.id != 0).toList();

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

  String _packSubtitle(int pack) {
    switch (pack) {
      case 1:
        return 'Дош а, хьанж а';
      case 2:
        return 'Хьанж а, боьярш а';
      case 3:
        return 'ГӀирс а, ойла а';
      case 4:
        return 'Уггаре дара а, зор а';
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
          // ── Pack başlığı (+ progress) ──
          SliverToBoxAdapter(
            child: _PackHeader(
              title: _packTitle(entry.key),
              subtitle: _packSubtitle(entry.key),
              completed: entry.value
                  .where((l) => store.starsFor(l.id) > 0)
                  .length,
              total: entry.value.length,
              store: store,
            ),
          ),
          // ── Seviye ızgarası ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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

/// Paket başlığı — isim, alt başlık, tamamlanma yüzdesi.
class _PackHeader extends StatelessWidget {
  const _PackHeader({
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.total,
    required this.store,
  });

  final String title;
  final String subtitle;
  final int completed;
  final int total;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                title,
                style: const TextStyle(
                  fontFamily: AppText.displayFamily,
                  fontFamilyFallback: AppText.displayFallback,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                '$completed/$total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xCC122C3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0x99122C3D),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Pack progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0x44FBF6EB)),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: pct.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.goldDark,
                                AppColors.gold,
                                AppColors.goldLight,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
