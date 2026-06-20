import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/game_sound.dart';
import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../theme.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/scenic_background.dart';

/// Zamana Karşı Yarış (Time Attack) Ekranı:
/// Oyuncu 60 saniye içinde çarktaki harflerden olabildiğince çok
/// geçerli Çeçence kelime türetmeye çalışır. Her doğru kelimede süre ve puan kazanır.
class TimeAttackScreen extends StatefulWidget {
  const TimeAttackScreen({
    super.key,
    required this.levels,
    required this.store,
    required this.sound,
    required this.theme,
    required this.onBack,
  });

  final List<Level> levels;
  final ProgressStore store;
  final GameSound sound;
  final SceneTheme theme;
  final VoidCallback onBack;

  @override
  State<TimeAttackScreen> createState() => _TimeAttackScreenState();
}

class _TimeAttackScreenState extends State<TimeAttackScreen> {
  late final Random _random = Random();
  late Set<String> _allValidWords;

  // Oyun Durumları
  int _score = 0;
  int _highScore = 0;
  int _timeLeft = 60;
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _countdown = 3;
  bool _isCountdownActive = true;

  List<String> _currentLetters = [];
  List<int> _wheelOrder = [];
  List<int> _selection = [];
  final List<String> _foundWords = [];

  Timer? _gameTimer;
  Timer? _countdownTimer;

  // Görsel Bildirim Geri Bildirimi (+3s, -1s, Zaten Bulundu vb.)
  String? _feedbackText;
  Color? _feedbackColor;
  Timer? _feedbackTimer;
  int _feedbackTick = 0;

  int _coinsGained = 0;
  bool _isNewRecord = false;

  @override
  void initState() {
    super.initState();
    _highScore = widget.store.timeAttackHighScore;
    _buildWordPool();
    _startNewSession();
  }

  void _buildWordPool() {
    _allValidWords = {};
    for (final lvl in widget.levels) {
      for (final w in lvl.words) {
        _allValidWords.add(w.word.toLowerCase());
      }
      for (final w in lvl.bonusWords) {
        _allValidWords.add(w.toLowerCase());
      }
    }
  }

  void _startNewSession() {
    _score = 0;
    _timeLeft = 60;
    _isPlaying = false;
    _isGameOver = false;
    _countdown = 3;
    _isCountdownActive = true;
    _isNewRecord = false;
    _foundWords.clear();
    _selection.clear();
    _feedbackText = null;
    _feedbackTimer?.cancel();
    _gameTimer?.cancel();
    _countdownTimer?.cancel();

    _pickNewLetters();
    _startCountdown();
  }

  void _pickNewLetters() {
    // 4 veya daha fazla harfe sahip rastgele bir bölümün harflerini al
    final filteredLevels =
        widget.levels.where((lvl) => lvl.letters.length >= 4).toList();
    final chosenLvl = filteredLevels.isNotEmpty
        ? filteredLevels[_random.nextInt(filteredLevels.length)]
        : widget.levels[_random.nextInt(widget.levels.length)];

    _currentLetters = List.from(chosenLvl.letters);
    _wheelOrder = List.generate(_currentLetters.length, (i) => i);
    _selection.clear();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
          widget.sound.play(SoundCue.tap);
        } else {
          _countdownTimer?.cancel();
          _isCountdownActive = false;
          _isPlaying = true;
          widget.sound.play(SoundCue.solve); // Başlama sinyali
          _startGameTimer();
        }
      });
    });
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 1) {
          _timeLeft--;
        } else {
          _timeLeft = 0;
          _gameTimer?.cancel();
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _isPlaying = false;
    _isGameOver = true;
    widget.sound.play(SoundCue.complete);

    _coinsGained = _score ~/ 10;
    _isNewRecord = _score > _highScore;

    if (_isNewRecord) {
      _highScore = _score;
      unawaited(widget.store.setTimeAttackHighScore(_score));
    }
    if (_coinsGained > 0) {
      unawaited(widget.store.setCoins(widget.store.coins + _coinsGained));
      unawaited(widget.store.addCoinsEarned(_coinsGained));
    }
  }

  void _enterBubble(int letterIndex) {
    if (!_isPlaying) return;
    if (_selection.contains(letterIndex)) {
      final len = _selection.length;
      if (len > 1 && _selection[len - 2] == letterIndex) {
        setState(() {
          _selection.removeLast();
          widget.sound.play(SoundCue.tap);
          HapticFeedback.selectionClick();
        });
      }
    } else {
      setState(() {
        _selection.add(letterIndex);
        widget.sound.play(SoundCue.tap);
        HapticFeedback.selectionClick();
      });
    }
  }

  void _releaseSelection() {
    if (!_isPlaying || _selection.isEmpty) return;

    final word = _selection.map((i) => _currentLetters[i]).join().toLowerCase();
    _selection.clear();

    if (word.length < 2) {
      setState(() {});
      return;
    }

    if (_foundWords.contains(word)) {
      _triggerFeedback(Strings.t('time_attack_already_found'), Colors.orange);
      widget.sound.play(SoundCue.wrong);
    } else if (_allValidWords.contains(word)) {
      final bonus = word.length >= 4 ? 5 : 3;
      setState(() {
        _foundWords.insert(0, word);
        _score += word.length * 10;
        _timeLeft = min(99, _timeLeft + bonus);
      });
      _triggerFeedback("+$bonus" "s", Colors.green);
      widget.sound.play(SoundCue.solve);
    } else {
      setState(() {
        _timeLeft = max(0, _timeLeft - 1);
      });
      _triggerFeedback("-1s", Colors.red);
      widget.sound.play(SoundCue.wrong);

      if (_timeLeft == 0) {
        _gameTimer?.cancel();
        _endGame();
      }
    }
  }

  void _triggerFeedback(String text, Color color) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackText = text;
      _feedbackColor = color;
      _feedbackTick++;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _feedbackText = null;
        });
      }
    });
  }

  void _shuffle() {
    if (!_isPlaying) return;
    widget.sound.play(SoundCue.shuffle);
    setState(() {
      _wheelOrder.shuffle();
    });
  }

  void _refreshWheel() {
    if (!_isPlaying) return;
    if (widget.store.coins < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yetersiz Coin! (15 Coin gerekli)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        ),
      );
      return;
    }

    widget.sound.play(SoundCue.shuffle);
    unawaited(widget.store.setCoins(widget.store.coins - 15));
    unawaited(widget.store.addCoinsSpent(15));
    setState(() {
      _pickNewLetters();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @visibleForTesting
  bool get isPlaying => _isPlaying;

  @visibleForTesting
  int get timeLeft => _timeLeft;

  @visibleForTesting
  set timeLeft(int value) => _timeLeft = value;

  @visibleForTesting
  int get score => _score;

  @visibleForTesting
  List<String> get foundWords => _foundWords;

  @visibleForTesting
  bool get isGameOver => _isGameOver;

  @visibleForTesting
  void enterBubble(int index) => _enterBubble(index);

  @visibleForTesting
  void releaseSelection() => _releaseSelection();

  @visibleForTesting
  void refreshWheel() => _refreshWheel();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final double wheelSize = isLandscape
        ? min(220.0, mq.size.height * 0.42)
        : min(290.0, mq.size.width * 0.72);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScenicBackground(showPlayArea: true, theme: widget.theme),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: GameConfig.maxContentWidth,
                ),
                child: Column(
                  children: [
                    // Üst Bar
                    _buildHeader(context),
                    const SizedBox(height: 8),

                    // Skor Tablosu
                    _buildScoreBar(),
                    const Spacer(),

                    // Süre Göstergesi
                    _buildTimerCircle(),
                    const Spacer(),

                    // Bildirim (Feedback) Alanı
                    _buildFeedbackArea(),
                    const SizedBox(height: 10),

                    // Bulunan Kelimeler Listesi
                    _buildFoundWordsList(),
                    const Spacer(),

                    // Çark ve Yan Butonlar
                    _buildWheelSection(wheelSize),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Başlangıç Geri Sayımı Maskesi
          if (_isCountdownActive) _buildCountdownOverlay(),

          // Oyun Bitti Maskesi
          if (_isGameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            label: 'Geri',
            button: true,
            child: InkWell(
              onTap: widget.onBack,
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
          Text(
            Strings.t('time_attack_title'),
            style: const TextStyle(
              fontFamily: AppText.displayFamily,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          // Cüzdan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xDDFBF6EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xAAFFFFFF), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🪙 ',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '${widget.store.coins}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Strings.t('time_attack_score').replaceAll('%d', '$_score'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${Strings.t('time_attack_high_score_label')}: $_highScore',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle() {
    final progress = _timeLeft / 60.0;
    final isLowTime = _timeLeft < 15;

    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: const Color(0x22122C3D),
              valueColor: AlwaysStoppedAnimation<Color>(
                isLowTime
                    ? Colors.redAccent
                    : (_timeLeft < 30 ? AppColors.gold : Colors.greenAccent),
              ),
            ),
            Text(
              '$_timeLeft',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isLowTime ? Colors.redAccent : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackArea() {
    return Container(
      height: 40,
      alignment: Alignment.center,
      child: _feedbackText == null
          ? const SizedBox.shrink()
          : KeyedSubtree(
              key: ValueKey('feedback_$_feedbackTick'),
              child: AnimatedOpacity(
                opacity: _feedbackText != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _feedbackColor!.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.chip,
                  ),
                  child: Text(
                    _feedbackText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFoundWordsList() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _foundWords.isEmpty
          ? Center(
              child: Text(
                'Çarkı sürükleyerek Çeçence kelimeleri bul!',
                style: TextStyle(
                  color: AppColors.ink.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _foundWords.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final word = _foundWords[i];
                final meaning = Strings.tOrNull('info_$word');
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.goldBorder, width: 1.2),
                    boxShadow: AppShadows.chip,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        word.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (meaning != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          meaning,
                          style: TextStyle(
                            color: AppColors.ink.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildWheelSection(double wheelSize) {
    return Row(
      children: [
        // Sol panel: Karıştır
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: RoundIconButton(
              icon: Icons.shuffle_rounded,
              size: 54,
              enabled: _isPlaying,
              onTap: _shuffle,
            ),
          ),
        ),

        // Çark
        LetterWheel(
          key: const ValueKey('time_attack_wheel'),
          letters: _currentLetters,
          order: _wheelOrder,
          selection: _selection,
          size: wheelSize,
          enabled: _isPlaying,
          onEnterBubble: _enterBubble,
          onRelease: _releaseSelection,
        ),

        // Sağ panel: Çarkı Yenile (15 Coin)
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: RoundIconButton(
              icon: Icons.refresh_rounded,
              size: 54,
              badge: '15',
              enabled: _isPlaying,
              onTap: _refreshWheel,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Strings.t('time_attack_ready'),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedScale(
              scale: 1.2,
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 84,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF6EB),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_off_rounded,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Strings.t('time_attack_game_over'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isNewRecord) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x22F5B62B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Strings.t('time_attack_new_record'),
                            style: const TextStyle(
                              color: AppColors.goldDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGameOverStat(
                          'SKOR', '$_score', Icons.emoji_events_rounded),
                      _buildGameOverStat('COİN', '+$_coinsGained',
                          Icons.monetization_on_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _startNewSession,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppGradients.gold,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppShadows.chip,
                            ),
                            child: Text(
                              Strings.t('time_attack_restart'),
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: widget.onBack,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.ink.withOpacity(0.3),
                                  width: 1.5),
                            ),
                            child: Text(
                              Strings.t('time_attack_home'),
                              style: TextStyle(
                                color: AppColors.ink.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.inkSoft, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.inkSoft,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
