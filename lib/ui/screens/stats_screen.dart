import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/progress_store.dart';
import '../theme.dart';
import '../widgets/scenic_background.dart';

/// İstatistik ekranı: oyuncunun tüm ilerleme verilerini görsel kartlarla
/// gösterir. Coin, çözülen/bonus kelime, en iyi seri, yıldız dağılımı.
class StatsScreen extends StatelessWidget {
  const StatsScreen({
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

  @override
  Widget build(BuildContext context) {
    final words = store.totalWordsSolved(levelCount);
    final bonus = store.totalBonusWords(levelCount);
    final streak = store.bestStreak;
    final completed = store.completedLevels(levelCount);
    final dist = store.starDistribution(levelCount);
    final totalGameLevels = levelCount - 1; // tutorial hariç
    final coinsEarned = store.totalCoinsEarned;
    final coinsSpent = store.totalCoinsSpent;
    final hintsUsed = store.totalHintsUsed;
    final totalWords = store.totalWordsEver;
    final totalBonus = store.totalBonusEver;

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
                    _StatsHeader(onBack: onBack),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        children: [
                          // ── Özet Kartları ──
                          _SummaryGrid(
                            coins: store.coins,
                            words: words,
                            streak: streak,
                          ),
                          const SizedBox(height: 20),

                          // ── Yıldız Dağılımı ──
                          _SectionLabel(
                            text: Strings.t('stats_stars_title'),
                          ),
                          const SizedBox(height: 10),
                          _StarBars(distribution: dist),
                          const SizedBox(height: 20),

                          // ── İlerleme Kartları ──
                          _SectionLabel(text: Strings.t('stats_total')),
                          const SizedBox(height: 10),
                          _ProgressCards(
                            completed: completed,
                            total: totalGameLevels,
                            bonus: bonus,
                            tutorialDone: store.tutorialDone,
                            coinsEarned: coinsEarned,
                            coinsSpent: coinsSpent,
                            hintsUsed: hintsUsed,
                            totalWordsEver: totalWords,
                            totalBonusEver: totalBonus,
                          ),
                          const SizedBox(height: 28),
                        ],
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

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.onBack});

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
            child: Text(
              Strings.t('stats'),
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

/// Üç büyük özet kartı: Coin, Kelime, Streak
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.coins,
    required this.words,
    required this.streak,
  });

  final int coins;
  final int words;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.monetization_on_rounded,
            label: Strings.t('stats_coins'),
            value: '$coins',
            iconColor: AppColors.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.text_fields_rounded,
            label: Strings.t('stats_words'),
            value: '$words',
            iconColor: AppColors.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: Strings.t('stats_streak'),
            value: '×$streak',
            iconColor: const Color(0xFFFF6B35),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0x99122C3D),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yıldız dağılımını gösteren 3 adet yatay progress bar.
class _StarBars extends StatelessWidget {
  const _StarBars({required this.distribution});

  final List<int> distribution;

  @override
  Widget build(BuildContext context) {
    final total = distribution.fold(0, (a, b) => a + b);
    final maxVal = distribution.reduce((a, b) => a > b ? a : b).toDouble();

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
        children: [
          _StarBar(
            stars: 3,
            count: distribution[2],
            total: total,
            maxVal: maxVal,
            color: AppColors.gold,
          ),
          const SizedBox(height: 10),
          _StarBar(
            stars: 2,
            count: distribution[1],
            total: total,
            maxVal: maxVal,
            color: const Color(0xFFE0B050),
          ),
          const SizedBox(height: 10),
          _StarBar(
            stars: 1,
            count: distribution[0],
            total: total,
            maxVal: maxVal,
            color: const Color(0xFFC89040),
          ),
        ],
      ),
    );
  }
}

class _StarBar extends StatelessWidget {
  const _StarBar({
    required this.stars,
    required this.count,
    required this.total,
    required this.maxVal,
    required this.color,
  });

  final int stars;
  final int count;
  final int total;
  final double maxVal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = maxVal > 0 ? count / maxVal : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Row(
            children: [
              ...List.generate(
                stars,
                (_) => const Icon(Icons.star_rounded, size: 16, color: AppColors.goldDark),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 18,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFE5D5BA)),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// İlerleme kartları: seviye tamamlama, bonus kelime, tutorial.
class _ProgressCards extends StatelessWidget {
  const _ProgressCards({
    required this.completed,
    required this.total,
    required this.bonus,
    required this.tutorialDone,
    required this.coinsEarned,
    required this.coinsSpent,
    required this.hintsUsed,
    required this.totalWordsEver,
    required this.totalBonusEver,
  });

  final int completed;
  final int total;
  final int bonus;
  final bool tutorialDone;
  final int coinsEarned;
  final int coinsSpent;
  final int hintsUsed;
  final int totalWordsEver;
  final int totalBonusEver;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProgressRow(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.gold,
          label: Strings.t('stats_levels_completed'),
          value: '$completed/$total',
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          icon: Icons.auto_awesome_rounded,
          iconColor: AppColors.gold,
          label: Strings.t('stats_bonus'),
          value: '$bonus',
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          icon: Icons.school_rounded,
          iconColor: tutorialDone
              ? const Color(0xFF5A8F6A)
              : const Color(0xFFBBBBBB),
          label: Strings.t('stats_tutorial'),
          value: tutorialDone ? '✓' : '—',
        ),
        const SizedBox(height: 16),

        // ── Kümülatif istatistikler ──
        _SectionLabel(text: Strings.t('stats_lifetime')),
        const SizedBox(height: 10),
        _ProgressRow(
          icon: Icons.text_fields_rounded,
          iconColor: AppColors.gold,
          label: Strings.t('stats_words_solved'),
          value: '$totalWordsEver',
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF8B6FC0),
          label: Strings.t('stats_bonus_found'),
          value: '$totalBonusEver',
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          icon: Icons.monetization_on_rounded,
          iconColor: AppColors.gold,
          label: Strings.t('stats_coins_earned'),
          value: '$coinsEarned',
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          icon: Icons.shopping_cart_rounded,
          iconColor: const Color(0xFFE08B50),
          label: Strings.t('stats_coins_spent'),
          value: '$coinsSpent',
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          icon: Icons.lightbulb_rounded,
          iconColor: const Color(0xFFFFD700),
          label: Strings.t('stats_hints'),
          value: '$hintsUsed',
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x14D9961A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
