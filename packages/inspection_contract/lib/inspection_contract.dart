import 'dart:typed_data';

enum VerificationStatus { pass, incorrectInstallation, unableToVerify }
enum InspectionPhase { idle, processing, result, error }

class InspectionImage {
  const InspectionImage({required this.id, required this.bytes, required this.width,
    required this.height, required this.source});
  final String id;
  final Uint8List bytes; // Encoded upright unmirrored JPEG/PNG.
  final int width, height;
  final String source; // live or upload
}

class VerificationResult {
  const VerificationResult({required this.inputId, required this.status,
    required this.evidenceSource, required this.allRequiredChecksObservable,
    this.referenceVersion, this.engineVersion, this.reasons = const [],
    this.motors = const [], this.elapsedMs});
  final String inputId, evidenceSource;
  final VerificationStatus status;
  final bool allRequiredChecksObservable;
  final String? referenceVersion, engineVersion;
  final List<String> reasons;
  final List<Map<String, Object?>> motors; // Exact v1 fields in JSON schema.
  final double? elapsedMs;

  Map<String, Object?> toJson() => {
    'schema_version': '1.0.0', 'input_id': inputId,
    'status': switch (status) {
      VerificationStatus.pass => 'pass',
      VerificationStatus.incorrectInstallation => 'incorrect_installation',
      VerificationStatus.unableToVerify => 'unable_to_verify',
    },
    'evidence_source': evidenceSource, 'reference_version': referenceVersion,
    'engine_version': engineVersion,
    'all_required_checks_observable': allRequiredChecksObservable,
    'reasons': reasons, 'motors': motors, 'elapsed_ms': elapsedMs,
  };
}

class InspectionState {
  const InspectionState({this.phase = InspectionPhase.idle,
    this.safetyConfirmed = false, this.message = '', this.image, this.result});
  final InspectionPhase phase;
  final bool safetyConfirmed;
  final String message;
  final InspectionImage? image;
  final VerificationResult? result;
}

abstract interface class VerificationEngine {
  Future<VerificationResult> verify(InspectionImage image);
}

abstract interface class InspectionController {
  InspectionState get current;
  Stream<InspectionState> get states;
  Future<void> setSafetyConfirmed(bool confirmed);
  Future<void> selectImage();
  Future<void> startLive();
  Future<void> stopLive();
  Future<void> dispose();
}
