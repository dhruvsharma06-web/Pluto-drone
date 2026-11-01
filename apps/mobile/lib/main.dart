import 'package:flutter/material.dart';

import 'login.dart';
import 'runtime_application.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  runApp(const LoginGate(child: RuntimeApplication()));
}
