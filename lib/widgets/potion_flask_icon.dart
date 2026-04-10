import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Интерактивная колба: серый → зелёное «зелье» → красное → снова серый.
/// Анимация заливки и пузырьков запускается только при нажатии (не крутится в фоне).
class PotionFlaskIcon extends StatefulWidget {
  const PotionFlaskIcon({super.key, this.size = 22});

  final double size;

  @override
  State<PotionFlaskIcon> createState() => _PotionFlaskIconState();
}

class _PotionFlaskIconState extends State<PotionFlaskIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _step = 0;
  int _fromStep = 0;
  int _toStep = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_ctrl.isAnimating) return;
    _fromStep = _step;
    _toStep = (_step + 1) % 3;
    _ctrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _step = _toStep;
        _ctrl.reset();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: widget.size + 8,
          height: widget.size + 8,
          child: Center(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _FlaskPainter(
                  animating: _ctrl.isAnimating,
                  animValue: _ctrl.value,
                  fromStep: _fromStep,
                  toStep: _toStep,
                  idleStep: _step,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlaskPainter extends CustomPainter {
  static const Color _outline = Color(0xFFB0BEC5);

  _FlaskPainter({
    required this.animating,
    required this.animValue,
    required this.fromStep,
    required this.toStep,
    required this.idleStep,
  });

  final bool animating;
  final double animValue;
  final int fromStep;
  final int toStep;
  final int idleStep;

  double get _t => Curves.easeInOut.transform(animValue.clamp(0.0, 1.0));

  double _fillLevel() {
    if (!animating) {
      return idleStep == 0 ? 0.0 : 1.0;
    }
    if (fromStep == 0 && toStep == 1) return _t;
    if (fromStep == 1 && toStep == 2) return 1.0;
    if (fromStep == 2 && toStep == 0) return 1.0 - _t;
    return 0;
  }

  Color? _liquidColor() {
    if (!animating) {
      if (idleStep == 0) return null;
      if (idleStep == 1) {
        return const Color(0xFF00E676);
      }
      return const Color(0xFFFF5252);
    }
    if (fromStep == 0 && toStep == 1) {
      return Color.lerp(
        const Color(0xFF004D40).withValues(alpha: 0.35),
        const Color(0xFF00E676),
        _t,
      );
    }
    if (fromStep == 1 && toStep == 2) {
      return Color.lerp(
        const Color(0xFF00E676),
        const Color(0xFFFF5252),
        _t,
      );
    }
    if (fromStep == 2 && toStep == 0) {
      return const Color(0xFFFF5252);
    }
    return null;
  }

  bool _showBubbles() => animating && animValue < 1.0;

  Path _flaskPath(Size s) {
    final w = s.width;
    final h = s.height;
    final p = Path();
    p.moveTo(0.38 * w, 0.06 * h);
    p.lineTo(0.62 * w, 0.06 * h);
    p.lineTo(0.58 * w, 0.22 * h);
    p.lineTo(0.78 * w, 0.94 * h);
    p.lineTo(0.22 * w, 0.94 * h);
    p.lineTo(0.42 * w, 0.22 * h);
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _flaskPath(size);
    final fill = _fillLevel();
    final liquid = _liquidColor();

    final outlinePaint = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width * 0.065)
      ..strokeJoin = StrokeJoin.round;

    if (fill > 0.02 && liquid != null) {
      canvas.save();
      canvas.clipPath(path);

      final bounds = path.getBounds();
      final bottom = bounds.bottom;
      final topFill = bottom - fill * bounds.height * 0.92;

      final base = liquid;
      final deep = base.r >= base.g ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20);
      final grad = ui.Gradient.linear(
        Offset(bounds.center.dx, topFill),
        Offset(bounds.center.dx, bottom),
        [
          Color.lerp(Colors.white, base, 0.35)!,
          Color.lerp(deep, base, 0.5)!,
          base,
        ],
        const [0.0, 0.45, 1.0],
      );

      final fillPaint = Paint()..shader = grad;
      final liquidRect = Rect.fromLTRB(bounds.left - 2, topFill, bounds.right + 2, bottom + 1);
      canvas.drawRect(liquidRect, fillPaint);

      final hi = Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * fill)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      final hiMid = (topFill + bottom) / 2;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bounds.center.dx - size.width * 0.08, hiMid - size.height * 0.04),
          width: size.width * 0.2,
          height: size.height * 0.12,
        ),
        hi,
      );

      if (_showBubbles()) {
        _drawBubbles(canvas, bounds, topFill, bottom);
      }

      canvas.restore();
    }

    canvas.drawPath(path, outlinePaint);
  }

  void _drawBubbles(Canvas canvas, Rect bounds, double liquidTop, double bottom) {
    final seed = (fromStep * 7 + toStep * 13) & 0x7fffffff;
    final rnd = math.Random(seed);
    final n = 5;
    final phase = _t * 2 * math.pi;
    for (var i = 0; i < n; i++) {
      final bx = rnd.nextDouble();
      final r = (0.04 + rnd.nextDouble() * 0.035) * bounds.width;
      final rise = _t * (0.55 + rnd.nextDouble() * 0.35);
      final y0 = bottom - rise * bounds.height * 0.85;
      final sway = math.sin(phase * 1.4 + i * 1.1) * bounds.width * 0.04;
      final cx = bounds.left + bounds.width * (0.28 + bx * 0.44) + sway;
      final cy = math.max(liquidTop + r, math.min(bottom - r, y0));
      final a = (0.35 + 0.45 * math.sin(phase + i)) * (1 - _t * 0.3);
      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: a.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r, bubblePaint);
      canvas.drawCircle(
        Offset(cx - r * 0.25, cy - r * 0.25),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: a * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlaskPainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.animating != animating ||
        oldDelegate.fromStep != fromStep ||
        oldDelegate.toStep != toStep ||
        oldDelegate.idleStep != idleStep;
  }
}
