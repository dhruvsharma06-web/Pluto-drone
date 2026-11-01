import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:inspection_contract/inspection_contract.dart';

typedef ImageNormalizer = Future<InspectionImage> Function(
    Uint8List bytes, String id, String source);

/// Decoding/EXIF transform/re-encoding runs off the rendering isolate.
Future<InspectionImage> normalizeImage(
        Uint8List bytes, String id, String source) =>
    Isolate.run(() => normalizeImageSync(bytes, id, source));

InspectionImage normalizeImageSync(Uint8List bytes, String id, String source) {
  if (bytes.isEmpty ||
      bytes.length > 20 * 1024 * 1024 ||
      !const ['upload', 'live'].contains(source)) {
    throw const FormatException('INVALID_INPUT');
  }
  // Reject unsupported formats, animated images and oversized headers before
  // allocating a decoded bitmap. No undocumented resizing before inference.
  final img.Decoder decoder;
  if (img.JpegDecoder().isValidFile(bytes)) {
    decoder = img.JpegDecoder();
  } else if (img.PngDecoder().isValidFile(bytes)) {
    decoder = img.PngDecoder();
  } else {
    throw const FormatException('INVALID_INPUT');
  }
  final info = decoder.startDecode(bytes);
  if (info == null ||
      info.width <= 0 ||
      info.height <= 0 ||
      info.width * info.height > 16000000 ||
      info.numFrames != 1) {
    throw const FormatException('INVALID_INPUT');
  }
  final decoded = decoder.decodeFrame(0);
  if (decoded == null) throw const FormatException('INVALID_INPUT');
  // Includes EXIF reflection (2,4,5,7), not just 90-degree rotation.
  final upright = img.bakeOrientation(decoded);
  upright.exif = img.ExifData();
  return InspectionImage(
      id: id,
      bytes: img.encodePng(upright),
      width: upright.width,
      height: upright.height,
      source: source);
}
