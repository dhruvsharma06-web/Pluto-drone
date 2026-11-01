import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspection_contract/inspection_contract.dart';
import 'evidence_view.dart';
import 'presentation.dart';
import 'support_views.dart';
import 'theme.dart';
import 'inspection_mark.dart';
import 'motor_finding.dart';

/// Drop-in presentation. The caller owns and disposes [controller].
class InspectionApp extends StatelessWidget {
  const InspectionApp(
      {super.key,
      required this.controller,
      this.cameraPreview,
      this.themeMode = ThemeMode.dark,
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
      title: 'Pluto Inspection',
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
      setState(() {
        _state = state;
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
      if (mounted)
        setState(() {
          _blockedResult = _state.result;
          _selectedMotor = null;
        });
      if (_liveRequested) {
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

  void _showMotor(String id) {
    final result = _result;
    if (result == null) return;
    final matches = result.motors.where((m) => m['motor_id'] == id);
    if (matches.length != 1) return;
    setState(() => _selectedMotor = id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
          maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height * .85),
      builder: (_) => MotorFindingSheet(
          motor: matches.single, result: result, controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final result = _result;
    final demo = widget.demoMode || _fixtureSession;
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
            onSelectMotor: (id) => setState(() => _selectedMotor = id),
            onMotorBoxSelected: _showMotor,
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
              InspectionMark(color: colors.secondary, size: 28),
              const SizedBox(width: 11),
              const Flexible(
                  child: Text('Pluto Inspection',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
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
                                child: DecoratedBox(
                                    decoration: inspectionBackdrop(colors),
                                    child: page)))),
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
                                    fontSize: 18,
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
      required this.onMotorBoxSelected,
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
  final ValueChanged<String> onMotorBoxSelected;
  final ValueChanged<_InputMode> onSelectMode;
  final ValueChanged<bool> onConfirm;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final processing =
        error == null && (state.phase == InspectionPhase.processing || busy);
    final title =
        result == null ? 'Inspect propellers' : resultLabel(result!.status);
    final heading =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
          header: true,
          liveRegion: result != null,
          child: Text(title,
              key: const ValueKey('inspection-heading'),
              style: Theme.of(context).textTheme.headlineSmall)),
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
      SegmentedButton<_InputMode>(
          segments: const [
            ButtonSegment(value: _InputMode.live, label: Text('Live camera')),
            ButtonSegment(value: _InputMode.photo, label: Text('Upload image'))
          ],
          selected: {
            mode
          },
          showSelectedIcon: false,
          onSelectionChanged:
              processing && !live ? null : (s) => onSelectMode(s.first)),
      const SizedBox(height: 16),
      EvidenceView(
          state: inputState,
          result: result,
          cameraPreview: mode == _InputMode.live ? cameraPreview : null,
          selectedMotor: selectedMotor,
          onMotorSelected: onMotorBoxSelected),
      const SizedBox(height: 16),
      Material(
          color: c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: CheckboxListTile(
            key: const ValueKey('safety-confirmation'),
            value: state.safetyConfirmed,
            onChanged: (v) => onConfirm(v ?? false),
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: const EdgeInsets.only(left: 16, right: 6),
            title: Text('I confirm: disarmed, motors stopped.',
                style: Theme.of(context).textTheme.titleSmall),
          )),
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
      if (processing)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: [
              if (MediaQuery.disableAnimationsOf(context))
                const Icon(Icons.hourglass_top_outlined, size: 18)
              else
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Inspecting visible propellers…',
                      style: TextStyle(fontSize: 18))),
            ])),
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
                    style: TextStyle(color: c.bad, height: 1.5)))),
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
                        heading,
                        const SizedBox(height: 20),
                        if (wide && resultPanel != null)
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: work),
                                const SizedBox(width: 24),
                                Expanded(flex: 5, child: resultPanel)
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
    final (ink, bg, icon) = switch (result.status) {
      VerificationStatus.pass => (
          c.good,
          c.goodSurface,
          Icons.check_circle_outline
        ),
      VerificationStatus.incorrectInstallation => (
          c.bad,
          c.badSurface,
          Icons.error_outline
        ),
      VerificationStatus.unableToVerify => (
          c.caution,
          c.cautionSurface,
          Icons.visibility_off_outlined
        )
    };
    final reason = result.reasons.isEmpty ? null : result.reasons.first;
    final text = reason != null
        ? reasonGuidance(reason)
        : switch (result.status) {
            VerificationStatus.pass =>
              'Visible checks match. Complete the full pre-flight procedure.',
            VerificationStatus.incorrectInstallation =>
              'Correct the indicated motor, then inspect again.',
            VerificationStatus.unableToVerify =>
              'Retake a clearer image or check the supplied reference.'
          };
    return DecoratedBox(
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TweenAnimationBuilder<double>(
                  key: ValueKey(result.status),
                  tween: Tween(begin: .92, end: 1),
                  duration: Duration(
                      milliseconds:
                          MediaQuery.disableAnimationsOf(context) ? 0 : 180),
                  curve: const Cubic(.23, 1, .32, 1),
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Icon(icon, color: ink, size: 26)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(text,
                      style: TextStyle(color: ink, height: 1.5, fontSize: 18))),
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
            style: TextStyle(color: c.onSurfaceVariant, fontSize: 18)),
      const SizedBox(height: 12),
      for (final motor in motors)
        if (motorText(motor, 'motor_id') case final String id)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                  color: selectedMotor == id
                      ? c.surfaceContainer
                      : c.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            onTap: () =>
                                onSelect(selectedMotor == id ? '' : id),
                            title: Text(id,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w500)),
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
                                })),
                        if (selectedMotor == id ||
                            motor['finding'] == 'mismatch')
                          Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: MotorFindingDetails(motor: motor)),
                      ]))),
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
          scale: pressed && widget.onPressed != null ? .98 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Duration(milliseconds: pressed ? 100 : 140),
          curve: const Cubic(.23, 1, .32, 1),
          child: FilledButton.icon(
              key: const ValueKey('primary-inspection-action'),
              onPressed: widget.onPressed,
              icon: Icon(widget.icon, size: 20),
              label: Text(widget.label, textAlign: TextAlign.center))));
}
