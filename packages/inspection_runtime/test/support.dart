// All images, references and engine responses in these tests are synthetic
// fixtures. They are not supplied-drone evidence or detector predictions.
import 'dart:typed_data';
import 'package:inspection_contract/inspection_contract.dart';
import 'package:inspection_runtime/inspection_runtime.dart';

InspectionReference fixtureReference() => InspectionReference.fromJson({
      'schema_version': '1.0.0',
      'reference_version': 'fixture-reference-only',
      'status': 'verified',
      'drone_variant': 'SYNTHETIC TEST FIXTURE',
      'front_convention': 'fixture',
      'source_evidence': ['synthetic test only'],
      'supported_views': ['fixture'],
      'motors': [
        {
          'motor_id': 'fixture-A',
          'expected_type': 'fixture-type',
          'expected_orientation': 'fixture-up'
        },
        {
          'motor_id': 'fixture-B',
          'expected_type': 'fixture-type',
          'expected_orientation': 'fixture-up'
        },
      ],
    });

Map<String, Object?> fixtureOutput(String id) => {
      'schema_version': '1.0.0', 'input_id': id, 'status': 'pass',
      // Deliberately exercises the production guard with a synthetic test double.
      // This marker must never be used to present a demo as real inference.
      'evidence_source': 'real', 'reference_version': 'fixture-reference-only',
      'engine_version': 'synthetic-test-double',
      'all_required_checks_observable': true,
      'reasons': <String>[], 'elapsed_ms': 1,
      'motors': [
        for (final id in ['fixture-A', 'fixture-B'])
          {
            'motor_id': id,
            'bbox': [0.1, 0.1, 0.2, 0.2],
            'observed_type': 'fixture-type',
            'expected_type': 'fixture-type',
            'observed_orientation': 'fixture-up',
            'expected_orientation': 'fixture-up',
            'finding': 'match',
            'correction_code': null,
          }
      ],
    };

InspectionImage fixtureImage([String id = 'fixture-input']) => InspectionImage(
    id: id,
    bytes: Uint8List.fromList([1]),
    width: 2,
    height: 1,
    source: 'upload');

class FakeAcquisition implements ImageAcquisition {
  Future<Uint8List?> Function()? picker;
  Future<Uint8List> Function()? capturer;
  Uint8List? recovered;
  Object? cameraError;
  int captures = 0, opens = 0, closes = 0;
  bool disposed = false;
  @override
  Future<Uint8List?> pickImage() async =>
      picker == null ? Uint8List(1) : picker!();
  @override
  Future<Uint8List?> recoverImage() async => recovered;
  @override
  Future<void> openCamera() async {
    opens++;
    if (cameraError != null) throw cameraError!;
  }

  @override
  Future<Uint8List> capture() async {
    captures++;
    return capturer == null ? Uint8List(1) : capturer!();
  }

  @override
  Future<void> closeCamera() async {
    closes++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeEngine implements VerificationEngine {
  FakeEngine(this.callback);
  final Future<VerificationResult> Function(InspectionImage) callback;
  @override
  Future<VerificationResult> verify(InspectionImage image) => callback(image);
}

Future<InspectionImage> fakeNormalizer(
        Uint8List bytes, String id, String source) async =>
    InspectionImage(id: id, bytes: bytes, width: 2, height: 1, source: source);

VerificationResult syntheticPass(InspectionImage image) => VerificationResult(
    inputId: image.id,
    status: VerificationStatus.pass,
    evidenceSource: 'real',
    allRequiredChecksObservable: true,
    referenceVersion: 'synthetic-test-double');
