import 'package:flutter/material.dart';

import '../../core/achievements.dart';
import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/progress_store.dart';
import '../theme.dart';
import '../widgets/scenic_background.dart';

/// Oyuncunun ilerlemesinden türetilen başarım/rozet ekranı.
///
/// Yeni bir sayaç saklamaz; tamamen [ProgressStore]'daki mevcut kümülatif
/// istatistiklerden (`core/achievements.dart` aracılığıyla) hesaplanır.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({
    super.key,
    required this.store,
    required this.theme,
    required this.levelCount,
    required this.onBack,
  });

  final ProgressStore store;
  final SceneTheme theme;
  final int levelCount;
  final VoidCallback onBack;

  static const Map<String, IconData> _icons = {
    'words': Icons.text_fields_rounded,
    'bonus': Icons.auto_awesome_rounded,
    'coins': Icons.monetization_on_rounded,
    'streak': Icons.local_fire_department_rounded,
    'levels': Icons.flag_rounded,
    'perfect': Icons.star_rounded,
    'timeAttack': Icons.bolt_rounded,
    'tutorial': Icons.school_rounded,
  };

  int _valueFor(String id) {
    switch (id) {
      case 'words':
        return store.totalWordsEver;
      case 'bonus':
        return store.totalBonusEver;
      case 'coins':
        return store.totalCoinsEarned;
      case 'streak':
        return store.bestStreak;
      case 'levels':
        return store.completedLevels(levelCount);
      case 'perfect':
        return store.starDistribution(levelCount)[2];
      case 'timeAttack':
        return store.timeAttackHighScore;
      case 'tutorial':
        return store.tutorialDone ? 1 : 0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progresses = [
      for (final def in Achievements.defs)
        Achievements.progressFor(def, _valueFor(def.id)),
    ];
    final unlocked = Achievements.unlockedCount(progresses);

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
                    _AchievementsHeader(
                      onBack: onBack,
                      unlocked: unlocked,
                      total: progresses.length,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: progresses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = progresses[index];
                          return _AchievementCard(
                            progress: p,
                            icon: _icons[p.def.id] ?? Icons.emoji_events_rounded,
                            title: Strings.t('ach_${p.def.id}_title'),
                            unit: Strings.t('ach_${p.def.id}_unit'),
                          );
                        },
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

class _AchievementsHeader extends StatelessWidget {
  const _AchievementsHeader({
    required this.onBack,
    required this.unlocked,
    required this.total,
  });

  final VoidCallback onBack;
  final int unlocked;
  final int total;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Strings.t('achievements'),
                  style: const TextStyle(
                    fontFamily: AppText.displayFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '$unlocked/$total ${Strings.t('achievements_unlocked')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0x99122C3D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.progress,
    required this.icon,
    required this.title,
    required this.unit,
  });

  final AchievementProgress progress;
  final IconData icon;
  final String title;
  final String unit;

  Color get _tierColor {
    switch (progress.tier) {
      case AchievementTier.gold:
        return AppColors.gold;
      case AchievementTier.silver:
        return const Color(0xFFB8C2CC);
      case AchievementTier.bronze:
        return const Color(0xFFCD8A5A);
      case AchievementTier.none:
        return const Color(0xFFBBBBBB);
    }
  }

  String get _tierLabel {
    switch (progress.tier) {
      case AchievementTier.gold:
        return Strings.t('achievements_tier_gold');
      case AchievementTier.silver:
        return Strings.t('achievements_tier_silver');
      case AchievementTier.bronze:
        return Strings.t('achievements_tier_bronze');
      case AchievementTier.none:
        return Strings.t('achievements_tier_locked');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = progress.tier == AchievementTier.none;
    final single = progress.def.isSingleTier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xEAFBF6EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x40FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: locked ? 0.12 : 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: locked ? const Color(0xFFAAAAAA) : _tierColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: locked ? const Color(0x99122C3D) : AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      single
                          ? unit
                          : '${progress.value}/${progress.nextThreshold ?? progress.def.gold} $unit',
                      style: const TextStyle(
                        color: Color(0x99122C3D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: locked ? 0.12 : 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _tierLabel,
                  style: TextStyle(
                    color: locked ? const Color(0x99122C3D) : _tierColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (!single) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFE5D5BA)),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.progressToNext,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_tierColor, _tierColor.withValues(alpha: 0.7)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
