import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspection_contract/inspection_contract.dart';
import 'evidence_view.dart';
import 'presentation.dart';
import 'support_views.dart';
import 'theme.dart';
import 'inspection_mark.dart';
import 'capture_view.dart';
import 'drone_stage.dart';
import 'result_symbol.dart';
import 'reveal.dart';
import 'motor_detail.dart';
import 'control_feedback.dart';
import 'input_choices.dart';

/// Drop-in presentation. The caller owns and disposes [controller].
class InspectionApp extends StatelessWidget {
  const InspectionApp(
      {super.key,
      required this.controller,
      this.cameraPreview,
      this.themeMode = ThemeMode.system,
      this.demoMode = false,
      this.developmentControls});
  final InspectionController controller;
  final Widget? cameraPreview;
  final ThemeMode themeMode;
  final bool demoMode;

  /// Only rendered with explicit demoMode; never production navigation.
  final Widget? developmentControls;
  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pluto Inspector',
      theme: inspectionTheme(Brightness.light),
      darkTheme: inspectionTheme(Brightness.dark),
      themeMode: themeMode,
      home: _InspectionShell(
          controller: controller,
          cameraPreview: cameraPreview,
          demoMode: demoMode,
          developmentControls: developmentControls));
}

enum _InputMode { live, photo }

class _InspectionShell extends StatefulWidget {
  const _InspectionShell(
      {required this.controller,
      this.cameraPreview,
      required this.demoMode,
      this.developmentControls});
  final InspectionController controller;
  final Widget? cameraPreview, developmentControls;
  final bool demoMode;
  @override
  State<_InspectionShell> createState() => _InspectionShellState();
}

class _InspectionShellState extends State<_InspectionShell>
    with WidgetsBindingObserver {
  late InspectionState _state;
  StreamSubscription<InspectionState>? _subscription;
  VerificationResult? _blockedResult;
  _InputMode _mode = _InputMode.live;
  int _destination = 0;
  bool _operation = false, _liveRequested = false, _fixtureSession = false;
  String? _actionError, _selectedMotor;
  BuildContext? _detailContext;

  void _closeDetails() {
    final detail = _detailContext;
    _detailContext = null;
    if (detail != null && detail.mounted) {
      final route = ModalRoute.of(detail);
      if (route != null && route.isActive)
        Navigator.of(detail).removeRoute(route);
    }
  }

  Future<void> _showMotor(String id) async {
    final result = _result;
    if (result == null) return;
    final motors = result.motors.where((m) => m['motor_id'] == id);
    if (motors.isEmpty) return;
    _closeDetails();
    setState(() => _selectedMotor = id);
    BuildContext? openedContext;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : const AnimationStyle(
                duration: Duration(milliseconds: 300),
                reverseDuration: Duration(milliseconds: 180)),
        builder: (detail) {
          openedContext = detail;
          _detailContext = detail;
          return MotorDetail(
              motor: motors.first,
              demo: widget.demoMode || result.evidenceSource == 'fixture');
        });
    if (identical(_detailContext, openedContext)) _detailContext = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  void _connect() {
    _state = widget.controller.current;
    _mode =
        _state.image?.source == 'upload' ? _InputMode.photo : _InputMode.live;
    _fixtureSession = _state.result?.evidenceSource == 'fixture';
    _subscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      if (!identical(state.result, _state.result) ||
          state.phase != InspectionPhase.result ||
          !state.safetyConfirmed) _closeDetails();
      setState(() {
        _state = state;
        if (state.phase == InspectionPhase.result ||
            state.phase == InspectionPhase.error) _liveRequested = false;
        if (state.result?.evidenceSource == 'fixture') _fixtureSession = true;
        if (state.result?.evidenceSource == 'real') _fixtureSession = false;
        if (state.result?.reasons.any((r) => [
                  'ENGINE_UNAVAILABLE',
                  'REFERENCE_NOT_CONFIGURED',
                  'CAMERA_PERMISSION_DENIED',
                  'PERMISSION_DENIED'
                ].contains(r)) ??
            false) _liveRequested = false;
      });
    }, onError: (Object error) {
      _closeDetails();
      if (mounted)
        setState(() {
          _blockedResult = _state.result;
          _actionError =
              'The inspection service stopped responding. Try again or use a photo.';
          _liveRequested = false;
        });
    });
  }

  @override
  void didUpdateWidget(covariant _InspectionShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _closeDetails();
      _subscription?.cancel();
      _blockedResult = null;
      _actionError = null;
      _liveRequested = false;
      _operation = false;
      _connect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _closeDetails();
      if (mounted)
        setState(() {
          _blockedResult = _state.result;
          _selectedMotor = null;
        });
      // Permission dialogs can make the app inactive while the camera is
      // initializing. Only actual backgrounding should cancel acquisition.
      if (_liveRequested && state == AppLifecycleState.paused) {
        _liveRequested = false;
        unawaited(widget.controller.stopLive().catchError((Object _) {}));
      }
    }
  }

  VerificationResult? get _result =>
      identical(_blockedResult, _state.result) && _blockedResult != null
          ? null
          : displayedResult(_state);

  Future<void> _run(Future<void> Function() action,
      {bool live = false, bool stopping = false}) async {
    if (_operation && !stopping) return;
    _closeDetails();
    setState(() {
      _operation = true;
      _actionError = null;
      _blockedResult = _state.result;
      _selectedMotor = null;
      if (live) _liveRequested = true;
      if (stopping) _liveRequested = false;
    });
    try {
      await action();
    } catch (_) {
      if (mounted)
        setState(() {
          _liveRequested = false;
          _actionError =
              'Inspection could not start. Check permissions, or try a different photo.';
        });
    } finally {
      if (mounted) setState(() => _operation = false);
    }
  }

  Future<void> _confirm(bool value) async {
    _closeDetails();
    setState(() {
      _blockedResult = _state.result;
      _actionError = null;
    });
    if (!value && _liveRequested) {
      _liveRequested = false;
      await _run(widget.controller.stopLive, stopping: true);
    }
    try {
      await widget.controller.setSafetyConfirmed(value);
    } catch (_) {
      if (mounted)
        setState(() => _actionError =
            'Safety confirmation could not be saved. Please try again.');
    }
  }

  void _selectMode(_InputMode mode) {
    if (mode == _mode) return;
    _closeDetails();
    if (_liveRequested) {
      unawaited(_run(widget.controller.stopLive, stopping: true));
    }
    setState(() {
      _mode = mode;
      _blockedResult = _state.result;
      _selectedMotor = null;
      _actionError = null;
    });
  }

  void _navigate(int index) {
    if (index != 0 && _liveRequested)
      unawaited(_run(widget.controller.stopLive, stopping: true));
    setState(() => _destination = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final result = _result;
    final demo = widget.demoMode || _fixtureSession;
    if (_destination == 0 &&
        _mode == _InputMode.live &&
        _liveRequested &&
        _state.safetyConfirmed &&
        _state.image == null) {
      return CaptureView(
          preview: widget.cameraPreview,
          busy: _operation || _state.phase == InspectionPhase.processing,
          notice: demo
              ? _DemoNotice(
                  controls: widget.demoMode ? widget.developmentControls : null)
              : null,
          onClose: () => _run(widget.controller.stopLive, stopping: true));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final expanded = constraints.maxWidth >= 900;
      final page = switch (_destination) {
        1 => const GuideView(),
        2 => ProjectView(state: _state),
        _ => _InspectionView(
            state: _state,
            result: result,
            mode: _mode,
            live: _liveRequested,
            busy: _operation || _state.phase == InspectionPhase.processing,
            error: _actionError,
            cameraPreview: widget.cameraPreview,
            selectedMotor: _selectedMotor,
            onSelectMotor: _showMotor,
            onSelectMode: _selectMode,
            onConfirm: _confirm,
            onPrimary: () => _liveRequested
                ? _run(widget.controller.stopLive, stopping: true)
                : _mode == _InputMode.photo
                    ? _run(widget.controller.selectImage)
                    : _run(widget.controller.startLive, live: true)),
      };
      return Scaffold(
        appBar: AppBar(
            titleSpacing: expanded ? 24 : 20,
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              InspectionMark(color: colors.primary, size: 28),
              const SizedBox(width: 11),
              const Flexible(
                  child: Text('Pluto Inspector',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.3))),
            ])),
        bottomNavigationBar: expanded
            ? null
            : NavigationBar(
                selectedIndex: _destination,
                onDestinationSelected: _navigate,
                animationDuration: MediaQuery.disableAnimationsOf(context) ||
                        FocusManager.instance.highlightMode ==
                            FocusHighlightMode.traditional
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.center_focus_weak_outlined),
                        selectedIcon: Icon(Icons.center_focus_strong),
                        label: 'Inspect'),
                    NavigationDestination(
                        icon: Icon(Icons.menu_book_outlined), label: 'Guide'),
                    NavigationDestination(
                        icon: Icon(Icons.fact_check_outlined), label: 'Project')
                  ]),
        body: SafeArea(
            top: false,
            bottom: expanded,
            child: Column(children: [
              if (demo)
                _DemoNotice(
                    controls:
                        widget.demoMode ? widget.developmentControls : null),
              Expanded(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    if (expanded)
                      NavigationRail(
                          selectedIndex: _destination,
                          onDestinationSelected: _navigate,
                          labelType: NavigationRailLabelType.all,
                          minWidth: 96,
                          destinations: const [
                            NavigationRailDestination(
                                icon: Icon(Icons.center_focus_strong_outlined),
                                label: Text('Inspect')),
                            NavigationRailDestination(
                                icon: Icon(Icons.menu_book_outlined),
                                label: Text('Guide')),
                            NavigationRailDestination(
                                icon: Icon(Icons.fact_check_outlined),
                                label: Text('Project'))
                          ]),
                    Expanded(
                        child: Padding(
                            padding: EdgeInsets.only(
                                right: expanded ? 12 : 0,
                                bottom: expanded ? 12 : 0),
                            child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(expanded ? 16 : 0),
                                child: ColoredBox(
                                    color: colors.surfaceContainerLowest,
                                    child: Reveal(
                                        key: ValueKey(_destination),
                                        child: page))))),
                  ])),
            ])),
      );
    });
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice({this.controls});
  final Widget? controls;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
        container: true,
        label: 'Demo. Simulated results, not real verification.',
        child: ColoredBox(
            color: c.cautionSurface,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Icon(Icons.science_outlined,
                            size: 18, color: c.caution),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Text('Demo · Simulated results',
                                style: TextStyle(
                                    color: c.caution,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500)))
                      ]),
                      if (controls != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: controls!),
                    ]))));
  }
}

class _InspectionView extends StatelessWidget {
  const _InspectionView(
      {required this.state,
      required this.result,
      required this.mode,
      required this.live,
      required this.busy,
      required this.error,
      required this.cameraPreview,
      required this.selectedMotor,
      required this.onSelectMotor,
      required this.onSelectMode,
      required this.onConfirm,
      required this.onPrimary});
  final InspectionState state;
  final VerificationResult? result;
  final _InputMode mode;
  final bool live, busy;
  final String? error, selectedMotor;
  final Widget? cameraPreview;
  final ValueChanged<String> onSelectMotor;
  final ValueChanged<_InputMode> onSelectMode;
  final ValueChanged<bool> onConfirm;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final processing =
        error == null && (state.phase == InspectionPhase.processing || busy);
    final title =
        result == null ? 'Inspect your drone' : resultLabel(result!.status);
    final heading =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
          header: true,
          liveRegion: result != null,
          child: Text(title,
              key: const ValueKey('inspection-heading'),
              style: Theme.of(context).textTheme.headlineSmall)),
      if (result == null) ...[
        const SizedBox(height: 12),
        Text('Use the live camera or upload a photo.',
            style: TextStyle(color: c.onSurfaceVariant, height: 1.45)),
      ],
    ]);
    final resultPanel = result != null
        ? _ResultPanel(
            result: result!,
            selectedMotor: selectedMotor,
            onSelect: onSelectMotor)
        : null;
    final inputState =
        (mode == _InputMode.live && state.image?.source == 'upload') ||
                (mode == _InputMode.photo && state.image?.source == 'live')
            ? InspectionState(
                phase: state.phase,
                safetyConfirmed: state.safetyConfirmed,
                message: state.message)
            : state;
    final work =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InputChoices<_InputMode>(choices: const {
        _InputMode.live: 'Live camera',
        _InputMode.photo: 'Upload image'
      }, selected: mode, onChanged: processing && !live ? null : onSelectMode),
      const SizedBox(height: 16),
      if (inputState.image != null)
        EvidenceView(
            state: inputState,
            result: result,
            cameraPreview: mode == _InputMode.live ? cameraPreview : null,
            selectedMotor: selectedMotor,
            onMotorSelected: onSelectMotor),
      if (inputState.image != null) const SizedBox(height: 16),
      Material(
          color: c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ControlFeedback(
              child: CheckboxListTile(
            key: const ValueKey('safety-confirmation'),
            value: state.safetyConfirmed,
            onChanged: (v) => onConfirm(v ?? false),
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: const EdgeInsets.only(left: 16, right: 6),
            title: Text(
                'I confirm the drone is disarmed and every motor is stopped.',
                style: Theme.of(context).textTheme.bodyMedium),
          ))),
      const SizedBox(height: 12),
      _PressButton(
          onPressed: (!state.safetyConfirmed || processing && !live)
              ? null
              : onPrimary,
          icon: live
              ? Icons.stop_rounded
              : mode == _InputMode.photo
                  ? Icons.add_photo_alternate_outlined
                  : Icons.videocam_outlined,
          label: live
              ? 'Stop inspection'
              : processing
                  ? 'Inspecting image…'
                  : mode == _InputMode.photo
                      ? (state.image == null
                          ? 'Choose image'
                          : 'Choose another image')
                      : 'Start live inspection'),
      if (error != null || state.phase == InspectionPhase.error)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
                liveRegion: true,
                child: Text(
                    error ??
                        (['CAMERA_PERMISSION_DENIED', 'PERMISSION_DENIED']
                                .contains(state.message)
                            ? reasonGuidance(state.message)
                            : 'Inspection could not finish. Check permissions, or try a different photo.'),
                    style: TextStyle(color: c.error, height: 1.5)))),
    ]);
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 760;
      // Equal 24dp margins; two columns sum to content width minus one 24dp gutter.
      return SingleChildScrollView(
          key: const PageStorageKey('inspection-scroll'),
          padding: EdgeInsets.all(box.maxWidth < 360 ? 16 : 24),
          child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Reveal(key: ValueKey(title), child: heading),
                        const SizedBox(height: 24),
                        if (wide)
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: work),
                                const SizedBox(width: 24),
                                Expanded(
                                    flex: 5,
                                    child: resultPanel ??
                                        DroneStage(processing: processing))
                              ])
                        else ...[
                          if (resultPanel != null) ...[
                            _ResultSummary(result: result!),
                            const SizedBox(height: 16)
                          ],
                          work,
                          const SizedBox(height: 24),
                          if (resultPanel != null)
                            _MotorFindings(
                                result: result!,
                                selectedMotor: selectedMotor,
                                onSelect: onSelectMotor)
                          else
                            DroneStage(processing: processing)
                        ],
                      ]))));
    });
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});
  final VerificationResult result;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final reason = result.reasons.isEmpty ? null : result.reasons.first;
    final text = reason != null
        ? reasonGuidance(reason)
        : switch (result.status) {
            VerificationStatus.pass =>
              'All required visible checks match. This does not replace the full pre-flight procedure.',
            VerificationStatus.incorrectInstallation =>
              'Review the affected motor below, correct its installation, then inspect again.',
            VerificationStatus.unableToVerify =>
              'A complete installation check was not possible. Retake the image or check the reference.'
          };
    return DecoratedBox(
        decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: inspectionLine),
            borderRadius: BorderRadius.circular(inspectionSurfaceRadius)),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ResultSymbol(status: result.status),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(text,
                      style: TextStyle(
                          color: c.onSurface, height: 1.5, fontSize: 14.5))),
            ])));
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel(
      {required this.result,
      required this.selectedMotor,
      required this.onSelect});
  final VerificationResult result;
  final String? selectedMotor;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ResultSummary(result: result),
        const SizedBox(height: 24),
        _MotorFindings(
            result: result, selectedMotor: selectedMotor, onSelect: onSelect)
      ]);
}

class _MotorFindings extends StatelessWidget {
  const _MotorFindings(
      {required this.result,
      required this.selectedMotor,
      required this.onSelect});
  final VerificationResult result;
  final String? selectedMotor;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final motors = result.motors;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Motor findings', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 7),
      if (motors.isEmpty)
        Text(
            'Motor findings will appear when the propellers can be identified.',
            style: TextStyle(color: c.onSurfaceVariant, height: 1.5)),
      if (motors.isNotEmpty)
        Text(
            '${motors.where((m) => m['finding'] == 'match').length} of ${motors.length} visible findings match',
            style: TextStyle(color: c.onSurfaceVariant, fontSize: 13.5)),
      const SizedBox(height: 12),
      for (final motor in motors)
        if (motorText(motor, 'motor_id') case final String id)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Reveal(
                  key: ValueKey('${result.inputId}-$id'),
                  delayMs: motors.indexOf(motor) * 50,
                  child: Material(
                      color: selectedMotor == id
                          ? c.surfaceContainer
                          : c.surfaceContainerLow,
                      shape: const Border(
                          bottom: BorderSide(color: inspectionLine)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ControlFeedback(
                                child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    onTap: () => onSelect(id),
                                    title: Text(motorLabel(id),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500)),
                                    subtitle: Text(switch (motor['finding']) {
                                      'match' => 'Matches reference',
                                      'mismatch' => 'Installation mismatch',
                                      _ => 'Not verified'
                                    }),
                                    trailing: Icon(
                                        switch (motor['finding']) {
                                          'match' => Icons.check_circle_outline,
                                          'mismatch' => Icons.error_outline,
                                          _ => Icons.help_outline
                                        },
                                        color: switch (motor['finding']) {
                                          'match' => c.good,
                                          'mismatch' => c.bad,
                                          _ => c.caution
                                        }))),
                          ])))),
    ]);
  }
}

/// Pointer-only feedback; keyboard activation remains immediate and unanimated.
class _PressButton extends StatefulWidget {
  const _PressButton(
      {required this.onPressed, required this.icon, required this.label});
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool pressed = false;
  void _press(bool value) {
    if (mounted && pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
      onPointerDown: widget.onPressed == null ? null : (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
          scale: pressed &&
                  widget.onPressed != null &&
                  !MediaQuery.disableAnimationsOf(context)
              ? .97
              : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Duration(milliseconds: pressed ? 100 : 140),
          curve: const Cubic(.23, 1, .32, 1),
          child: FilledButton.icon(
              key: const ValueKey('primary-inspection-action'),
              style: ButtonStyle(
                  foregroundBuilder: (context, states, child) =>
                      child ?? const SizedBox.shrink()),
              onPressed: widget.onPressed,
              icon: Icon(widget.icon, size: 20),
              label: Text(widget.label, textAlign: TextAlign.center))));
}
