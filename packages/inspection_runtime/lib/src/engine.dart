import 'dart:async';

import 'package:flutter/services.dart';
import 'package:inspection_contract/inspection_contract.dart';

import 'reference.dart';

typedef EngineTransport = Future<Object?> Function(
    Map<String, Object?> request);

VerificationResult unable(String id, List<String> reasons,
        {String? referenceVersion, double? elapsedMs}) =>
    VerificationResult(
        inputId: id,
        status: VerificationStatus.unableToVerify,
        evidenceSource: 'real',
        allRequiredChecksObservable: false,
        reasons: reasons,
        referenceVersion: referenceVersion,
        elapsedMs: elapsedMs);

/// App-local proposed platform transport; the shared v1 contract is unchanged.
/// No detector is bundled. Android currently explicitly reports unavailable.
class GuardedVerificationEngine implements VerificationEngine {
  GuardedVerificationEngine(
      {this.reference,
      EngineTransport? transport,
      this.timeout = const Duration(seconds: 15)})
      : _transport = transport ?? _nativeVerify;
  static const channel = MethodChannel('org.plutoinspection/verification_v1');
  static Future<Object?> _nativeVerify(Map<String, Object?> request) =>
      channel.invokeMethod<Object?>('verify', request);

  final InspectionReference? reference;
  final EngineTransport _transport;
  final Duration timeout;
  bool _timedOut = false;

  @override
  Future<VerificationResult> verify(InspectionImage image) async {
    final ref = reference;
    if (ref == null || !ref.verified) {
      return unable(image.id, const ['REFERENCE_NOT_CONFIGURED'],
          referenceVersion: ref?.version);
    }
    if (_timedOut)
      return unable(image.id, const ['ENGINE_UNAVAILABLE'],
          referenceVersion: ref.version);
    try {
      final raw = await _transport({
        'schema_version': '1.0.0',
        'input_id': image.id,
        'bytes': image.bytes,
        'width': image.width,
        'height': image.height,
        'source': image.source,
        'reference': ref.json,
      }).timeout(timeout);
      return validateEngineResult(raw, image.id, ref);
    } on MissingPluginException {
      return unable(image.id, const ['ENGINE_UNAVAILABLE'],
          referenceVersion: ref.version);
    } on PlatformException catch (error) {
      return unable(
          image.id,
          [
            error.code == 'ENGINE_UNAVAILABLE'
                ? 'ENGINE_UNAVAILABLE'
                : 'ENGINE_ERROR'
          ],
          referenceVersion: ref.version);
    } on TimeoutException {
      // Timeout does not cancel native execution. Latch closed to prevent an
      // unbounded native queue; replace/dispose the adapter before retrying.
      _timedOut = true;
      return unable(image.id, const ['ENGINE_UNAVAILABLE'],
          referenceVersion: ref.version);
    } catch (_) {
      return unable(image.id, const ['ENGINE_ERROR'],
          referenceVersion: ref.version);
    }
  }
}

/// Strict structural + semantic validation before a production result reaches UI.
VerificationResult validateEngineResult(
    Object? raw, String inputId, InspectionReference reference) {
  final result = objectMap(raw);
  requireKeys(result, const [
    'schema_version',
    'input_id',
    'status',
    'evidence_source',
    'reference_version',
    'engine_version',
    'all_required_checks_observable',
    'reasons',
    'motors',
    'elapsed_ms'
  ]);
  if (result['schema_version'] != '1.0.0' ||
      result['input_id'] != inputId ||
      result['evidence_source'] != 'real' ||
      result['reference_version'] != reference.version ||
      result['all_required_checks_observable'] is! bool) invalid();
  final engineVersion = nullableString(result['engine_version']);
  final status = switch (result['status']) {
    'pass' => VerificationStatus.pass,
    'incorrect_installation' => VerificationStatus.incorrectInstallation,
    'unable_to_verify' => VerificationStatus.unableToVerify,
    _ => invalid(),
  };
  final reasons = stringList(result['reasons']);
  if (reasons.toSet().length != reasons.length) invalid();
  final elapsed = result['elapsed_ms'];
  if (elapsed != null && (elapsed is! num || !elapsed.isFinite || elapsed < 0))
    invalid();
  if (result['motors'] is! List) invalid();
  final motors = <Map<String, Object?>>[];
  final ids = <String>{};
  for (final value in result['motors'] as List) {
    final motor = objectMap(value);
    requireKeys(motor, const [
      'motor_id',
      'bbox',
      'observed_type',
      'expected_type',
      'observed_orientation',
      'expected_orientation',
      'finding',
      'correction_code'
    ]);
    final id = nonemptyString(motor['motor_id']);
    final expected = reference.motors[id];
    if (!ids.add(id) || expected == null) invalid();
    for (final key in const [
      'observed_type',
      'expected_type',
      'observed_orientation',
      'expected_orientation',
      'correction_code'
    ]) {
      nullableString(motor[key]);
    }
    if (motor['expected_type'] != expected['expected_type'] ||
        motor['expected_orientation'] != expected['expected_orientation'] ||
        !const ['match', 'mismatch', 'unknown'].contains(motor['finding']))
      invalid();
    final box = motor['bbox'];
    if (box != null) {
      if (box is! List ||
          box.length != 4 ||
          box.any((v) => v is! num || !v.isFinite || v < 0 || v > 1)) invalid();
      final b = box.cast<num>();
      if (b[2] <= 0 ||
          b[3] <= 0 ||
          b[0] + b[2] > 1.000001 ||
          b[1] + b[3] > 1.000001) invalid();
      motor['bbox'] = List<num>.unmodifiable(b);
    }
    if (motor['finding'] != 'unknown') {
      final observedType = nonemptyString(motor['observed_type']);
      final observedOrientation = nonemptyString(motor['observed_orientation']);
      final matches = observedType == motor['expected_type'] &&
          observedOrientation == motor['expected_orientation'];
      if ((motor['finding'] == 'match') != matches) invalid();
    }
    motors.add(Map.unmodifiable(motor));
  }
  if (status != VerificationStatus.unableToVerify) {
    if (!reference.verified ||
        engineVersion == null ||
        engineVersion.trim().isEmpty ||
        result['all_required_checks_observable'] != true ||
        reasons.isNotEmpty ||
        motors.isEmpty ||
        ids.length != reference.motors.length ||
        motors.any((m) => m['finding'] == 'unknown')) invalid();
    if (status == VerificationStatus.pass &&
        motors.any((m) => m['finding'] != 'match')) invalid();
    if (status == VerificationStatus.incorrectInstallation &&
        !motors.any((m) => m['finding'] == 'mismatch')) invalid();
  }
  return VerificationResult(
      inputId: inputId,
      status: status,
      evidenceSource: 'real',
      allRequiredChecksObservable:
          result['all_required_checks_observable'] as bool,
      referenceVersion: reference.version,
      engineVersion: engineVersion,
      reasons: List.unmodifiable(reasons),
      motors: List.unmodifiable(motors),
      elapsedMs: (elapsed as num?)?.toDouble());
}
