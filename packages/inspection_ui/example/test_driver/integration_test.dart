import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final out = Directory(
      Platform.environment['PLUTO_SCREENSHOTS'] ?? 'build/ui-screenshots');
  await out.create(recursive: true);
  await integrationDriver(onScreenshot: (name, bytes, [args]) async {
    await File('${out.path}/$name.png').writeAsBytes(bytes);
    return true;
  });
}
