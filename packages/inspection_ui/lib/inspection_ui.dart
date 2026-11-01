import 'package:flutter/material.dart';
import 'package:inspection_contract/inspection_contract.dart';

/// Bootstrap screen only; the frontend owner replaces presentation here.
class InspectionApp extends StatelessWidget {
  const InspectionApp({super.key, required this.controller, this.cameraPreview});
  final InspectionController controller;
  final Widget? cameraPreview;
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Pluto Inspection',
    home: Scaffold(appBar: AppBar(title: const Text('Pluto Inspection')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(24),
        child: StreamBuilder<InspectionState>(stream: controller.states,
          initialData: controller.current, builder: (context, snapshot) {
            final state = snapshot.data!;
            return ListView(children: [
              const Text('Scaffold only - not a working detector.'),
              const SizedBox(height: 16),
              const Text('Keep the drone disarmed and motors stopped.'),
              Text(state.message),
              if (cameraPreview != null) cameraPreview!,
              CheckboxListTile(value: state.safetyConfirmed,
                title: const Text('I have followed the disarmed / motors-stopped procedure'),
                onChanged: (value) => controller.setSafetyConfirmed(value ?? false)),
              FilledButton(onPressed: state.safetyConfirmed ? controller.selectImage : null,
                child: const Text('Upload service (pending)')),
              OutlinedButton(onPressed: state.safetyConfirmed ? controller.startLive : null,
                child: const Text('Live service (pending)')),
              if (state.result != null) Text(switch(state.result!.status) {
                VerificationStatus.pass => 'Pass',
                VerificationStatus.incorrectInstallation => 'Incorrect Installation',
                VerificationStatus.unableToVerify => 'Unable to Verify',
              }),
            ]);
          }))),
    ));
}
