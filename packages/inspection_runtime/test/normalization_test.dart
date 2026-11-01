import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:inspection_runtime/inspection_runtime.dart';

void main() {
  // Synthetic colored image fixtures only; no physical-drone evidence.
  for (var orientation = 1; orientation <= 8; orientation++) {
    test('EXIF orientation $orientation bakes upright with no metadata replay',
        () async {
      final source = img.Image(width: 40, height: 20);
      for (var y = 0; y < 20; y++) {
        for (var x = 0; x < 40; x++) {
          source.setPixelRgb(x, y, x < 20 ? 240 : 0, y < 10 ? 240 : 0, 0);
        }
      }
      source.exif.imageIfd.orientation = orientation;
      final bytes = img.encodeJpg(source, quality: 100);
      final result =
          await normalizeImage(bytes, 'fixture-$orientation', 'upload');
      final output = img.decodePng(result.bytes)!;
      expect(result.width, orientation >= 5 ? 20 : 40);
      expect(result.height, orientation >= 5 ? 40 : 20);
      expect(output.exif.imageIfd.orientation, anyOf(isNull, equals(1)));
      // Expected top-left source quadrant after each EXIF transform.
      final expected = <int, List<int>>{
        1: [240, 240],
        2: [0, 240],
        3: [0, 0],
        4: [240, 0],
        5: [240, 240],
        6: [240, 0],
        7: [0, 0],
        8: [0, 240],
      }[orientation]!;
      final pixel = output.getPixel(3, 3);
      expect(pixel.r, closeTo(expected[0], 15));
      expect(pixel.g, closeTo(expected[1], 15));
    });
  }
  test('reject empty, damaged, unsupported and oversized encoded input', () {
    for (final bytes in [
      Uint8List(0),
      Uint8List.fromList([1, 2, 3]),
      Uint8List(20 * 1024 * 1024 + 1)
    ]) {
      expect(() => normalizeImageSync(bytes, 'fixture', 'upload'),
          throwsFormatException);
    }
    final gif = img.encodeGif(img.Image(width: 1, height: 1));
    expect(() => normalizeImageSync(gif, 'fixture', 'upload'),
        throwsFormatException);
  });
  test('same-image normalized boxes account for letterboxing and crop', () {
    const geometry = UprightImageGeometry(400, 200);
    expect(geometry.mapBox([0, 0, 1, 1], const Size(200, 200)),
        const Rect.fromLTWH(0, 50, 200, 100));
    expect(
        geometry.mapBox([0, 0, 1, 1], const Size(200, 200), fit: BoxFit.cover),
        const Rect.fromLTWH(-100, 0, 400, 200));
  });
}
