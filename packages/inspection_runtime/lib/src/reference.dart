import 'dart:convert';

/// Structure validation cannot certify physical ground truth. Only the supplied,
/// reviewed reference may be packaged as verified by the integration owner.
class InspectionReference {
  InspectionReference._(this.version, this.verified, this.json, this.motors);
  final String version;
  final bool verified;
  final Map<String, Object?> json;
  final Map<String, Map<String, Object?>> motors;

  factory InspectionReference.parse(String source) =>
      InspectionReference.fromJson(jsonDecode(source));

  factory InspectionReference.fromJson(Object? value) {
    final ref = objectMap(value);
    requireKeys(ref, const [
      'schema_version',
      'reference_version',
      'status',
      'drone_variant',
      'front_convention',
      'source_evidence',
      'supported_views',
      'motors'
    ]);
    final version = nonemptyString(ref['reference_version']);
    if (ref['schema_version'] != '1.0.0' ||
        !const ['pending', 'verified'].contains(ref['status'])) invalid();
    nullableString(ref['drone_variant']);
    nullableString(ref['front_convention']);
    final sources = stringList(ref['source_evidence'], nonempty: true);
    final views = stringList(ref['supported_views'], nonempty: true);
    final motors = <String, Map<String, Object?>>{};
    if (ref['motors'] is! List) invalid();
    for (final value in ref['motors'] as List) {
      final motor = objectMap(value);
      requireKeys(
          motor, const ['motor_id', 'expected_type', 'expected_orientation']);
      final id = nonemptyString(motor['motor_id']);
      nonemptyString(motor['expected_type']);
      nonemptyString(motor['expected_orientation']);
      if (motors.containsKey(id)) invalid();
      motors[id] = Map.unmodifiable(motor);
    }
    final verified = ref['status'] == 'verified';
    if (!verified && motors.isNotEmpty) invalid();
    if (verified &&
        (version == 'pending' ||
            motors.isEmpty ||
            sources.isEmpty ||
            views.isEmpty ||
            ref['drone_variant'] == null ||
            ref['front_convention'] == null ||
            ref['drone_variant'] == '' ||
            ref['front_convention'] == '')) invalid();
    // Deep-copy before freezing: callers cannot mutate the active mapping.
    final frozen = <String, Object?>{
      ...ref,
      'source_evidence': List<String>.unmodifiable(sources),
      'supported_views': List<String>.unmodifiable(views),
      'motors': List<Map<String, Object?>>.unmodifiable(motors.values)
    };
    return InspectionReference._(
        version, verified, Map.unmodifiable(frozen), Map.unmodifiable(motors));
  }
}

Never invalid() => throw const FormatException('Invalid v1 resource');

Map<String, Object?> objectMap(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) invalid();
  return Map<String, Object?>.from(value);
}

void requireKeys(Map<String, Object?> value, List<String> keys) {
  if (value.length != keys.length || !keys.every(value.containsKey)) invalid();
}

String nonemptyString(Object? value) {
  if (value is! String || value.trim().isEmpty) invalid();
  return value;
}

String? nullableString(Object? value) {
  if (value != null && value is! String) invalid();
  return value as String?;
}

List<String> stringList(Object? value, {bool nonempty = false}) {
  if (value is! List ||
      value.any((v) => v is! String || (nonempty && v.trim().isEmpty)))
    invalid();
  return List<String>.from(value);
}
