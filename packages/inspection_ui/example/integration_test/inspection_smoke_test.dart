import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inspection_ui/inspection_ui.dart';
import 'package:inspection_ui_preview/fixture_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native phone presentation states', (tester) async {
    final data = await rootBundle.load('assets/illustrative-drone.png');
    final controller = FixtureController(data.buffer.asUint8List());
    for (final (name, scenario, dark) in [
      ('android-prepare', 'prepare', false),
      ('android-reference', 'reference', false),
      ('android-mismatch', 'incorrect', false),
      ('android-pass-dark', 'pass', true)
    ]) {
      controller.show(scenario);
      await tester.pumpWidget(InspectionApp(
          controller: controller,
          demoMode: true,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light));
      await tester.pumpAndSettle();
      expect(find.text('Demo · Simulated results'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (scenario == 'prepare') await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }
    await tester.pumpWidget(const SizedBox());
    await controller.dispose();
  });
}
