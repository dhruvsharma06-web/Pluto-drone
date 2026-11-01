import 'package:flutter/material.dart';
import 'theme.dart';

/// Adds pointer feedback and a keyboard focus outline without replacing native actions.
class ControlFeedback extends StatefulWidget {
  const ControlFeedback({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<ControlFeedback> createState() => _ControlFeedbackState();
}

class _ControlFeedbackState extends State<ControlFeedback> {
  bool _pressed = false, _focused = false;
  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        onFocusChange: (value) => setState(() => _focused = value),
        child: Listener(
          onPointerDown: widget.enabled ? (_) => _press(true) : null,
          onPointerUp: (_) => _press(false),
          onPointerCancel: (_) => _press(false),
          child: AnimatedScale(
            scale: _pressed &&
                    widget.enabled &&
                    !MediaQuery.disableAnimationsOf(context)
                ? .97
                : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _focused ? inspectionAccent : Colors.transparent,
                        width: 2)),
                child: widget.child),
          ),
        ),
      );
}
