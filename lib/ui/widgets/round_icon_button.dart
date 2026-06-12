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
  }) : assert(size >= 44, 'Touch target en az 44dp olmalı (Apple HIG)');

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
    with TickerProviderStateMixin {
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

    // Ana ekrandaki krem buton diliyle aynı; hover'da hafif "kalkma"
    // (gölge büyür), basınca küçülüp gölge daralır — dokunsal his.
    final lifted = _hovered && active && !_pressed;
    final button = AnimatedScale(
      scale: _pressed ? 0.94 : (lifted ? 1.05 : 1.0),
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.enter,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lifted ? AppColors.barButtonHover : AppColors.barButton,
          border: Border.all(color: AppColors.barButtonBorder, width: 1.5),
          boxShadow: [
            if (_pressed)
              const BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              )
            else if (lifted)
              const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              )
            else
              const BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 6,
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
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.goldLight, AppColors.goldDark],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFFF6D8),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          widget.badge!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
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
