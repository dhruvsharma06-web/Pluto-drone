import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspection_contract/inspection_contract.dart';
import 'package:inspection_ui/inspection_ui.dart';
import '../example/lib/fixture_controller.dart';
import 'package:inspection_ui/src/drone_stage.dart';
import 'package:inspection_ui/src/motor_finding.dart';
import 'package:inspection_ui/src/presentation.dart' show motorWhy;

late Uint8List photoBytes;

class TestController implements InspectionController {
  TestController([this.value = const InspectionState()]);
  InspectionState value;
  final events = StreamController<InspectionState>.broadcast();
  int liveCalls = 0, photoCalls = 0, stopCalls = 0;
  bool fail = false;
  Completer<void>? pending;
  @override
  InspectionState get current => value;
  @override
  Stream<InspectionState> get states => events.stream;
  void emit(InspectionState next) {
    value = next;
    events.add(next);
  }

  @override
  Future<void> setSafetyConfirmed(bool v) async =>
      emit(InspectionState(safetyConfirmed: v));
  @override
  Future<void> selectImage() async {
    photoCalls++;
    if (fail) throw StateError('private stack detail');
    await pending?.future;
  }

  @override
  Future<void> startLive() async {
    liveCalls++;
    if (fail) throw StateError('private stack detail');
    await pending?.future;
  }

  @override
  Future<void> stopLive() async {
    stopCalls++;
    emit(InspectionState(safetyConfirmed: current.safetyConfirmed));
  }

  @override
  Future<void> dispose() async => events.close();
}

Future<FixtureController> fixture(String name) async {
  final c = FixtureController(photoBytes);
  c.show(name);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const privatePhoto = String.fromEnvironment('TEAM_PHOTO_PATH');
    photoBytes = await File(privatePhoto.isEmpty
            ? 'example/assets/illustrative-drone.png'
            : privatePhoto)
        .readAsBytes();
    final loader = FontLoader('packages/inspection_ui/InspectionSans');
    for (final name in ['Regular', 'Medium', 'Bold'])
      loader.addFont(File('assets/fonts/Roboto-$name.ttf')
          .readAsBytes()
          .then((v) => ByteData.sublistView(v)));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  test('portrait and rotated image boxes preserve contain geometry', () {
    final portrait =
        containedImageRect(const Size(400, 300), const Size(300, 400));
    expect(portrait, const Rect.fromLTWH(87.5, 0, 225, 300));
    expect(motorBoxRect([0, .25, .5, .5], portrait),
        const Rect.fromLTWH(87.5, 75, 112.5, 150));
    final landscape =
        containedImageRect(const Size(300, 400), const Size(400, 300));
    expect(landscape, const Rect.fromLTWH(0, 87.5, 300, 225));
    expect(motorBoxRect([.9, 0, .2, .2], landscape), isNull);
    expect(motorBoxRect([double.nan, 0, .1, .1], landscape), isNull);
    expect(motorBoxRect([0, 0, 0, .2], landscape), isNull);
  });
  test('finding explains only supplied differences and image coordinates', () {
    final motor = <String, Object?>{
      'motor_id': 'M2',
      'bbox': [.7, .1, .2, .2],
      'finding': 'mismatch',
      'observed_type': 'B',
      'expected_type': 'A',
      'observed_orientation': 'face down',
      'expected_orientation': 'face up',
    };
    expect(motorWhere(motor), 'M2 · Upper right of image.');
    expect(motorWhy(motor), contains('Type: observed B; expected A.'));
    expect(motorWhy(motor),
        contains('Orientation: observed face down; expected face up.'));
    expect(motorWhy({...motor, 'finding': 'unknown'}),
        'This part could not be verified from the image.');
    expect(motorWhy({'finding': 'mismatch'}),
        contains('a specific reason was not supplied'));
    expect(
        motorWhere({
          ...motor,
          'bbox': [double.nan, 0, .1, .2]
        }),
        'M2 · Image location not supplied.');
    expect(motorWhere({...motor, 'bbox': null}),
        'M2 · Image location not supplied.');
  });

  testWidgets('issue box opens matching details and closes on new inspection',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await fixture('incorrect');
    await tester.pumpWidget(InspectionApp(controller: c));
    await tester.pumpAndSettle();
    await tester.runAsync(() => precacheImage(MemoryImage(photoBytes),
        tester.element(find.byType(InteractiveViewer))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('motor-box-Sample A')), findsNothing);
    final box = find.byKey(const ValueKey('motor-box-Sample B'));
    expect(box, findsOneWidget);
    await tester.tap(box);
    await tester.pumpAndSettle();
    expect(find.byType(MotorFindingSheet), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(MotorFindingSheet), matching: find.text('Where')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(MotorFindingSheet), matching: find.text('Why')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(MotorFindingSheet),
            matching: find.text('Correction')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(MotorFindingSheet),
            matching: find.text('Sample B · Upper right of image.')),
        findsOneWidget);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    c.show('processing');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // The broadcast event pops the route, then its reverse ticker starts.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MotorFindingSheet), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
  });
  test('processing and mismatched image identity suppress stale result',
      () async {
    final c = await fixture('pass');
    final s = c.current;
    expect(displayedResult(s)?.status, VerificationStatus.pass);
    expect(
        displayedResult(InspectionState(
            phase: InspectionPhase.processing,
            safetyConfirmed: true,
            image: s.image,
            result: s.result)),
        isNull);
    expect(
        displayedResult(InspectionState(
            phase: InspectionPhase.result,
            safetyConfirmed: true,
            image: InspectionImage(
                id: 'different',
                bytes: s.image!.bytes,
                width: 960,
                height: 1280,
                source: 'upload'),
            result: s.result)),
        isNull);
    await c.dispose();
  });
  test('incomplete and inconsistent Pass becomes Unable to Verify', () async {
    final c = await fixture('pass');
    final r = c.current.result!;
    for (final bad in [
      VerificationResult(
          inputId: r.inputId,
          status: r.status,
          evidenceSource: 'fixture',
          allRequiredChecksObservable: false),
      VerificationResult(
          inputId: r.inputId,
          status: r.status,
          evidenceSource: 'fixture',
          allRequiredChecksObservable: true,
          referenceVersion: 'pending',
          engineVersion: 'fixture',
          motors: r.motors),
      VerificationResult(
          inputId: r.inputId,
          status: r.status,
          evidenceSource: 'fixture',
          allRequiredChecksObservable: true,
          referenceVersion: r.referenceVersion,
          engineVersion: r.engineVersion,
          motors: [
            {...r.motors.first, 'observed_type': 'Wrong'}
          ]),
    ])
      expect(
          displayedResult(InspectionState(
                  phase: InspectionPhase.result,
                  safetyConfirmed: true,
                  result: bad))
              ?.status,
          VerificationStatus.unableToVerify);
    expect(
        displayedResult(InspectionState(
                phase: InspectionPhase.result,
                safetyConfirmed: false,
                result: r))
            ?.status,
        VerificationStatus.unableToVerify);
    await c.dispose();
  });
  testWidgets('safety blocks acquisition, then delegates to controller',
      (tester) async {
    final c = TestController();
    await tester.pumpWidget(InspectionApp(controller: c));
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('primary-inspection-action')))
            .onPressed,
        isNull);
    await tester
        .ensureVisible(find.byKey(const ValueKey('safety-confirmation')));
    await tester.tap(find.byKey(const ValueKey('safety-confirmation')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('primary-inspection-action')));
    await tester.tap(find.byKey(const ValueKey('primary-inspection-action')));
    await tester.pump();
    expect(c.liveCalls, 1);
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
  });
  testWidgets(
      'new operation immediately removes old Pass even before controller emits',
      (tester) async {
    final f = await fixture('pass');
    final c = TestController(f.current)..pending = Completer<void>();
    await tester.pumpWidget(InspectionApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Pass'), findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const ValueKey('primary-inspection-action')));
    await tester.tap(find.byKey(const ValueKey('primary-inspection-action')));
    await tester.pump();
    expect(find.text('Pass'), findsNothing);
    expect(c.photoCalls, 1);
    c.pending!.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
    await f.dispose();
  });
  testWidgets('controller failures use safe actionable copy', (tester) async {
    final c = TestController(const InspectionState(safetyConfirmed: true))
      ..fail = true;
    await tester.pumpWidget(InspectionApp(controller: c));
    await tester
        .ensureVisible(find.byKey(const ValueKey('primary-inspection-action')));
    await tester.tap(find.byKey(const ValueKey('primary-inspection-action')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Inspection could not start'), findsOneWidget);
    expect(find.textContaining('private stack'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
  });
  testWidgets('fixture notice stays visible in guide and project',
      (tester) async {
    final c = await fixture('incorrect');
    await tester.pumpWidget(InspectionApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Demo · Simulated results'), findsOneWidget);
    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    expect(find.text('Demo · Simulated results'), findsOneWidget);
    await tester.tap(find.text('Project'));
    await tester.pumpAndSettle();
    expect(find.text('Simulated UI fixture'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
  });
  testWidgets('changing input mode hides previous result', (tester) async {
    final c = await fixture('pass');
    await tester.pumpWidget(InspectionApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Live camera'));
    await tester.pumpAndSettle();
    expect(find.text('Pass'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
  });

  for (final (width, height, scale, dark) in [
    (320.0, 740.0, 1.0, false),
    (390.0, 844.0, 1.0, false),
    (390.0, 844.0, 1.5, true),
    (768.0, 1024.0, 1.0, false),
    (1440.0, 900.0, 1.0, false)
  ]) {
    testWidgets('layout $width scale $scale dark $dark', (tester) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await fixture('prepare');
      await tester.pumpWidget(InspectionApp(
          controller: c,
          demoMode: true,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      c.show('incorrect');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Guide'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await c.dispose();
    });
  }

  testWidgets('processing graphics honour reduced motion', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child:
                SizedBox(width: 300, height: 250, child: ProcessingSweep()))));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('illustrative scene responds to drag and settles',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: SizedBox(width: 390, height: 300, child: DroneStage())));
    await tester.drag(find.byType(DroneStage), const Offset(35, -15));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('capture rendered UI evidence', (tester) async {
    final dest = const String.fromEnvironment('SCREENSHOT_DIR');
    if (dest.isEmpty) return;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final (name, scenario, width, height, dark) in [
      ('prepare-phone', 'prepare', 390.0, 844.0, true),
      ('reference-phone', 'reference', 390.0, 844.0, false),
      ('mismatch-tablet', 'incorrect', 1100.0, 1000.0, false),
      ('finding-phone', 'incorrect', 390.0, 844.0, true),
      ('pass-dark', 'pass', 390.0, 844.0, true)
    ]) {
      final key = GlobalKey();
      tester.view.physicalSize = Size(width, height);
      final c = await fixture(scenario);
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: InspectionApp(
              controller: c,
              demoMode: true,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light)));
      await tester.pumpAndSettle();
      if (c.current.image != null) {
        await tester.runAsync(() => precacheImage(MemoryImage(photoBytes),
            tester.element(find.byType(InteractiveViewer))));
        await tester.pumpAndSettle();
      }
      if (name == 'finding-phone') {
        await tester.tap(find.byKey(const ValueKey('motor-box-Sample B')));
        await tester.pumpAndSettle();
      }
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      boundary.markNeedsPaint();
      await tester.pump();
      await tester.runAsync(() async {
        final im = await boundary.toImage(pixelRatio: 2);
        final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
        await File('$dest/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        im.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      await c.dispose();
    }
  });
}
