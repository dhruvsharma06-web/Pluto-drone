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
import '../lib/src/theme.dart';
import '../lib/src/drone_stage.dart';

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
  setUp(() {
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
  });
  setUpAll(() async {
    const privatePhoto = String.fromEnvironment('TEAM_PHOTO_PATH');
    photoBytes = await File(privatePhoto.isEmpty
            ? 'example/assets/illustrative-drone.png'
            : privatePhoto)
        .readAsBytes();
    final loader = FontLoader('packages/inspection_ui/InspectionSans');
    for (final name in ['Inter'])
      loader.addFont(File('assets/fonts/$name.ttf')
          .readAsBytes()
          .then((v) => ByteData.sublistView(v)));
    await loader.load();
    final display = FontLoader('packages/inspection_ui/InspectionDisplay')
      ..addFont(File('assets/fonts/PlayfairDisplay.ttf')
          .readAsBytes()
          .then((v) => ByteData.sublistView(v)))
      ..addFont(File('assets/fonts/PlayfairDisplay-Italic.ttf')
          .readAsBytes()
          .then((v) => ByteData.sublistView(v)));
    await display.load();
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
      'capture uses large phone surface and close returns to inspection',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final c = TestController(const InspectionState(safetyConfirmed: true));
    await tester.pumpWidget(InspectionApp(
        controller: c, cameraPreview: const ColoredBox(color: Colors.black)));
    final action = find.byKey(const ValueKey('primary-inspection-action'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Capture photo'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('capture-stage'))).height,
        closeTo(844 * .78, 1));
    await tester.tap(find.byTooltip('Close camera'));
    await tester.pumpAndSettle();
    expect(c.stopCalls, 1);
    expect(find.text('Capture photo'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
  });
  testWidgets('capture supports short landscape, large text and Android Back',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final c = TestController(const InspectionState(safetyConfirmed: true));
    await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: InspectionApp(
            controller: c,
            cameraPreview: const ColoredBox(color: Colors.black))));
    final action = find.byKey(const ValueKey('primary-inspection-action'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(c.stopCalls, 1);
    expect(find.text('Capture photo'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
  });
  testWidgets('inactive camera permission prompt does not stop camera startup',
      (tester) async {
    final c = TestController(const InspectionState(safetyConfirmed: true))
      ..pending = Completer<void>();
    await tester.pumpWidget(InspectionApp(controller: c));
    final action = find.byKey(const ValueKey('primary-inspection-action'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(c.stopCalls, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    c.pending!.complete();
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(c.stopCalls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
    for (final width in [320.0, 390.0, 768.0, 1440.0])
      for (final scale in [1.0, 1.5])
        (width, width < 500 ? 844.0 : 1024.0, scale, true)
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

  test('palette and contrast follow the website', () {
    final c = inspectionTheme(Brightness.dark).colorScheme;
    for (final color in [
      c.primary,
      c.onPrimary,
      c.primaryContainer,
      c.onPrimaryContainer,
      c.secondary,
      c.onSecondary,
      c.secondaryContainer,
      c.onSecondaryContainer,
      c.tertiary,
      c.onTertiary,
      c.tertiaryContainer,
      c.onTertiaryContainer,
      c.error,
      c.onError,
      c.errorContainer,
      c.onErrorContainer,
      c.surface,
      c.onSurface,
      c.onSurfaceVariant,
      c.outline,
      c.outlineVariant,
      c.surfaceContainerLowest,
      c.surfaceContainerLow,
      c.surfaceContainer,
      c.surfaceContainerHigh,
      c.surfaceContainerHighest,
      c.inverseSurface,
      c.onInverseSurface,
      c.inversePrimary,
      c.surfaceTint
    ]) {
      expect(color, isNot(const Color(0xff00e5ff)));
    }
    double contrast(Color foreground) =>
        (foreground.computeLuminance() + .05) /
        (inspectionGround.computeLuminance() + .05);
    expect(contrast(inspectionInk), greaterThanOrEqualTo(7));
    expect(contrast(inspectionMuted), greaterThanOrEqualTo(4.5));
    expect(contrast(inspectionAccent), greaterThanOrEqualTo(3));
  });
  testWidgets('exact labels and distinct symbols for every result',
      (tester) async {
    for (final (scenario, status) in [
      ('pass', VerificationStatus.pass),
      ('incorrect', VerificationStatus.incorrectInstallation),
      ('reference', VerificationStatus.unableToVerify)
    ]) {
      final c = await fixture(scenario);
      await tester.pumpWidget(InspectionApp(controller: c, demoMode: true));
      await tester.pumpAndSettle();
      expect(
          find.text(resultLabel(status), findRichText: true), findsOneWidget);
      expect(
          find.byKey(ValueKey('result-symbol-${status.name}')), findsOneWidget);
      expect(find.text('Demo · Simulated results'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await c.dispose();
    }
  });
  testWidgets('reduced motion freezes mist and processing scan',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(390, 844), disableAnimations: true),
            child: const Scaffold(body: DroneStage(processing: true)))));
    await tester.pumpAndSettle();
    DroneStagePainter painter() => tester
        .widget<CustomPaint>(
            find.byKey(const ValueKey('illustrative-drone-stage')))
        .painter! as DroneStagePainter;
    expect(painter().phase, 0);
    await tester.pump(const Duration(seconds: 3));
    expect(painter().phase, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('motor guidance closes as soon as its result is invalidated',
      (tester) async {
    final c = await fixture('incorrect');
    await tester.pumpWidget(InspectionApp(controller: c, demoMode: true));
    await tester.pumpAndSettle();
    final target = find.text('Sample B');
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.text('Where'), findsOneWidget);
    expect(find.text('Why'), findsOneWidget);
    expect(find.text('Correction'), findsOneWidget);
    c.show('prepare');
    await tester.pumpAndSettle();
    expect(find.text('Where'), findsNothing);
    expect(
        find.text('Incorrect Installation', findRichText: true), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await c.dispose();
  });
  testWidgets('mist runs onscreen and stops when scrolled out', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: false);
    final scroll = ScrollController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                controller: scroll,
                child: const Column(
                    children: [DroneStage(), SizedBox(height: 2000)])))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    DroneStagePainter painter() => tester
        .widget<CustomPaint>(
            find.byKey(const ValueKey('illustrative-drone-stage')))
        .painter! as DroneStagePainter;
    expect(painter().phase, greaterThan(0));
    scroll.jumpTo(500);
    await tester.pump();
    final stopped = painter().phase;
    await tester.pump(const Duration(seconds: 2));
    expect(painter().phase, stopped);
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });

  testWidgets('capture rendered UI evidence', (tester) async {
    final dest = const String.fromEnvironment('SCREENSHOT_DIR');
    if (dest.isEmpty) return;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final key = GlobalKey();
    for (final (name, scenario, width, height, dark) in [
      for (final width in [320.0, 390.0, 768.0, 1440.0])
        for (final scale in [1.0, 1.5])
          for (final scenario in ['prepare', 'incorrect'])
            (
              '$scenario-$width-$scale',
              scenario,
              width,
              width < 500 ? 844.0 : 1024.0,
              true
            ),
      ('reference-phone', 'reference', 390.0, 844.0, true),
      ('pass-phone', 'pass', 390.0, 844.0, true),
      ('processing-phone', 'processing', 390.0, 844.0, true)
    ]) {
      tester.view.physicalSize = Size(width, height);
      tester.platformDispatcher.textScaleFactorTestValue =
          name.endsWith('-1.5') ? 1.5 : 1;
      final c = await fixture(scenario);
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: InspectionApp(
              controller: c,
              demoMode: true,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light)));
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
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
