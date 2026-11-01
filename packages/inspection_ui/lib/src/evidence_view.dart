import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inspection_contract/inspection_contract.dart';

import 'presentation.dart';
import 'theme.dart';
import 'drone_stage.dart';

Rect containedImageRect(Size viewport, Size image) {
  if (image.width <= 0 ||
      image.height <= 0 ||
      !image.width.isFinite ||
      !image.height.isFinite) return Rect.zero;
  return Alignment.center.inscribe(
    applyBoxFit(BoxFit.contain, image, viewport).destination,
    Offset.zero & viewport,
  );
}

Rect? motorBoxRect(Object? value, Rect imageRect) {
  if (value is! List ||
      value.length != 4 ||
      imageRect.isEmpty ||
      value.any((v) => v is! num || !v.isFinite)) return null;
  final v = value.cast<num>().map((v) => v.toDouble()).toList();
  if (v[0] < 0 ||
      v[1] < 0 ||
      v[2] <= 0 ||
      v[3] <= 0 ||
      v[0] + v[2] > 1.000001 ||
      v[1] + v[3] > 1.000001) return null;
  return Rect.fromLTWH(
    imageRect.left + v[0] * imageRect.width,
    imageRect.top + v[1] * imageRect.height,
    v[2] * imageRect.width,
    v[3] * imageRect.height,
  );
}

class EvidenceView extends StatelessWidget {
  const EvidenceView({
    super.key,
    required this.state,
    required this.result,
    this.cameraPreview,
    this.selectedMotor,
    required this.onMotorSelected,
  });
  final InspectionState state;
  final VerificationResult? result;
  final Widget? cameraPreview;
  final String? selectedMotor;
  final ValueChanged<String> onMotorSelected;
  @override
  Widget build(BuildContext context) {
    final image = state.image;
    final source = image == null
        ? Size.zero
        : Size(image.width.toDouble(), image.height.toDouble());
    final ratio = image == null
        ? (4 / 3) / math.max(1, MediaQuery.textScalerOf(context).scale(14) / 14)
        : (image.width / math.max(1, image.height)).clamp(1.1, 1.6);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: cameraGround,
        child: AspectRatio(
          aspectRatio: ratio,
          child: LayoutBuilder(
            builder: (context, box) {
              final rect = containedImageRect(
                Size(box.maxWidth, box.maxHeight),
                source,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    InteractiveViewer(
                        key: ValueKey(image.id),
                        minScale: 1,
                        maxScale: 3,
                        child: Image.memory(
                          image.bytes,
                          fit: BoxFit.contain,
                          gaplessPlayback: false,
                          semanticLabel: 'Current drone inspection image',
                          errorBuilder: (_, error, trace) =>
                              const _EmptyCanvas(invalidImage: true),
                          frameBuilder: (context, child, frame, loaded) =>
                              frame == null && !loaded
                                  ? const Center(
                                      child: Text(
                                        'Loading image',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  : Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        child,
                                        if (result != null &&
                                            result!.inputId == image.id)
                                          for (final motor in result!.motors)
                                            if (motor['finding'] != 'match' ||
                                                selectedMotor ==
                                                    motor['motor_id'])
                                              if (motorBoxRect(
                                                      motor['bbox'], rect)
                                                  case final Rect bounds)
                                                _MotorTarget(
                                                  bounds: bounds,
                                                  motor: motor,
                                                  selected: selectedMotor ==
                                                      motor['motor_id'],
                                                  onSelected: onMotorSelected,
                                                ),
                                      ],
                                    ),
                        ))
                  else if (cameraPreview != null)
                    cameraPreview!
                  else
                    DroneStage(
                        processing: state.phase == InspectionPhase.processing),
                  if (state.phase == InspectionPhase.processing &&
                      (image != null || cameraPreview != null))
                    const Positioned.fill(
                      child: IgnorePointer(child: ProcessingSweep()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyCanvas extends StatelessWidget {
  const _EmptyCanvas({this.invalidImage = false});
  final bool invalidImage;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!invalidImage &&
                MediaQuery.sizeOf(context).width >= 360 &&
                MediaQuery.textScalerOf(context).scale(14) <= 18)
              const SizedBox(
                width: 160,
                height: 100,
                child: CustomPaint(painter: _FramingGuide()),
              )
            else
              const Icon(
                Icons.broken_image_outlined,
                color: Color(0xffffffff),
                size: 36,
              ),
            const SizedBox(height: 16),
            Text(
              invalidImage
                  ? 'Image could not be opened'
                  : 'Keep every propeller in view',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              invalidImage
                  ? 'Choose a readable image and try again.'
                  : 'Even light. Steady camera. Motors stopped.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xffffffff),
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}

/// Geometry-only framing guide, not a model or a motor reference.
class _FramingGuide extends CustomPainter {
  const _FramingGuide();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xffffffff)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final c = Offset(size.width / 2, size.height / 2);
    for (final o in [
      const Offset(.19, .24),
      const Offset(.81, .24),
      const Offset(.19, .76),
      const Offset(.81, .76),
    ]) {
      final at = Offset(size.width * o.dx, size.height * o.dy);
      canvas.drawLine(c, at, p);
      canvas.drawOval(Rect.fromCenter(center: at, width: 44, height: 17), p);
      canvas.drawCircle(at, 3, p);
    }
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 32, height: 60),
      const Radius.circular(12),
    );
    canvas.drawRRect(body, Paint()..color = cameraGround);
    canvas.drawRRect(body, p);
  }

  @override
  bool shouldRepaint(_FramingGuide oldDelegate) => false;
}

class _MotorTarget extends StatelessWidget {
  const _MotorTarget({
    required this.bounds,
    required this.motor,
    required this.selected,
    required this.onSelected,
  });
  final Rect bounds;
  final Map<String, Object?> motor;
  final bool selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    final id = motorText(motor, 'motor_id');
    if (id == null) return const SizedBox.shrink();
    final symbol = switch (motor['finding']) {
      'match' => Icons.check,
      'mismatch' => Icons.close,
      _ => Icons.question_mark,
    };
    return Positioned.fromRect(
      rect: bounds,
      child: Semantics(
        label: '$id, ${motor['finding']}. Show motor guidance',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('motor-box-$id'),
            onTap: () => onSelected(id),
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.white, width: selected ? 4 : 3),
              ),
              // Dual contrast keeps boxes visible on dark or light evidence.
              foregroundDecoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1)),
              child: Align(
                alignment: Alignment.topLeft,
                child: ColoredBox(
                  color: Colors.black,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: bounds.width >= 90 && bounds.height >= 36
                        ? Text(id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                        : Icon(symbol, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
