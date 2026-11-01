import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// Decorative schematic. No motor identities, inferred geometry or spinning props.
class DroneStage extends StatefulWidget {
  const DroneStage({super.key, this.processing = false});
  final bool processing;
  @override
  State<DroneStage> createState() => _DroneStageState();
}

class _DroneStageState extends State<DroneStage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _mist =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));
  ScrollPosition? _scroll;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scroll?.removeListener(_sync);
    _scroll = Scrollable.maybeOf(context)?.position;
    _scroll?.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final box = context.findRenderObject();
    final visible = box is RenderBox &&
        box.hasSize &&
        (box.localToGlobal(Offset.zero) & box.size)
            .overlaps(Offset.zero & MediaQuery.sizeOf(context));
    final animate = visible &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate && !_mist.isAnimating) _mist.repeat();
    if (!animate && _mist.isAnimating) _mist.stop();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    _mist.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: RepaintBoundary(
              child: AnimatedBuilder(
            animation: _mist,
            builder: (context, _) => CustomPaint(
              key: const ValueKey('illustrative-drone-stage'),
              painter: DroneStagePainter(
                phase:
                    MediaQuery.disableAnimationsOf(context) ? 0 : _mist.value,
                processing: widget.processing,
              ),
            ),
          )),
        ),
        const Text("Illustration only · not a reference model",
            textAlign: TextAlign.center,
            style:
                TextStyle(color: inspectionMuted, fontSize: 14, height: 1.4)),
      ]);
}

class DroneStagePainter extends CustomPainter {
  const DroneStagePainter({required this.phase, required this.processing});
  final double phase;
  final bool processing;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final center = Offset(size.width / 2, size.height * .48);
    // Three broad, cheap radial fields: no blur over photographs or full-page wash.
    for (var i = 0; i < 3; i++) {
      final drift = math.sin(phase * math.pi * 2 + i * 2) * 14;
      final rect = Rect.fromCenter(
          center:
              Offset(size.width * (.25 + .25 * i) + drift, size.height * .8),
          width: size.width * .85,
          height: 100);
      canvas.drawOval(
          rect,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xff2b0b55).withValues(alpha: .8),
              inspectionGround.withValues(alpha: 0),
            ]).createShader(rect));
    }
    final scale = math.min(size.width / 320, .95);
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    final arm = Paint()
      ..color = const Color(0xff131019)
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final rim = Paint()
      ..color = inspectionAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final edge = Paint()
      ..color = inspectionInk.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final p in [
      const Offset(-104, -40),
      const Offset(104, -40),
      const Offset(-104, 48),
      const Offset(104, 48)
    ]) {
      canvas.drawLine(Offset.zero, p, rim..strokeWidth = 18);
      canvas.drawLine(Offset.zero, p, arm);
      canvas.drawOval(Rect.fromCenter(center: p, width: 27, height: 22),
          Paint()..color = const Color(0xff16131b));
      final prop = RRect.fromRectAndRadius(
          Rect.fromCenter(center: p.translate(0, -7), width: 96, height: 13),
          const Radius.circular(7));
      canvas.drawRRect(prop, Paint()..color = const Color(0xff0b0b0d));
      canvas.drawRRect(prop, edge);
      canvas.drawCircle(
          p.translate(0, -7), 5, Paint()..color = inspectionAccent);
    }
    final body = Path()
      ..moveTo(0, -48)
      ..quadraticBezierTo(33, -42, 35, -15)
      ..lineTo(28, 38)
      ..quadraticBezierTo(0, 55, -28, 38)
      ..lineTo(-35, -15)
      ..quadraticBezierTo(-33, -42, 0, -48)
      ..close();
    canvas.drawPath(
        body,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff49434f),
                Color(0xff0a090c),
                Color(0xff191020)
              ]).createShader(const Rect.fromLTWH(-35, -48, 70, 100)));
    canvas.drawPath(body, edge);
    canvas.drawLine(
        const Offset(-15, -30),
        const Offset(-20, 10),
        Paint()
          ..color = inspectionInk.withValues(alpha: .65)
          ..strokeWidth = 2);
    if (processing) {
      final y = -65 + phase * 130;
      canvas.drawLine(
          Offset(-148, y),
          Offset(148, y),
          Paint()
            ..color = inspectionLightPurple
            ..strokeWidth = 2);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DroneStagePainter old) =>
      phase != old.phase || processing != old.processing;
}
