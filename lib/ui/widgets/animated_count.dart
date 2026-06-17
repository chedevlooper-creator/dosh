import 'package:flutter/material.dart';

/// Verilen [target] değerine 0'dan başlayarak animasyonlu şekilde sayan
/// metin widget'ı. [duration] süresince [curve] ile sayar.
///
/// Kullanım: `AnimatedCount(target: 42, style: TextStyle(...))`
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.textAlign,
  });

  final int target;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _ctrl.addListener(() => setState(() {}));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCount old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = (widget.target * _anim.value).round();
    return Text(
      '$value',
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}

/// Liste elemanlarının sırayla görünmesini sağlayan animasyon sarmalayıcı.
///
/// Kullanım: `StaggerItem(index: i, child: MyTile())`
/// İlk eleman [delayOffset] ms gecikmeyle, her sonraki eleman [staggerMs] ms
/// arayla görünür.
class StaggerItem extends StatefulWidget {
  const StaggerItem({
    super.key,
    required this.index,
    required this.child,
    this.delayOffset = 50,
    this.staggerMs = 40,
    this.duration = const Duration(milliseconds: 350),
  });

  final int index;
  final Widget child;
  final int delayOffset;
  final int staggerMs;
  final Duration duration;

  @override
  State<StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<StaggerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final delay = widget.delayOffset + (widget.index * widget.staggerMs);
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuad);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}
