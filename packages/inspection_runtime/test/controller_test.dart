import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspection_contract/inspection_contract.dart';
import 'package:inspection_runtime/inspection_runtime.dart';
import 'support.dart';

Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAcquisition acquisition;
  late RuntimeInspectionController controller;
  setUp(() {
    acquisition = FakeAcquisition();
    controller = RuntimeInspectionController(
        acquisition: acquisition,
        engine: GuardedVerificationEngine(),
        normalizer: fakeNormalizer);
  });
  tearDown(() async {
    await controller.dispose();
  });

  test('safety required before acquisition', () async {
    await controller.selectImage();
    expect(controller.current.result!.reasons, ['SAFETY_NOT_CONFIRMED']);
    expect(acquisition.closes, 0);
  });
  test('upload acquires image but missing reference never passes', () async {
    await controller.setSafetyConfirmed(true);
    await controller.selectImage();
    expect(controller.current.image!.source, 'upload');
    expect(
        controller.current.result!.status, VerificationStatus.unableToVerify);
    expect(controller.current.result!.elapsedMs, isNonNegative);
  });
  test('cancelled picker clears a prior result', () async {
    await controller.setSafetyConfirmed(true);
    await controller.selectImage();
    acquisition.picker = () async => null;
    await controller.selectImage();
    expect(controller.current.result, null);
    expect(controller.current.image, null);
    expect(controller.current.phase, InspectionPhase.idle);
  });
  test('engine exception fails closed', () async {
    await controller.replaceEngine(
        FakeEngine((_) async => throw StateError('fixture error')));
    await controller.setSafetyConfirmed(true);
    await controller.selectImage();
    expect(controller.current.result!.reasons, ['ENGINE_ERROR']);
  });
  test('late result after safety revoke is discarded', () async {
    final response = Completer<VerificationResult>();
    final entered = Completer<InspectionImage>();
    await controller.replaceEngine(FakeEngine((image) {
      entered.complete(image);
      return response.future;
    }));
    await controller.setSafetyConfirmed(true);
    final selecting = controller.selectImage();
    final image = await entered.future;
    await controller.setSafetyConfirmed(false);
    response.complete(syntheticPass(image));
    await selecting;
    expect(controller.current.result, null);
    expect(controller.current.safetyConfirmed, false);
  });
  test('engine/reference replacement invalidates in-flight result', () async {
    final entered = Completer<InspectionImage>();
    final response = Completer<VerificationResult>();
    await controller.replaceEngine(FakeEngine((image) {
      entered.complete(image);
      return response.future;
    }));
    await controller.setSafetyConfirmed(true);
    final selecting = controller.selectImage();
    final image = await entered.future;
    await controller.replaceEngine(GuardedVerificationEngine());
    response.complete(syntheticPass(image));
    await selecting;
    expect(controller.current.result, null);
    expect(controller.current.safetyConfirmed, false);
  });
  test('new upload supersedes active input; one engine call at a time',
      () async {
    final response = Completer<VerificationResult>();
    final entered = Completer<InspectionImage>();
    var calls = 0, active = 0, maxActive = 0;
    await controller.replaceEngine(FakeEngine((image) async {
      calls++;
      active++;
      if (active > maxActive) maxActive = active;
      if (calls == 1) {
        entered.complete(image);
        final result = await response.future;
        active--;
        return result;
      }
      active--;
      return unable(image.id, ['REFERENCE_NOT_CONFIGURED']);
    }));
    await controller.setSafetyConfirmed(true);
    final first = controller.selectImage();
    final image = await entered.future;
    final second = controller.selectImage();
    await tick();
    // A third request is ignored while the single pending upload is occupied.
    await controller.selectImage();
    expect(calls, 1);
    expect(controller.current.result, null);
    response.complete(syntheticPass(image));
    await Future.wait([first, second]);
    expect(calls, 2);
    expect(maxActive, 1);
    expect(controller.current.result!.inputId, isNot(image.id));
    expect(
        controller.current.result!.status, VerificationStatus.unableToVerify);
  });
  test('camera permission denial is device error, not verification result',
      () async {
    acquisition.cameraError =
        CameraException('CameraAccessDenied', 'synthetic denial');
    await controller.setSafetyConfirmed(true);
    await controller.startLive();
    expect(controller.current.phase, InspectionPhase.error);
    expect(controller.current.message, contains('CAMERA_PERMISSION_DENIED'));
    expect(controller.current.result, null);
  });
  test('background cancels inference, clears safety and releases camera',
      () async {
    final response = Completer<VerificationResult>();
    final entered = Completer<InspectionImage>();
    await controller.replaceEngine(FakeEngine((image) {
      entered.complete(image);
      return response.future;
    }));
    await controller.setSafetyConfirmed(true);
    final selecting = controller.selectImage();
    final image = await entered.future;
    await controller.suspend();
    response.complete(syntheticPass(image));
    await selecting;
    expect(controller.current.result, null);
    expect(controller.current.safetyConfirmed, false);
    controller.resume();
    expect(acquisition.opens, 0);
  });
  test('system picker may background without losing returned bytes', () async {
    final response = Completer<Uint8List?>();
    acquisition.picker = () => response.future;
    await controller.setSafetyConfirmed(true);
    final selecting = controller.selectImage();
    await tick();
    await controller.suspend();
    response.complete(Uint8List(1));
    await selecting;
    expect(controller.current.safetyConfirmed, false);
    expect(controller.current.result, null);
    controller.resume();
    await controller.setSafetyConfirmed(true);
    acquisition.picker =
        () async => throw StateError('should use retained image');
    await controller.selectImage();
    expect(controller.current.image, isNotNull);
  });
  test('camera preview does not capture or reopen until shutter pressed',
      () async {
    await controller.setSafetyConfirmed(true);
    await controller.startLive();
    final closes = acquisition.closes;
    await Future<void>.delayed(const Duration(milliseconds: 850));
    await controller.startLive();
    expect(acquisition.opens, 1);
    expect(acquisition.captures, 0);
    expect(acquisition.closes, closes);
    expect(controller.current.phase, InspectionPhase.idle);
    await controller.stopLive();
    expect(acquisition.closes, closes + 1);
  });
  test('manual capture freezes one result without reopening camera', () async {
    final response = Completer<VerificationResult>();
    final entered = Completer<InspectionImage>();
    await controller.replaceEngine(FakeEngine((image) {
      entered.complete(image);
      return response.future;
    }));
    await controller.setSafetyConfirmed(true);
    await controller.startLive();
    final capture = controller.captureLiveImage();
    final image = await entered.future;
    await tick();
    expect(acquisition.captures, 1);
    response.complete(syntheticPass(image));
    await capture;
    expect(controller.current.result!.status, VerificationStatus.pass);
    expect(controller.current.image!.source, 'live');
    expect(acquisition.opens, 1);
    expect(acquisition.captures, 1);
    await controller.stopLive();
    expect(controller.current.result, null);
  });
  test('stop live during capture suppresses late input', () async {
    final captured = Completer<Uint8List>();
    acquisition.capturer = () => captured.future;
    await controller.setSafetyConfirmed(true);
    await controller.startLive();
    final capture = controller.captureLiveImage();
    await tick();
    await controller.stopLive();
    captured.complete(Uint8List(1));
    await capture;
    expect(controller.current.result, null);
    expect(controller.current.image, null);
  });
  test('double shutter press produces one capture', () async {
    final captured = Completer<Uint8List>();
    acquisition.capturer = () => captured.future;
    await controller.setSafetyConfirmed(true);
    await controller.startLive();
    final capture = controller.captureLiveImage();
    await tick();
    await controller.captureLiveImage();
    expect(acquisition.captures, 1);
    captured.complete(Uint8List(1));
    await capture;
    expect(controller.current.result!.reasons, ['REFERENCE_NOT_CONFIGURED']);
    await controller.captureLiveImage();
    expect(acquisition.captures, 1);
  });
  test('capture failure closes camera and allows explicit retry', () async {
    acquisition.capturer =
        () async => throw CameraException('captureFailed', 'fixture');
    await controller.setSafetyConfirmed(true);
    await controller.startLive();
    await controller.captureLiveImage();
    expect(controller.current.phase, InspectionPhase.error);
    expect(controller.current.result, null);
    expect(acquisition.opens, 1);
    acquisition.capturer = null;
    await controller.startLive();
    expect(acquisition.opens, 2);
    expect(acquisition.captures, 1);
  });
  test('background closes idle preview and does not restart on resume',
      () async {
    await controller.setSafetyConfirmed(true);
    await controller.startLive();
    await controller.suspend();
    controller.resume();
    expect(controller.current.safetyConfirmed, false);
    expect(acquisition.opens, 1);
    expect(acquisition.captures, 0);
    await controller.captureLiveImage();
    expect(acquisition.captures, 0);
  });
  test('recovered upload requires fresh safety action', () async {
    acquisition.recovered = Uint8List(1);
    await controller.initialize();
    expect(controller.current.safetyConfirmed, false);
    expect(controller.current.image, null);
    await controller.setSafetyConfirmed(true);
    await controller.selectImage();
    expect(controller.current.image, isNotNull);
  });
  test('dispose ignores late results and closes stream once', () async {
    final response = Completer<VerificationResult>();
    final entered = Completer<InspectionImage>();
    await controller.replaceEngine(FakeEngine((image) {
      entered.complete(image);
      return response.future;
    }));
    await controller.setSafetyConfirmed(true);
    final selecting = controller.selectImage();
    final image = await entered.future;
    await controller.dispose();
    response.complete(syntheticPass(image));
    await selecting;
    await controller.dispose();
    expect(acquisition.disposed, true);
    expect(controller.current.result, null);
  });
}
