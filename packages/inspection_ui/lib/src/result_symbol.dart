import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:inspection_contract/inspection_contract.dart';
import 'theme.dart';

/// Shape and glyph are redundant with the adjacent exact result label.
class ResultSymbol extends StatelessWidget {
  const ResultSymbol({super.key, required this.status, this.size = 32});
  final VerificationStatus status;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              key: ValueKey('result-symbol-${status.name}'),
              painter: _ResultPainter(status),
              child: Icon(
                  switch (status) {
                    VerificationStatus.pass => Icons.check,
                    VerificationStatus.incorrectInstallation => Icons.close,
                    VerificationStatus.unableToVerify => Icons.question_mark,
                  },
                  size: size * .64,
                  color: status == VerificationStatus.unableToVerify
                      ? inspectionMuted
                      : inspectionGround),
            )),
      );
}

class _ResultPainter extends CustomPainter {
  const _ResultPainter(this.status);
  final VerificationStatus status;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    switch (status) {
      case VerificationStatus.pass:
        canvas.drawOval(rect, Paint()..color = inspectionInk);
      case VerificationStatus.incorrectInstallation:
        canvas.drawRect(rect, Paint()..color = inspectionAccent);
      case VerificationStatus.unableToVerify:
        final paint = Paint()
          ..color = inspectionMuted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (var i = 0; i < 12; i++) {
          canvas.drawArc(rect, i * math.pi / 6, math.pi / 9, false, paint);
        }
    }
  }

  @override
  bool shouldRepaint(_ResultPainter old) => old.status != status;
}
