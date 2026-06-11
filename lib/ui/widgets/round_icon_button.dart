import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Yuvarlak, yarı şeffaf oyun butonu. Dokunmatik + mouse (hover/tıklama)
/// destekler; isteğe bağlı altın rozet (ör. ipucu maliyeti) gösterir.
/// [pulse] açıkken (ve buton etkinken) yumuşak nefes alma animasyonu oynar.
class RoundIconButton extends StatefulWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.badge,
    this.enabled = true,
    this.pulse = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String? badge;
  final bool enabled;
  final bool pulse;

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  AnimationController? _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant RoundIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final wantPulse = widget.pulse && widget.enabled;
    if (wantPulse && _pulseCtrl == null) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1700),
      )..repeat();
    } else if (!wantPulse && _pulseCtrl != null) {
      _pulseCtrl!.dispose();
      _pulseCtrl = null;
    }
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `enabled` görünümü belirler (ipucu kalmadığında sönük); aksiyonsuz
    // (onTap == null) butonlar normal görünür ama tepki vermez.
    final active = widget.enabled && widget.onTap != null;

    final button = AnimatedScale(
      scale: _pressed ? 0.92 : (_hovered && active ? 1.06 : 1.0),
      duration: const Duration(milliseconds: 110),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _hovered && active
                ? const [Color(0xCCFFFFFF), Color(0x8CFFFFFF)]
                : const [Color(0x8CFFFFFF), Color(0x42FFFFFF)],
          ),
          border: Border.all(color: const Color(0x80FFFFFF), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child:
            Icon(widget.icon, size: widget.size * 0.52, color: AppColors.ink),
      ),
    );

    final core = MouseRegion(
      cursor: active ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onTap : null,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: widget.badge == null
              ? button
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    button,
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          widget.badge!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    final pulseCtrl = _pulseCtrl;
    if (pulseCtrl == null) return core;
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.05 * sin(2 * pi * pulseCtrl.value),
        child: child,
      ),
      child: core,
    );
  }
}
