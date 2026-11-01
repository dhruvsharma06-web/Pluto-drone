import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class AcquisitionFailure implements Exception {
  const AcquisitionFailure(this.code);
  final String code;
}

/// Encoded stills only. No YUV/BGRA buffers enter the v1 engine boundary.
abstract interface class ImageAcquisition {
  Future<Uint8List?> pickImage();
  Future<Uint8List?> recoverImage();
  Future<void> openCamera();
  Future<Uint8List> capture();
  Future<void> closeCamera();
  Future<void> dispose();
}

class AndroidImageAcquisition implements ImageAcquisition {
  AndroidImageAcquisition({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  final camera = ValueNotifier<CameraController?>(null);
  int _generation = 0;
  bool _disposed = false;

  Future<Uint8List> _read(XFile file) async {
    if (await file.length() > 20 * 1024 * 1024) {
      throw const AcquisitionFailure('INVALID_INPUT');
    }
    return file.readAsBytes();
  }

  @override
  Future<Uint8List?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<Uint8List?> recoverImage() async {
    if (!Platform.isAndroid) return null;
    final lost = await _picker.retrieveLostData();
    if (lost.exception != null) throw const AcquisitionFailure('PICKER_FAILED');
    final files = lost.files;
    return files == null || files.isEmpty ? null : _read(files.first);
  }

  @override
  Future<void> openCamera() async {
    await closeCamera();
    final generation = _generation;
    final cameras = await availableCameras();
    if (_disposed || generation != _generation) return;
    final rear =
        cameras.where((c) => c.lensDirection == CameraLensDirection.back);
    if (rear.isEmpty) throw const AcquisitionFailure('CAMERA_UNAVAILABLE');
    // Rear camera only: no selfie mirroring or guessed front-camera transforms.
    final controller =
        CameraController(rear.first, ResolutionPreset.high, enableAudio: false);
    try {
      await controller.initialize();
      if (_disposed || generation != _generation) {
        await controller.dispose();
        return;
      }
      camera.value = controller;
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
  }

  @override
  Future<Uint8List> capture() async {
    final controller = camera.value;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.hasError) {
      throw const AcquisitionFailure('CAMERA_UNAVAILABLE');
    }
    final file = await controller.takePicture();
    try {
      return await _read(file);
    } finally {
      // Only delete the camera plugin's temporary still, never a gallery input.
      try {
        await File(file.path).delete();
      } on FileSystemException {/* Cache cleanup only. */}
    }
  }

  @override
  Future<void> closeCamera() async {
    _generation++;
    final controller = camera.value;
    camera.value = null;
    await controller?.dispose();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await closeCamera();
    camera.dispose();
  }
}
