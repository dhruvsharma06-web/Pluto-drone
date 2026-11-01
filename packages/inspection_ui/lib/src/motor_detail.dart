import 'package:flutter/material.dart';
import 'presentation.dart';
import 'theme.dart';

class MotorDetail extends StatelessWidget {
  const MotorDetail({super.key, required this.motor, required this.demo});
  final Map<String, Object?> motor;
  final bool demo;
  @override
  Widget build(BuildContext context) => SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text(motorName(motor, 'Motor guidance'),
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
                tooltip: 'Close guidance',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
          ]),
          if (demo)
            const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Demo · Simulated results',
                    style: TextStyle(color: inspectionMuted))),
          for (final row in [
            ('Where', motorName(motor, 'Position not supplied')),
            (
              'Why',
              'Observed: ${motorText(motor, 'observed_type') ?? 'Unknown'}. '
                  'Expected: ${motorText(motor, 'expected_type') ?? 'Reference needed'}.'
            ),
            ('Correction', correctionGuidance(motor)),
          ]) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(row.$1, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(row.$2),
            const SizedBox(height: 24),
          ],
        ]),
      ));
}
