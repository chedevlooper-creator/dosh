import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/graphemes.dart';
import '../../data/models.dart';
import '../../game/game_controller.dart';
import '../theme.dart';

/// Seviye verisinden çalışma anında üretilen crossword alanı.
/// Hücre boyutu mevcut alana göre hesaplanır; küçük ekranlarda otomatik
/// küçülür. Harfler açıldıkça kademeli pop-in animasyonuyla yerleşir.
class CrosswordGrid extends StatelessWidget {
  const CrosswordGrid({
    super.key,
    required this.controller,
    this.onCellTap,
  });

  final GameController controller;
  final ValueChanged<Cell>? onCellTap;

  @override
  Widget build(BuildContext context) {
    final level = controller.level;
    const gapRatio = 0.12;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = level.colCount;
        final rows = level.rowCount;
        final cellFromW =
            constraints.maxWidth / (cols + (cols - 1) * gapRatio);
        final cellFromH =
            constraints.maxHeight / (rows + (rows - 1) * gapRatio);
        final cell =
            cellFromW.clamp(0.0, cellFromH).clamp(0.0, 56.0).toDouble();
        final gap = cell * gapRatio;
        final totalW = cols * cell + (cols - 1) * gap;
        final totalH = rows * cell + (rows - 1) * gap;

        // Çözülen son kelimenin hücreleri kademeli gecikmeyle açılır.
        final delays = <Cell, int>{};
        final lastSolved = controller.lastSolved;
        if (lastSolved != null) {
          final cells = lastSolved.cells;
          for (var i = 0; i < cells.length; i++) {
            delays[cells[i]] = i * 70;
          }
        }

        return Center(
          child: SizedBox(
            width: totalW,
            height: totalH,
            child: Stack(
              children: [
                for (final entry in level.targetByCell.entries)
                  Positioned(
                    key: ValueKey('cell_${entry.key.row}_${entry.key.col}'),
                    left: (entry.key.col - level.minCol) * (cell + gap),
                    top: (entry.key.row - level.minRow) * (cell + gap),
                    child: GestureDetector(
                      onTap: () => onCellTap?.call(entry.key),
                      behavior: HitTestBehavior.opaque,
                      child: _LetterCell(
                        letter: displayGrapheme(entry.value),
                        size: cell,
                        show: controller.cellFilled(entry.key),
                        solved: _solvedWordCovers(entry.key),
                        delayMs: delays[entry.key] ?? 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _solvedWordCovers(Cell cell) {
    for (final word in controller.level.words) {
      if (controller.solvedWords.contains(word.word) &&
          word.cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }
}

class _LetterCell extends StatefulWidget {
  const _LetterCell({
    required this.letter,
    required this.size,
    required this.show,
    required this.solved,
    required this.delayMs,
  });

  final String letter;
  final double size;

  /// Harf görünür mü (ipucu ya da çözülmüş kelime).
  final bool show;

  /// Çözülen bir kelimenin parçası mı (altın zemin); değilse ipucu stili.
  final bool solved;

  final int delayMs;

  @override
  State<_LetterCell> createState() => _LetterCellState();
}

class _LetterCellState extends State<_LetterCell>
    with TickerProviderStateMixin {
  // Her zaman initState'te oluşturulur: gizli hücrelerde ilk erişim dispose()
  // sırasında olursa late başlatıcı deaktive ağaçta vsync araması yapar ve
  // "deactivated widget's ancestor" hatası fırlatır.
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: AppMotion.pop,
    );
    if (widget.show) _pop.value = 1; // yeniden kurulumda animasyon tekrarı yok
  }

  @override
  void didUpdateWidget(covariant _LetterCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.show && widget.show) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _pop.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.show;
    final solved = widget.solved;

    return Semantics(
      label: visible
          ? 'Harf ${widget.letter}, satır ${(widget.size * 0).toInt() + 1}, '
              '${solved ? "çözüldü" : "ipucu"}'
          : 'Boş hücre',
      container: true,
      child: ExcludeSemantics(
        child: AnimatedContainer(
        duration: AppMotion.base,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size * 0.18),
          gradient: visible && solved
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.goldLight, AppColors.gold],
                )
              : null,
          color: visible && solved ? null : AppColors.cellEmpty,
          // İnce ışık konturu veya ipucu durumunda altın kontur
          border: visible && solved
              ? null
              : Border.all(
                  color: visible ? const Color(0x80F5B62B) : const Color(0x2EFFFFFF),
                  width: visible ? 1.5 : 1.0,
                ),
          boxShadow: [
            if (visible && solved)
              const BoxShadow(
                color: Color(0x99F5B62B),
                blurRadius: 12,
                spreadRadius: 1,
                offset: Offset(0, 2),
              )
            else if (visible && !solved)
              const BoxShadow(
                color: Color(0x4DF5B62B),
                blurRadius: 8,
                offset: Offset(0, 1),
              )
            else
              const BoxShadow(
                color: Color(0x26000000),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: visible
            ? AnimatedBuilder(
                animation: _pop,
                builder: (context, _) {
                  final pop = Curves.easeOutBack.transform(_pop.value);
                  return Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      // Altın kıvılcımlar: harf yerleşirken dışa saçılır
                    if (solved && _pop.isAnimating)
                      CustomPaint(
                        painter: _SparklePainter(progress: _pop.value),
                      ),
                    Center(
                      child: Transform.scale(
                        scale: pop,
                        child: Padding(
                          padding: EdgeInsets.all(widget.size * 0.12),
                          child: FittedBox(
                            child: Text(
                              widget.letter,
                              style: TextStyle(
                                fontSize: widget.size * 0.55,
                                fontWeight: FontWeight.w900,
                                // İpucu harfi koyu hücre üzerinde parlak altın
                                color: solved
                                    ? AppColors.ink
                                    : AppColors.goldLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : null,
      ),
      ),
    );
  }
}

/// Hücre çözüldüğünde köşelerden dışa saçılan minik altın kıvılcımlar.
class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1 - progress).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    final center = size.center(Offset.zero);
    final travel = size.width * (0.42 + 0.5 * progress);
    final arm = size.width * 0.075 * (1 - progress * 0.55);
    final paint = Paint()
      ..color = AppColors.goldLight.withAlpha((235 * opacity).round())
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final angle = pi / 4 + i * pi / 2; // köşegen yönler
      final p = center + Offset(cos(angle), sin(angle)) * travel;
      canvas.drawLine(p - Offset(arm, 0), p + Offset(arm, 0), paint);
      canvas.drawLine(p - Offset(0, arm), p + Offset(0, arm), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
