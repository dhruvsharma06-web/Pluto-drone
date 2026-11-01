import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspection_runtime/inspection_runtime.dart';
import 'package:inspection_ui/inspection_ui.dart';

void main() {
  testWidgets('pending services never approve an image', (tester) async {
    final controller = PendingInspectionController();
    await tester.pumpWidget(InspectionApp(controller: controller));
    expect(find.text('Pass'), findsNothing);
    await controller.setSafetyConfirmed(true);
    await tester.pump();
    await controller.selectImage();
    await tester.pump();
    expect(find.text('Unable to Verify'), findsOneWidget);
    expect(find.text('Pass'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await controller.dispose();
  });
}
