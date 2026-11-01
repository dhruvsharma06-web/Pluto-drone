import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspection_runtime/inspection_runtime.dart';
import 'package:inspection_ui/inspection_ui.dart';
import 'dart:typed_data';

class CancelledPicker implements ImageAcquisition {
  @override
  Future<Uint8List?> pickImage() async => null;
  @override
  Future<Uint8List?> recoverImage() async => null;
  @override
  Future<void> openCamera() async =>
      throw const AcquisitionFailure('CAMERA_UNAVAILABLE');
  @override
  Future<Uint8List> capture() async => Uint8List(0);
  @override
  Future<void> closeCamera() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('pending services never approve an image', (tester) async {
    final controller = RuntimeInspectionController(
        acquisition: CancelledPicker(), engine: GuardedVerificationEngine());
    await tester.pumpWidget(InspectionApp(controller: controller));
    expect(find.text('Pass'), findsNothing);
    await controller.selectImage();
    await tester.pump();
    expect(find.text('Unable to Verify'), findsOneWidget);
    expect(find.text('Pass'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await controller.dispose();
  });
}
