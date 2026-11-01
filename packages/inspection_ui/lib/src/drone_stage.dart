import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Original illustrative geometry, not the supplied drone configuration.
/// Movement is the viewpoint, never powered propeller motion.
class DroneStage extends StatefulWidget {
  const DroneStage({super.key, this.processing = false});
  final bool processing;
  @override
  State<DroneStage> createState() => _DroneStageState();
}

class _DroneStageState extends State<DroneStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController scan = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200));
  Offset tilt = Offset.zero;
  bool dragging = false;
  bool get reduced => MediaQuery.disableAnimationsOf(context);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant DroneStage old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.processing && !reduced) {
      if (!scan.isAnimating) scan.repeat();
    } else {
      scan.stop();
      scan.value = 0;
    }
  }

  @override
  void dispose() {
    scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final compact = c.maxHeight < 245;
        return Semantics(
            label:
                'Illustrative drone framing guide. Drag to change the viewing angle. Motors are shown stopped.',
            child: GestureDetector(
                onPanStart:
                    reduced ? null : (_) => setState(() => dragging = true),
                onPanUpdate: reduced
                    ? null
                    : (d) => setState(() => tilt = Offset(
                        (tilt.dx + d.delta.dx / 180).clamp(-.3, .3),
                        (tilt.dy + d.delta.dy / 180).clamp(-.25, .25))),
                onPanEnd: (_) => setState(() {
                      dragging = false;
                      tilt = Offset.zero;
                    }),
                onPanCancel: () => setState(() {
                      dragging = false;
                      tilt = Offset.zero;
                    }),
                child: ColoredBox(
                    color: const Color(0xff10161b),
                    child: Stack(fit: StackFit.expand, children: [
                      RepaintBoundary(
                          child: CustomPaint(painter: _StageGround())),
                      Positioned.fill(
                          bottom: compact ? 66 : 88,
                          top: compact ? 8 : 12,
                          child: TweenAnimationBuilder<Offset>(
                              tween: Tween(begin: Offset.zero, end: tilt),
                              duration: Duration(
                                  milliseconds: reduced || dragging ? 0 : 180),
                              curve: const Cubic(.23, 1, .32, 1),
                              builder: (context, value, child) => Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, .001)
                                    ..rotateX(-.18 + value.dy)
                                    ..rotateY(value.dx),
                                  child: child),
                              child:
                                  const CustomPaint(painter: _DronePainter()))),
                      if (widget.processing)
                        IgnorePointer(
                            child: AnimatedBuilder(
                                animation: scan,
                                builder: (context, child) => CustomPaint(
                                    painter: _ScanPainter(
                                        reduced ? .5 : scan.value)))),
                      Positioned(
                          left: 22,
                          right: 22,
                          bottom: compact ? 22 : 29,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                                widget.processing
                                    ? 'Reading the installation'
                                    : 'Bring your drone into view',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xffedf5fa),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(
                                widget.processing
                                    ? 'Checking visible evidence'
                                    : 'Illustrative guide · drag to explore',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xff9eafbc), fontSize: 12)),
                          ])),
                    ]))));
      });
}

class _StageGround extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final area = Offset.zero & s;
    canvas.drawRect(
        area,
        Paint()
          ..shader = RadialGradient(
                  center: const Alignment(0, -.35),
                  radius: .95,
                  colors: const [Color(0xff243640), Color(0xff10161b)])
              .createShader(area));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xff344651);
    final r = Rect.fromLTWH(
        s.width * .12, s.height * .10, s.width * .76, s.height * .58);
    for (final (at, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0)
    ]) {
      canvas.drawPath(
          Path()
            ..moveTo(at.dx, at.dy + dy * 15)
            ..lineTo(at.dx, at.dy)
            ..lineTo(at.dx + dx * 15, at.dy),
          p);
    }
  }

  @override
  bool shouldRepaint(_StageGround old) => false;
}

class _DronePainter extends CustomPainter {
  const _DronePainter();
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, s.height / 2);
    final scale = math.min(s.width / 310, s.height / 210);
    c.scale(scale);
    final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-27, -58, 54, 116), const Radius.circular(22));
    final arms = Paint()
      ..color = const Color(0xff6e8594)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (final point in [
      const Offset(-92, -65),
      const Offset(92, -65),
      const Offset(-92, 65),
      const Offset(92, 65)
    ]) {
      c.drawLine(Offset.zero, point, arms);
      c.drawCircle(point, 12, Paint()..color = const Color(0xff1b272f));
      c.save();
      c.translate(point.dx, point.dy);
      c.rotate(point.dx * point.dy > 0 ? .4 : -.4);
      final blade = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-42, -7, 84, 14), const Radius.circular(7));
      c.drawRRect(
          blade,
          Paint()
            ..shader = const LinearGradient(colors: [
              Color(0xff536671),
              Color(0xffc4d4dc),
              Color(0xff4d626e)
            ]).createShader(const Rect.fromLTWH(-42, -7, 84, 14)));
      c.drawCircle(Offset.zero, 5, Paint()..color = const Color(0xff93b1c3));
      c.restore();
    }
    c.drawRRect(
        body,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xffb7cad5),
                Color(0xff5e788a),
                Color(0xff243d4e)
              ]).createShader(body.outerRect));
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-20, -51, 40, 102), const Radius.circular(16)),
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xff263b49), Color(0xff142530)])
              .createShader(body.outerRect));
    c.drawLine(
        const Offset(-11, -29),
        const Offset(11, -29),
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xff70b8ff));
    c.drawCircle(
        const Offset(0, 29), 3, Paint()..color = const Color(0xff70b8ff));
    c.restore();
  }

  @override
  bool shouldRepaint(_DronePainter old) => false;
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas c, Size s) {
    final y = s.height * .12 + progress * s.height * .55;
    final r = Rect.fromLTWH(s.width * .13, y - 22, s.width * .74, 24);
    c.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x001f91ff), Color(0x282f9fff)]).createShader(r));
    c.drawLine(
        Offset(s.width * .13, y),
        Offset(s.width * .87, y),
        Paint()
          ..color = const Color(0xff79bfff)
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.progress != progress;
}

/// Processing indication over real image evidence; never a detection result.
class ProcessingSweep extends StatefulWidget {
  const ProcessingSweep({super.key});
  @override
  State<ProcessingSweep> createState() => _ProcessingSweepState();
}

class _ProcessingSweepState extends State<ProcessingSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context)) {
      if (!motion.isAnimating) motion.repeat();
    } else {
      motion.stop();
      motion.value = .5;
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: AnimatedBuilder(
          animation: motion,
          builder: (context, child) =>
              CustomPaint(painter: _ScanPainter(motion.value))));
}
