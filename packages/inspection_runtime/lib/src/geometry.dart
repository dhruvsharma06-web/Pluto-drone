import 'package:flutter/painting.dart';

/// Coordinates for normalized analysis boxes over the SAME upright still.
/// Never use this to overlay a later live frame: preview/capture crops differ.
class UprightImageGeometry {
  const UprightImageGeometry(this.width, this.height);
  final int width, height;

  Rect mapBox(List<num> box, Size viewport, {BoxFit fit = BoxFit.contain}) {
    if (width <= 0 || height <= 0 || viewport.isEmpty || box.length != 4) {
      throw const FormatException('Invalid image geometry');
    }
    final sourceSize = Size(width.toDouble(), height.toDouble());
    final fitted = applyBoxFit(fit, sourceSize, viewport);
    final source =
        Alignment.center.inscribe(fitted.source, Offset.zero & sourceSize);
    final target =
        Alignment.center.inscribe(fitted.destination, Offset.zero & viewport);
    return Rect.fromLTWH(
      target.left +
          (box[0] * width - source.left) * target.width / source.width,
      target.top +
          (box[1] * height - source.top) * target.height / source.height,
      box[2] * width * target.width / source.width,
      box[3] * height * target.height / source.height,
    );
  }
}
