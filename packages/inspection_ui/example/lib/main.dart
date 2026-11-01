import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspection_ui/inspection_ui.dart';

import 'fixture_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final photo = await rootBundle.load('assets/illustrative-drone.png');
  runApp(
    PreviewGallery(controller: FixtureController(photo.buffer.asUint8List())),
  );
}

class PreviewGallery extends StatefulWidget {
  const PreviewGallery({super.key, required this.controller});
  final FixtureController controller;
  @override
  State<PreviewGallery> createState() => _PreviewGalleryState();
}

class _PreviewGalleryState extends State<PreviewGallery> {
  String selected = 'prepare';
  bool dark = false;
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InspectionApp(
        controller: widget.controller,
        demoMode: true,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        developmentControls: Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: const {
                  'prepare': 'Preparation',
                  'reference': 'Reference pending',
                  'incorrect': 'Simulated mismatch',
                  'pass': 'Simulated Pass',
                  'blur': 'Simulated unclear image',
                  'processing': 'Processing',
                  'permission': 'Permission error',
                }
                    .entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null)
                    setState(() {
                      selected = v;
                      widget.controller.show(v);
                    });
                },
              ),
            ),
            IconButton(
              tooltip: 'Toggle preview theme',
              icon: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              onPressed: () => setState(() => dark = !dark),
            ),
          ],
        ),
      );
}
