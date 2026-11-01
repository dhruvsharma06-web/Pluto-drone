import 'dart:async';
import 'package:inspection_contract/inspection_contract.dart';

/// Safe bootstrap only. No camera, image selection or inference is implemented.
class PendingInspectionController implements InspectionController {
  final _events = StreamController<InspectionState>.broadcast();
  InspectionState _current = const InspectionState(
    message: 'Scaffold only. Drone reference and verification engine pending.');
  @override InspectionState get current => _current;
  @override Stream<InspectionState> get states => _events.stream;
  void _emit(InspectionState value) { _current = value; _events.add(value); }
  @override Future<void> setSafetyConfirmed(bool confirmed) async {
    _emit(InspectionState(safetyConfirmed: confirmed,
      message: 'Confirmation does not prove hardware disarm. Reference still pending.'));
  }
  Future<void> _unavailable() async => _emit(InspectionState(
    phase: InspectionPhase.result, safetyConfirmed: current.safetyConfirmed,
    message: 'Camera/upload and real verification are not implemented in this scaffold.',
    result: VerificationResult(inputId: 'pending',
      status: VerificationStatus.unableToVerify, evidenceSource: 'real',
      allRequiredChecksObservable: false,
      reasons: current.safetyConfirmed
        ? const ['REFERENCE_NOT_CONFIGURED', 'ENGINE_UNAVAILABLE']
        : const ['SAFETY_NOT_CONFIRMED'])));
  @override Future<void> selectImage() => _unavailable();
  @override Future<void> startLive() => _unavailable();
  @override Future<void> stopLive() async {
    _emit(InspectionState(safetyConfirmed: current.safetyConfirmed, message: 'Stopped.'));
  }
  @override Future<void> dispose() async => _events.close();
}
