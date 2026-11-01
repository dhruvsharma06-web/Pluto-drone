import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspection_contract/inspection_contract.dart';
import 'package:inspection_runtime/inspection_runtime.dart';
import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('missing or pending reference never invokes an engine', () async {
    var called = false;
    final engine = GuardedVerificationEngine(transport: (_) async {
      called = true;
      return null;
    });
    final result = await engine.verify(fixtureImage());
    expect(result.status, VerificationStatus.unableToVerify);
    expect(result.reasons, ['REFERENCE_NOT_CONFIGURED']);
    expect(called, false);
    final pending = InspectionReference.fromJson({
      ...fixtureReference().json,
      'status': 'pending',
      'reference_version': 'pending',
      'motors': []
    });
    final pendingEngine = GuardedVerificationEngine(
        reference: pending,
        transport: (_) async {
          called = true;
          return null;
        });
    expect((await pendingEngine.verify(fixtureImage())).reasons,
        ['REFERENCE_NOT_CONFIGURED']);
    expect(called, false);
  });
  test('unavailable native adapter is explicit', () async {
    final engine = GuardedVerificationEngine(
        reference: fixtureReference(),
        transport: (_) async =>
            throw PlatformException(code: 'ENGINE_UNAVAILABLE'));
    expect(
        (await engine.verify(fixtureImage())).reasons, ['ENGINE_UNAVAILABLE']);
  });
  test('absent channel reports unavailable', () async {
    final engine = GuardedVerificationEngine(reference: fixtureReference());
    expect(
        (await engine.verify(fixtureImage())).reasons, ['ENGINE_UNAVAILABLE']);
  });
  test('timeout latches closed rather than growing native work queue',
      () async {
    var calls = 0;
    final pending = Completer<Object?>();
    final engine = GuardedVerificationEngine(
        reference: fixtureReference(),
        timeout: const Duration(milliseconds: 5),
        transport: (_) {
          calls++;
          return pending.future;
        });
    expect((await engine.verify(fixtureImage())).status,
        VerificationStatus.unableToVerify);
    expect(
        (await engine.verify(fixtureImage())).reasons, ['ENGINE_UNAVAILABLE']);
    expect(calls, 1);
    pending.complete(null);
  });
  test('valid synthetic response exercises the pass gate', () {
    final result = validateEngineResult(
        fixtureOutput('fixture-input'), 'fixture-input', fixtureReference());
    expect(result.status, VerificationStatus.pass);
  });
  test('confirmed synthetic mismatch exercises incorrect gate', () {
    final raw = fixtureOutput('fixture-input');
    raw['status'] = 'incorrect_installation';
    final motor = (raw['motors'] as List).first as Map;
    motor['finding'] = 'mismatch';
    motor['observed_type'] = 'fixture-wrong-type';
    expect(
        validateEngineResult(raw, 'fixture-input', fixtureReference()).status,
        VerificationStatus.incorrectInstallation);
  });
  final mutations = <String, void Function(Map<String, Object?>)>{
    'wrong input': (r) => r['input_id'] = 'old',
    'wrong reference': (r) => r['reference_version'] = 'old',
    'fixture in production': (r) => r['evidence_source'] = 'fixture',
    'missing engine version': (r) => r['engine_version'] = null,
    'unobservable': (r) => r['all_required_checks_observable'] = false,
    'blur rejection': (r) => r['reasons'] = ['BLUR'],
    'incomplete motor set': (r) => (r['motors'] as List).removeLast(),
    'duplicate motor': (r) =>
        (r['motors'] as List).add((r['motors'] as List).first),
    'contradictory class': (r) =>
        ((r['motors'] as List).first as Map)['observed_type'] = 'wrong',
    'bad bbox': (r) =>
        ((r['motors'] as List).first as Map)['bbox'] = [0.9, 0, 0.3, 0.1],
    'unknown finding': (r) =>
        ((r['motors'] as List).first as Map)['finding'] = 'unknown',
    'unconfigured motor': (r) =>
        ((r['motors'] as List).first as Map)['motor_id'] = 'invented',
    'NaN time': (r) => r['elapsed_ms'] = double.nan,
    'extra key': (r) => r['confidence'] = 0.99,
    'incorrect without mismatch': (r) => r['status'] = 'incorrect_installation',
  };
  for (final mutation in mutations.entries) {
    test('reject ${mutation.key}', () async {
      final raw = fixtureOutput('fixture-input');
      mutation.value(raw);
      final engine = GuardedVerificationEngine(
          reference: fixtureReference(), transport: (_) async => raw);
      final result = await engine.verify(fixtureImage());
      expect(result.status, VerificationStatus.unableToVerify);
      expect(result.reasons, ['ENGINE_ERROR']);
    });
  }
  test('reference rejects pending mapping and duplicate identities', () {
    final pending = {...fixtureReference().json, 'status': 'pending'};
    expect(() => InspectionReference.fromJson(pending), throwsFormatException);
    final duplicate = {...fixtureReference().json};
    duplicate['motors'] = [
      fixtureReference().motors.values.first,
      fixtureReference().motors.values.first
    ];
    expect(
        () => InspectionReference.fromJson(duplicate), throwsFormatException);
  });
}
