import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Rotor aperture: four swept blades around a small verification check.
/// The same paths generate the source SVG and Android launcher assets.
class InspectionMark extends StatelessWidget {
  const InspectionMark({super.key, this.size = 28, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Pluto Inspector logo',
      image: true,
      child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
              painter: _MarkPainter(
                  color ?? Theme.of(context).colorScheme.primary))));
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.shortestSide / 100);
    final blade = Path()
      ..moveTo(1, -14)
      ..cubicTo(4, -28, 19, -37, 29, -34)
      ..cubicTo(37, -31, 36, -20, 28, -14)
      ..lineTo(12, -5)
      ..close();
    for (var i = 0; i < 4; i++) {
      canvas.drawPath(blade, Paint()..color = color);
      canvas.rotate(math.pi / 2);
    }
    canvas.drawPath(
        Path()
          ..moveTo(-8, 0)
          ..lineTo(-2, 6)
          ..lineTo(9, -7),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}
