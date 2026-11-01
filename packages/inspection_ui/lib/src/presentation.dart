import 'package:inspection_contract/inspection_contract.dart';

String resultLabel(VerificationStatus status) => switch (status) {
      VerificationStatus.pass => 'Pass',
      VerificationStatus.incorrectInstallation => 'Incorrect Installation',
      VerificationStatus.unableToVerify => 'Unable to Verify',
    };

/// Presentation guard only. Complete motor coverage is validated by the core.
VerificationResult? displayedResult(InspectionState state) {
  final r = state.result;
  if (state.phase != InspectionPhase.result || r == null) return null;
  if (state.image != null && state.image!.id != r.inputId) return null;
  String? invalid;
  if (!state.safetyConfirmed) invalid = 'SAFETY_NOT_CONFIRMED';
  if (r.status != VerificationStatus.unableToVerify) {
    if (r.referenceVersion == null ||
        r.referenceVersion!.isEmpty ||
        r.referenceVersion == 'pending') invalid ??= 'REFERENCE_NOT_CONFIGURED';
    if (r.engineVersion == null || r.engineVersion!.isEmpty)
      invalid ??= 'ENGINE_UNAVAILABLE';
    if (!r.allRequiredChecksObservable ||
        r.reasons.isNotEmpty ||
        r.motors.isEmpty) invalid ??= 'INCOMPLETE_EVIDENCE';
    final ids = r.motors.map((m) => m['motor_id']).toList();
    if (ids.any((id) => id is! String || id.isEmpty) ||
        ids.toSet().length != ids.length) invalid ??= 'INVALID_RESULT';
    for (final m in r.motors) {
      if ([
            'observed_type',
            'expected_type',
            'observed_orientation',
            'expected_orientation',
          ].any((k) => m[k] is! String || (m[k] as String).trim().isEmpty) ||
          !['match', 'mismatch'].contains(m['finding']))
        invalid ??= 'INCOMPLETE_EVIDENCE';
      if (r.status == VerificationStatus.pass &&
          (m['finding'] != 'match' ||
              m['observed_type'] != m['expected_type'] ||
              m['observed_orientation'] != m['expected_orientation']))
        invalid ??= 'INVALID_RESULT';
    }
    if (r.status == VerificationStatus.incorrectInstallation &&
        !r.motors.any((m) => m['finding'] == 'mismatch'))
      invalid ??= 'INVALID_RESULT';
  }
  if (invalid == null) return r;
  return VerificationResult(
    inputId: r.inputId,
    status: VerificationStatus.unableToVerify,
    evidenceSource: r.evidenceSource,
    allRequiredChecksObservable: false,
    referenceVersion: r.referenceVersion,
    engineVersion: r.engineVersion,
    reasons: [invalid],
    motors: r.motors,
    elapsedMs: r.elapsedMs,
  );
}

String reasonGuidance(String reason) => switch (reason) {
      'REFERENCE_NOT_CONFIGURED' =>
        'The supplied drone reference is needed before installation can be verified.',
      'ENGINE_UNAVAILABLE' =>
        'The inspection service is not available. Try again when it is connected.',
      'SAFETY_NOT_CONFIRMED' =>
        'Confirm the drone is disarmed and all motors have stopped before inspecting.',
      'BLUR' => 'Hold the camera steady or choose a sharper photo.',
      'LOW_LIGHT' =>
        'Move to even, brighter light. Avoid strong shadows on the propellers.',
      'INCOMPLETE_DRONE' =>
        'Include the whole drone and every propeller in the image.',
      'NO_DRONE' => 'Place the drone fully in view, then try again.',
      'UNKNOWN_ORIENTATION' =>
        'Use the view required by the reference so the installation orientation is visible.',
      'AMBIGUOUS_CLASS' =>
        'Move closer while keeping every propeller visible. The propeller types are unclear.',
      'UNSUPPORTED_VIEW' =>
        'Use the viewing angle specified by the drone reference.',
      'PERMISSION_DENIED' ||
      'CAMERA_PERMISSION_DENIED' =>
        'Camera permission is needed. Allow it in Android settings, or use a photo.',
      'CANCELLED' =>
        'Inspection was cancelled. Choose an image or start the camera again.',
      'INVALID_INPUT' =>
        'Choose a readable JPEG or PNG image of the complete drone.',
      'INCOMPLETE_EVIDENCE' =>
        'There is not enough evidence for a complete installation check. Retake the image.',
      'INVALID_RESULT' =>
        'The inspection returned an incomplete result. Try again; this image has not been verified.',
      _ =>
        'This image could not be verified. Retake it with every propeller clearly visible.',
    };

String? motorText(Map<String, Object?> motor, String field) {
  final v = motor[field];
  return v is String && v.trim().isNotEmpty ? v : null;
}

String correctionGuidance(Map<String, Object?> motor) {
  final type = motorText(motor, 'expected_type'),
      orientation = motorText(motor, 'expected_orientation');
  if (motor['finding'] == 'unknown')
    return 'Make this propeller clearly visible and inspect again.';
  if (motor['finding'] == 'match')
    return 'Matches the supplied installation reference.';
  if (type == null)
    return 'Check this motor against the supplied installation reference.';
  return 'Use $type at this motor.${orientation == null ? '' : ' Required orientation: $orientation.'} Keep the drone disarmed while correcting it.';
}
