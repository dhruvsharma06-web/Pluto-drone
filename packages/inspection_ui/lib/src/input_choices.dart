import 'package:flutter/material.dart';
import 'theme.dart';

/// Separate rounded choices keep their full shape on compact screens.
class InputChoices<T> extends StatelessWidget {
  const InputChoices(
      {super.key,
      required this.choices,
      required this.selected,
      required this.onChanged});
  final Map<T, String> choices;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (final entry in choices.entries) ...[
          if (entry.key != choices.keys.first) const SizedBox(width: 8),
          Expanded(
              child: Semantics(
            selected: entry.key == selected,
            child: TextButton(
              onPressed: onChanged == null ? null : () => onChanged!(entry.key),
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                backgroundColor: WidgetStatePropertyAll(entry.key == selected
                    ? inspectionInk
                    : const Color(0xff18161c)),
                foregroundColor: WidgetStatePropertyAll(
                    entry.key == selected ? inspectionGround : inspectionMuted),
              ),
              child: Text(entry.value, textAlign: TextAlign.center),
            ),
          )),
        ],
      ]);
}
