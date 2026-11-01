import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:inspection_contract/inspection_contract.dart';

import 'acquisition.dart';
import 'engine.dart';
import 'normalization.dart';

class RuntimeInspectionController implements InspectionController {
  RuntimeInspectionController(
      {required this.acquisition,
      required VerificationEngine engine,
      ImageNormalizer normalizer = normalizeImage})
      : _engine = engine,
        _normalizer = normalizer;

  final ImageAcquisition acquisition;
  VerificationEngine _engine;
  final ImageNormalizer _normalizer;

  final _events = StreamController<InspectionState>.broadcast();
  InspectionState _current = const InspectionState(
      message: 'Follow the supplied drone disarming procedure and '
          'visually confirm every motor is stopped before inspecting. '
          'Confirmation cannot prove hardware disarm.');
  bool _disposed = false,
      _live = false,
      _foreground = true,
      _queuedUpload = false,
      _capturing = false;
  int? _pickerGeneration;
  bool get _picking => _pickerGeneration != null;
  int _generation = 0, _inputNumber = 0;
  Future<void>? _work;
  Uint8List? _recovered;
  @override
  InspectionState get current => _current;
  @override
  Stream<InspectionState> get states => _events.stream;
  bool _valid(int generation) => !_disposed && generation == _generation;

  void _emit(InspectionState state) {
    if (_disposed) return;
    _current = state;
    _events.add(state);
  }

  void _clear(String message,
          {bool? safety, InspectionPhase phase = InspectionPhase.idle}) =>
      _emit(InspectionState(
          phase: phase,
          safetyConfirmed: safety ?? current.safetyConfirmed,
          message: message));

  Future<void> initialize() async {
    if (_disposed) return;
    final generation = _generation;
    try {
      final recovered = await acquisition.recoverImage();
      if (!_valid(generation) || recovered == null) return;
      _recovered = recovered;
      _clear(
          'An interrupted upload was recovered. Repeat the safety procedure, '
          'confirm it, then choose Upload to inspect this image.',
          safety: false);
    } catch (_) {
      if (_valid(generation))
        _clear('Previous upload could not be recovered. Select it again.');
    }
  }

  @override
  Future<void> setSafetyConfirmed(bool confirmed) async {
    if (_disposed) return;
    _generation++;
    _live = false;
    _clear(
        confirmed
            ? 'Keep all motors stopped. This confirmation does not prove hardware disarm.'
            : 'Complete the disarmed / motors-stopped procedure before selecting input.',
        safety: confirmed);
    await _closeCamera();
  }

  bool _allowInput() {
    if (_disposed || !_foreground) return false;
    if (current.safetyConfirmed) return true;
    _emit(InspectionState(
        phase: InspectionPhase.result,
        message:
            'Disarm using the supplied procedure and confirm every motor has stopped.',
        result: unable('safety', const ['SAFETY_NOT_CONFIRMED'])));
    return false;
  }

  @override
  Future<void> selectImage() async {
    if (!_allowInput() || _picking || _queuedUpload) return;
    final queued = _work != null;
    if (queued) _queuedUpload = true;
    final generation = ++_generation;
    _live = false;
    _pickerGeneration = generation;
    _clear('Select a complete, sharp JPEG or PNG of the supplied drone.',
        phase: InspectionPhase.processing);
    try {
      await acquisition.closeCamera();
      if (!_valid(generation)) return;
      final bytes = _recovered ?? await acquisition.pickImage();
      if (_pickerGeneration == generation) _pickerGeneration = null;
      _recovered = null;
      if (!_valid(generation)) return;
      if (bytes == null) {
        _clear('Image selection cancelled.');
        return;
      }
      if (!_foreground) {
        _recovered = bytes;
        _clear(
            'Upload retained. Return to the app, repeat the safety procedure, '
            'then choose Upload.',
            safety: false);
        return;
      }
      await _inspect(bytes, 'upload', generation);
    } catch (error) {
      if (_valid(generation)) _deviceError(error);
    } finally {
      if (_pickerGeneration == generation) _pickerGeneration = null;
      if (queued) _queuedUpload = false;
    }
  }

  @override
  Future<void> startLive() async {
    if (!_allowInput() || _live || _picking) return;
    final generation = ++_generation;
    _live = true;
    _clear(
        'Opening rear camera. Keep the whole drone visible and motors stopped.',
        phase: InspectionPhase.processing);
    try {
      await acquisition.openCamera();
      if (!_valid(generation)) return;
      _clear('Camera ready. Frame the whole drone, then tap Take photo.');
    } catch (error) {
      if (_valid(generation)) {
        _live = false;
        _deviceError(error);
        await _closeCamera();
      }
    }
  }

  /// App-owned shutter injected with the camera preview; shared v1 stays intact.
  /// Preview never takes pictures or runs inference until this is pressed.
  Future<void> captureLiveImage() async {
    if (!_allowInput() || !_live || _capturing) return;
    final generation = _generation;
    _capturing = true;
    _clear('Taking photo...', phase: InspectionPhase.processing);
    try {
      await _waitForWork();
      if (!_valid(generation)) return;
      final endToEnd = Stopwatch()..start();
      final bytes = await acquisition.capture();
      if (!_valid(generation)) return;
      // Freeze the chosen still once. Never alternate it with later preview
      // frames, and never reopen the camera after inference completes.
      _live = false;
      await _closeCamera();
      if (!_valid(generation)) return;
      await _inspect(bytes, 'live', generation, endToEnd: endToEnd);
    } catch (error) {
      if (_valid(generation)) {
        _live = false;
        _deviceError(error);
        await _closeCamera();
      }
    } finally {
      _capturing = false;
    }
  }

  Future<void> _waitForWork() async {
    while (_work != null) {
      await _work;
    }
  }

  Future<void> _inspect(Uint8List bytes, String source, int generation,
      {Stopwatch? endToEnd}) async {
    // Acquire synchronously after each wait, so competing callers cannot both
    // reserve an empty slot across a Future continuation.
    while (_work != null) {
      await _work;
    }
    if (!_valid(generation)) return;
    final finished = Completer<void>();
    _work = finished.future;
    // Live includes camera capture/file read; upload starts at selected bytes
    // becoming available, excluding human time in the system picker.
    final stopwatch = endToEnd ?? (Stopwatch()..start());
    final id = '${DateTime.now().microsecondsSinceEpoch}-${++_inputNumber}';
    try {
      _clear('Preparing upright image…', phase: InspectionPhase.processing);
      final image = await _normalizer(bytes, id, source);
      if (!_valid(generation)) return;
      _emit(InspectionState(
          phase: InspectionPhase.processing,
          safetyConfirmed: true,
          image: image,
          message: 'Checking local reference and engine…'));
      var result = await _engine.verify(image);
      if (!_valid(generation)) return;
      if (result.inputId != image.id || result.evidenceSource != 'real') {
        result = unable(image.id, const ['ENGINE_ERROR']);
      }
      // A sampled still cannot establish that a moving preview remains tracked.
      // Fail closed until ML supplies a tracking/observability protocol.
      if (source == 'live' &&
          result.status != VerificationStatus.unableToVerify) {
        result = unable(image.id, const ['LIVE_TRACKING_UNAVAILABLE'],
            referenceVersion: result.referenceVersion);
      }
      stopwatch.stop();
      result = VerificationResult(
          inputId: result.inputId,
          status: result.status,
          evidenceSource: result.evidenceSource,
          referenceVersion: result.referenceVersion,
          engineVersion: result.engineVersion,
          allRequiredChecksObservable: result.allRequiredChecksObservable,
          reasons: result.reasons,
          motors: result.motors,
          elapsedMs: stopwatch.elapsedMicroseconds / 1000);
      _emit(InspectionState(
          phase: InspectionPhase.result,
          safetyConfirmed: true,
          image: image,
          result: result,
          message: result.status == VerificationStatus.unableToVerify
              ? 'Unable to Verify: ${result.reasons.join(', ')}. '
                  'No flight clearance is provided.'
              : 'Visual inspection of this still only; not general flight clearance.'));
    } on FormatException {
      if (_valid(generation))
        _emit(InspectionState(
            phase: InspectionPhase.result,
            safetyConfirmed: current.safetyConfirmed,
            message:
                'Unsupported, damaged or oversized image. Use a sharp JPEG/PNG '
                'under 20 MiB and 16 megapixels.',
            result: unable(id, const ['INVALID_INPUT'])));
    } catch (_) {
      if (_valid(generation))
        _emit(InspectionState(
            phase: InspectionPhase.result,
            safetyConfirmed: current.safetyConfirmed,
            message: 'Local verification failed. Select input to retry.',
            result: unable(id, const ['ENGINE_ERROR'])));
    } finally {
      _work = null;
      finished.complete();
    }
  }

  void _deviceError(Object error) {
    final code = switch (error) {
      AcquisitionFailure(:final code) => code,
      CameraException(:final code) when code.startsWith('CameraAccessDenied') =>
        'CAMERA_PERMISSION_DENIED',
      PlatformException(:final code) when code.contains('access_denied') =>
        'PHOTO_PERMISSION_DENIED',
      _ => 'ACQUISITION_FAILED',
    };
    _clear(
        '$code. Check app permissions in Android Settings and retry. '
        'Keep the drone disarmed and motors stopped.',
        phase: InspectionPhase.error);
  }

  Future<void> _closeCamera() async {
    try {
      await acquisition.closeCamera();
    } catch (_) {
      if (!_disposed)
        _clear('Camera shutdown failed. Close the app before retrying.',
            phase: InspectionPhase.error);
    }
  }

  @override
  Future<void> stopLive() async {
    if (_disposed) return;
    _generation++;
    _live = false;
    _clear('Stopped. Previous results cleared.');
    await _closeCamera();
  }

  /// Called by the shell on lifecycle changes. Resume requires an explicit
  /// safety confirmation and Start Live; the camera never restarts itself.
  Future<void> suspend() async {
    if (_disposed) return;
    _foreground = false;
    // Android's system photo picker backgrounds this Activity too.
    if (_picking) return;
    _generation++;
    _live = false;
    _clear('App paused. Repeat the safety procedure before restarting.',
        safety: false);
    await _closeCamera();
  }

  void resume() {
    _foreground = true;
  }

  Future<void> replaceEngine(VerificationEngine engine) async {
    if (_disposed) return;
    _generation++;
    _live = false;
    _engine = engine;
    _clear('Reference/engine changed. Repeat the safety procedure.',
        safety: false);
    await _closeCamera();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _live = false;
    await acquisition.dispose();
    await _events.close();
  }
}
