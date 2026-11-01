import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspection_contract/inspection_contract.dart';
import 'package:inspection_runtime/inspection_runtime.dart';
import 'package:inspection_ui/inspection_ui.dart';

/// Platform composition/lifecycle only. Presentation belongs to inspection_ui.
class RuntimeApplication extends StatefulWidget {
  const RuntimeApplication({super.key});
  @override
  State<RuntimeApplication> createState() => _RuntimeApplicationState();
}

class _RuntimeApplicationState extends State<RuntimeApplication>
    with WidgetsBindingObserver {
  late final AndroidImageAcquisition acquisition;
  late final RuntimeInspectionController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    acquisition = AndroidImageAcquisition();
    controller = RuntimeInspectionController(
        acquisition: acquisition, engine: GuardedVerificationEngine());
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    // This app-owned asset is pending, without a guessed motor map. Final
    // integration explicitly replaces it with the reviewed reference resource.
    try {
      final source = await rootBundle.loadString('assets/reference.json');
      final reference = InspectionReference.parse(source);
      await controller
          .replaceEngine(GuardedVerificationEngine(reference: reference));
    } catch (_) {
      // Missing/invalid assets leave the unavailable engine in place.
    }
    await controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(controller.suspend());
    }
    // Inactive may be the camera permission prompt. Actual background states
    // above close the camera; cancelling on the prompt would break first use.
  }

  @override
  Widget build(BuildContext context) => InspectionApp(
      controller: controller,
      cameraPreview: RuntimeCameraPreview(
          acquisition: acquisition, controller: controller));

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(controller.dispose());
    super.dispose();
  }
}

/// Keep the camera surface mounted while the user frames a single photograph.
/// This platform-owned shutter needs no change to the shared controller API.
class RuntimeCameraPreview extends StatelessWidget {
  const RuntimeCameraPreview(
      {super.key, required this.acquisition, required this.controller});
  final AndroidImageAcquisition acquisition;
  final RuntimeInspectionController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<CameraController?>(
        valueListenable: acquisition.camera,
        builder: (context, camera, _) {
          if (camera == null) return const SizedBox.shrink();
          return StreamBuilder<InspectionState>(
            stream: controller.states,
            initialData: controller.current,
            builder: (context, snapshot) {
              final busy = snapshot.data!.phase == InspectionPhase.processing;
              return Stack(fit: StackFit.expand, children: [
                Center(child: CameraPreview(camera)),
                Positioned(
                    left: 16,
                    right: 16,
                    bottom: 56,
                    child: Center(
                        child: FilledButton.icon(
                      key: const ValueKey('take-photo'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(144, 48)),
                      onPressed: busy ? null : controller.captureLiveImage,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(busy ? 'Taking photo...' : 'Take photo'),
                    ))),
              ]);
            },
          );
        },
      );
}
