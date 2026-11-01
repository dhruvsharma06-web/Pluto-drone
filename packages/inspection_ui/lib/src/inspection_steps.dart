part of 'inspection_app.dart';

class _InspectionSteps extends StatelessWidget {
  const _InspectionSteps({required this.stage});
  final int stage;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Row(children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0)
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: c.outlineVariant,
                          borderRadius: BorderRadius.circular(1)),
                      child: const SizedBox(height: 1)))),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              i < stage
                  ? Icons.check_circle_rounded
                  : i == stage
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
              size: 16,
              color: i <= stage ? c.primary : c.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(['Prepare', 'Inspect', 'Review'][i],
              style: TextStyle(
                  fontSize: 12,
                  color: i == stage ? c.onSurface : c.onSurfaceVariant,
                  fontWeight: i == stage ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ]
    ]);
  }
}
