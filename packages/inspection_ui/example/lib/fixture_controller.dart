import 'dart:async';
import 'dart:typed_data';

import 'package:inspection_contract/inspection_contract.dart';

/// Explicitly simulated UI states. No detection, labels, camera or model here.
class FixtureController implements InspectionController {
  FixtureController(this.photo);
  final Uint8List photo;
  final _events = StreamController<InspectionState>.broadcast();
  InspectionState _state = const InspectionState();
  String scenario = 'prepare';
  int _sequence = 0;
  @override
  InspectionState get current => _state;
  @override
  Stream<InspectionState> get states => _events.stream;
  void emit(InspectionState value) {
    _state = value;
    _events.add(value);
  }

  void show(String value) {
    scenario = value;
    final id = 'demo-${++_sequence}';
    final image = InspectionImage(
      id: id,
      bytes: photo,
      width: 960,
      height: 1280,
      source: 'upload',
    );
    final motors = <Map<String, Object?>>[
      for (var i = 0; i < 4; i++)
        {
          'motor_id': 'Sample ${String.fromCharCode(65 + i)}',
          'bbox': [
            [.12, .15, .20, .30],
            [.68, .18, .23, .28],
            [.03, .65, .26, .23],
            [.64, .66, .28, .22],
          ][i],
          'finding': value == 'blur'
              ? 'unknown'
              : value == 'incorrect' && i == 1
                  ? 'mismatch'
                  : 'match',
          'observed_type': value == 'incorrect' && i == 1
              ? 'Example type B'
              : value == 'blur'
                  ? null
                  : 'Example type A',
          'expected_type': 'Example type A',
          'observed_orientation':
              value == 'blur' ? null : 'Example orientation',
          'expected_orientation': 'Example orientation',
          'correction_code': value == 'incorrect' && i == 1
              ? 'REPLACE_WITH_REFERENCE_TYPE'
              : null,
        },
    ];
    if (value == 'prepare') {
      emit(const InspectionState());
      return;
    }
    if (value == 'processing') {
      emit(
        InspectionState(
          phase: InspectionPhase.processing,
          safetyConfirmed: true,
          image: image,
        ),
      );
      return;
    }
    if (value == 'permission') {
      emit(
        const InspectionState(
          phase: InspectionPhase.error,
          safetyConfirmed: true,
          message: 'CAMERA_PERMISSION_DENIED',
        ),
      );
      return;
    }
    final status = switch (value) {
      'pass' => VerificationStatus.pass,
      'incorrect' => VerificationStatus.incorrectInstallation,
      _ => VerificationStatus.unableToVerify,
    };
    emit(
      InspectionState(
        phase: InspectionPhase.result,
        safetyConfirmed: true,
        image: image,
        result: VerificationResult(
          inputId: id,
          status: status,
          evidenceSource: 'fixture',
          referenceVersion:
              value == 'reference' ? null : 'fixture-reference-v1',
          engineVersion: 'fixture-only',
          allRequiredChecksObservable: value == 'pass' || value == 'incorrect',
          reasons: value == 'reference'
              ? ['REFERENCE_NOT_CONFIGURED']
              : value == 'blur'
                  ? ['BLUR']
                  : [],
          motors: value == 'reference' ? [] : motors,
        ),
      ),
    );
  }

  @override
  Future<void> setSafetyConfirmed(bool confirmed) async =>
      emit(InspectionState(safetyConfirmed: confirmed, image: current.image));
  @override
  Future<void> selectImage() async {
    show('processing');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    show('reference');
  }

  @override
  Future<void> startLive() async {
    emit(
      const InspectionState(
        phase: InspectionPhase.result,
        safetyConfirmed: true,
        result: VerificationResult(
          inputId: 'demo-live-unavailable',
          status: VerificationStatus.unableToVerify,
          evidenceSource: 'fixture',
          allRequiredChecksObservable: false,
          reasons: ['ENGINE_UNAVAILABLE'],
        ),
      ),
    );
  }

  @override
  Future<void> stopLive() async =>
      emit(InspectionState(safetyConfirmed: current.safetyConfirmed));
  @override
  Future<void> dispose() async => _events.close();
}
