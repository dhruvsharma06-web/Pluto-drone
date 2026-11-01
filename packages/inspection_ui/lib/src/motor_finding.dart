import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspection_contract/inspection_contract.dart';
import 'evidence_view.dart';
import 'presentation.dart';

/// Image-relative position only. It is not a physical drone motor mapping.
String motorWhere(Map<String, Object?> motor) {
  final id = motorText(motor, 'motor_id') ?? 'Unidentified motor';
  final box = motorBoxRect(motor['bbox'], const Rect.fromLTWH(0, 0, 1, 1));
  if (box == null) return '$id · Image location not supplied.';
  final x = box.center.dx, y = box.center.dy;
  final horizontal = x < 1 / 3
      ? 'left'
      : x > 2 / 3
          ? 'right'
          : 'centre';
  final vertical = y < 1 / 3
      ? 'Upper'
      : y > 2 / 3
          ? 'Lower'
          : 'Middle';
  return '$id · $vertical $horizontal of image.';
}

class MotorFindingDetails extends StatelessWidget {
  const MotorFindingDetails({super.key, required this.motor});
  final Map<String, Object?> motor;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in [
            ('Where', motorWhere(motor)),
            ('Why', motorWhy(motor)),
            ('Correction', correctionGuidance(motor)),
          ]) ...[
            Text(item.$1, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(item.$2, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
          ],
        ],
      );
}

/// Details stay attached to this exact inspection, including during live input.
class MotorFindingSheet extends StatefulWidget {
  const MotorFindingSheet(
      {super.key,
      required this.motor,
      required this.result,
      required this.controller});
  final Map<String, Object?> motor;
  final VerificationResult result;
  final InspectionController controller;
  @override
  State<MotorFindingSheet> createState() => _MotorFindingSheetState();
}

class _MotorFindingSheetState extends State<MotorFindingSheet>
    with WidgetsBindingObserver {
  StreamSubscription<InspectionState>? _subscription;
  bool _closing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = widget.controller.states.listen((state) {
      if (!identical(state.result, widget.result) ||
          state.phase != InspectionPhase.result ||
          !state.safetyConfirmed ||
          (state.image != null && state.image!.id != widget.result.inputId)) {
        _close();
      }
    }, onError: (Object _) => _close());
  }

  void _close() {
    if (!mounted || _closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) _close();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                  child: Text(
                      motorText(widget.motor, 'motor_id') ?? 'Motor finding',
                      style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(
                  onPressed: _close,
                  tooltip: 'Close motor finding',
                  icon: const Icon(Icons.close)),
            ]),
            if (widget.result.evidenceSource == 'fixture')
              const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Demo · Simulated results')),
            const SizedBox(height: 24),
            MotorFindingDetails(motor: widget.motor),
          ]),
        ),
      );
}
