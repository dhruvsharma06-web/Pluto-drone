import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:inspection_contract/inspection_contract.dart';
import 'package:inspection_runtime/inspection_runtime.dart';

/// Supplied at build time: --dart-define=GEMINI_API_KEY=... (never committed).
const _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
const _geminiModel = 'gemini-2.5-flash';

/// Plain-language guidance for each engine reason code. Spoken offline.
const reasonGuidance = <String, String>{
  'IMAGE_BLURRY': 'The photo is blurry. Hold the phone steady and retake it.',
  'IMAGE_TOO_DARK': 'The photo is too dark. Move to better light and retake it.',
  'IMAGE_OVEREXPOSED': 'The photo is too bright. Avoid direct glare and retake it.',
  'IMAGE_UNREADABLE': 'This image could not be read. Choose a JPEG or PNG photo.',
  'NO_PROPELLERS_DETECTED': 'No propellers were found. Point the camera at the drone from above.',
  'INCOMPLETE_DRONE_VIEW': 'Not all four propellers are visible. Step back so the whole drone is in the frame.',
  'AMBIGUOUS_DETECTIONS': 'More than four propellers were detected. Use a plain background with only this drone in view.',
  'LOW_CONFIDENCE_CLASSIFICATION': 'Some propellers could not be identified confidently. Retake the photo closer and in focus.',
  'UNSUPPORTED_VIEW_TOP_DOWN_REQUIRED': 'Please take the photo straight from above the drone.',
  'MOTOR_ASSIGNMENT_FAILED': 'The motor positions could not be matched. Take the photo straight from above.',
  'REFERENCE_NOT_CONFIGURED': 'The reference configuration is missing.',
  'ENGINE_UNAVAILABLE': 'The verification engine is unavailable on this device.',
  'ENGINE_ERROR': 'The verification engine hit an error. Please try again.',
  'LIVE_TRACKING_UNAVAILABLE': 'Live tracking is not supported. Take a still photo instead.',
};

String _motorName(Object? id) =>
    (id as String? ?? 'motor').replaceAll('_', ' ');

/// Short spoken summary of a result.
String spokenSummary(VerificationResult r) {
  switch (r.status) {
    case VerificationStatus.pass:
      return 'Pass. All four propellers match the reference configuration.';
    case VerificationStatus.incorrectInstallation:
      final wrong = r.motors.where((m) => m['finding'] == 'mismatch').map((m) =>
          'The ${_motorName(m['motor_id'])} propeller is ${m['observed_type']}, '
          'it should be ${m['expected_type']}.');
      return 'Incorrect installation. ${wrong.join(' ')} Swap it for the correct propeller type.';
    case VerificationStatus.unableToVerify:
      final tips = r.reasons.map((c) => reasonGuidance[c]).whereType<String>();
      return 'Unable to verify. ${tips.isEmpty ? 'Please retake the photo from above, in good light.' : tips.join(' ')}';
  }
}

Future<String> explainWithGemini(VerificationResult r) async {
  if (_geminiKey.isEmpty) return spokenSummary(r);
  final facts = jsonEncode({
    'status': r.status.name,
    'reasons': r.reasons,
    'motors': [
      for (final m in r.motors)
        {
          'motor': m['motor_id'],
          'observed_type': m['observed_type'],
          'expected_type': m['expected_type'],
          'finding': m['finding'],
        }
    ],
  });
  final prompt = 'You are the assistant in a Pluto mini-drone propeller '
      'inspection app. The on-device detector produced this result: $facts. '
      'Explain to a beginner, in under 120 words, what the result means and '
      'exactly what to do next (which propeller to swap, or how to retake the '
      'photo: top-down, whole drone visible, steady, good light). CW and CCW '
      'propellers have mirrored blade pitch; diagonal motors share a type. Use '
      'only the facts given; do not invent findings. Never suggest arming or '
      'spinning the motors. Plain text, no markdown.';
  final response = await http
      .post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/'
              '$_geminiModel:generateContent'),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _geminiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }))
      .timeout(const Duration(seconds: 20));
  if (response.statusCode != 200) {
    throw Exception('Gemini HTTP ${response.statusCode}');
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final parts = body['candidates'][0]['content']['parts'] as List;
  return parts.map((p) => p['text']).join().trim();
}

/// Floating voice + AI explanation layer above the inspection UI.
class AssistantLayer extends StatefulWidget {
  const AssistantLayer({super.key, required this.controller, required this.child});
  final RuntimeInspectionController controller;
  final Widget child;
  @override
  State<AssistantLayer> createState() => _AssistantLayerState();
}

class _AssistantLayerState extends State<AssistantLayer> {
  final _tts = FlutterTts();
  StreamSubscription<InspectionState>? _sub;
  VerificationResult? _result;
  bool _voice = true, _loading = false;
  String? _explanation;

  @override
  void initState() {
    super.initState();
    unawaited(_tts.setSpeechRate(0.5));
    _sub = widget.controller.states.listen((s) {
      final r = s.phase == InspectionPhase.result ? s.result : null;
      if (identical(r, _result)) return;
      setState(() {
        _result = r;
        _explanation = null;
      });
      unawaited(_tts.stop());
      if (r != null && r.evidenceSource == 'real' && _voice) {
        unawaited(_tts.speak(spokenSummary(r)));
      }
    });
  }

  Future<void> _explain() async {
    final r = _result;
    if (r == null) return;
    setState(() => _loading = true);
    String text;
    try {
      text = await explainWithGemini(r);
    } catch (_) {
      text = '${spokenSummary(r)}\n\n(AI explanation unavailable offline; showing built-in guidance.)';
    }
    if (!mounted || !identical(r, _result)) return;
    setState(() {
      _loading = false;
      _explanation = text;
    });
    if (_voice) {
      await _tts.stop();
      unawaited(_tts.speak(text.split('\n\n').first));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return MediaQuery.fromView(
      view: View.of(context),
      child: Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        widget.child,
        if (r != null)
          Positioned(
            right: 16,
            bottom: 96,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (_explanation != null)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 340, maxHeight: 320),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: const Color(0xF0141018),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x5539D7E6))),
                      child: SingleChildScrollView(
                          child: Text(_explanation!,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4))),
                    ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _Pill(
                        icon: _voice ? Icons.volume_up : Icons.volume_off,
                        label: _voice ? 'Voice on' : 'Voice off',
                        onTap: () {
                          setState(() => _voice = !_voice);
                          if (!_voice) unawaited(_tts.stop());
                        }),
                    const SizedBox(width: 8),
                    _Pill(
                        icon: Icons.auto_awesome,
                        label: _loading ? 'Thinking…' : (_explanation == null ? 'Explain' : 'Hide'),
                        onTap: _loading
                            ? null
                            : () => _explanation == null
                                ? _explain()
                                : setState(() => _explanation = null)),
                  ]),
                ]),
              ),
            ),
          ),
      ]),
    ));
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: const Color(0xFF39D7E6), borderRadius: BorderRadius.circular(24)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
