import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/progress_store.dart';
import '../theme.dart';
import '../widgets/animated_count.dart';
import '../widgets/scenic_background.dart';

/// Sözlük ekranı: oyuncunun çözdüğü tüm kelimeleri Çeçence → Türkçe
/// anlamlarıyla birlikte alfabetik sırayla listeler. Arama çubuğu ile
/// filtrelenebilir.
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({
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
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allWords = widget.store.allSolvedWords(widget.levelCount);
    // Aynı kelime birden çok seviyede çözülmüş olabilir — benzersiz yap
    final unique = <String, (int levelId, bool isBonus)>{};
    for (final (word, levelId, isBonus) in allWords) {
      unique[word] = (levelId, isBonus);
    }
    // Alfabetik sırala
    var entries = unique.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    // Arama filtresi
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      entries = entries.where((e) {
        final meaning = Strings.tOrNull('info_${e.key}') ?? '';
        return e.key.contains(q) || meaning.toLowerCase().contains(q);
      }).toList();
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScenicBackground(showPlayArea: false, theme: widget.theme),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: GameConfig.maxContentWidth,
                ),
                child: Column(
                  children: [
                    _DictionaryHeader(onBack: widget.onBack),
                    const SizedBox(height: 4),
                    // Arama çubuğu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SearchBar(
                        controller: _searchCtrl,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Sayaç
                    if (entries.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            AnimatedCount(
                              target: entries.length,
                              style: const TextStyle(
                                color: Color(0x99122C3D),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' ${Strings.t('dictionary_word')}',
                              style: const TextStyle(
                                color: Color(0x99122C3D),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Liste
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text(
                                _search.isEmpty
                                    ? Strings.t('dictionary_empty')
                                    : Strings.t('dictionary_no_match'),
                                style: const TextStyle(
                                  color: Color(0x99122C3D),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, i) {
                                final entry = entries[i];
                                final meaning = Strings.tOrNull(
                                  'info_${entry.key}',
                                );
                                return StaggerItem(
                                  index: i,
                                  child: _WordTile(
                                    word: entry.key,
                                    meaning: meaning,
                                    levelId: entry.value.$1,
                                    isBonus: entry.value.$2,
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
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

class _DictionaryHeader extends StatelessWidget {
  const _DictionaryHeader({required this.onBack});

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
              Strings.t('dictionary'),
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

/// Arama çubuğu — büyüteç ikonu + metin alanı + temizle butonu.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEAFBF6EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x60FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: Strings.t('dictionary_search'),
          hintStyle: const TextStyle(
            color: Color(0x99122C3D),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0x99122C3D),
            size: 22,
          ),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0x99122C3D),
                      size: 20,
                    ),
                    onPressed: controller.clear,
                  )
                : const SizedBox.shrink(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Tek bir kelime satırı: Çeçence yazılış + Türkçe anlam + seviye rozeti.
class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.meaning,
    required this.levelId,
    required this.isBonus,
  });

  final String word;
  final String? meaning;
  final int levelId;
  final bool isBonus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xEAFBF6EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x40FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Çeçence kelime
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppText.displayFamily,
                    fontFamilyFallback: AppText.displayFallback,
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meaning ?? '—',
                  style: TextStyle(
                    color: meaning != null
                        ? const Color(0x99122C3D)
                        : const Color(0x66CCCCCC),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontStyle: meaning != null
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Seviye rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isBonus
                  ? const Color(0x14D9961A)
                  : const Color(0x14122C3D),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isBonus
                  ? '☆${levelId > 0 ? levelId : ""}'
                  : 'Lv.$levelId',
              style: TextStyle(
                color: isBonus ? AppColors.goldDark : AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
