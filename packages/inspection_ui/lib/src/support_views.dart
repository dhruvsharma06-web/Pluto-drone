import 'package:flutter/material.dart';
import 'package:inspection_contract/inspection_contract.dart';

import 'presentation.dart';
import 'theme.dart';

class GuideView extends StatelessWidget {
  const GuideView({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'A clear view. A useful check.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Prepare the drone before opening the camera. Visual inspection does not test flight readiness.',
          ),
          const SizedBox(height: 28),
          const _GuideRow(
            Icons.power_settings_new,
            'Disarm the drone',
            'Follow the supplied disarming procedure. Wait for every motor to stop.',
          ),
          const _GuideRow(
            Icons.wb_sunny_outlined,
            'Find even light',
            'Set the drone on a stable surface. Avoid glare and heavy shadows on the blades.',
          ),
          const _GuideRow(
            Icons.center_focus_strong_outlined,
            'Show the complete drone',
            'Keep every propeller in frame. Use the viewing angle required by the supplied reference.',
          ),
          const _GuideRow(
            Icons.photo_camera_outlined,
            'Inspect or upload',
            'Use the live view, or choose a sharp photo. Keep the camera steady.',
          ),
          const SizedBox(height: 24),
          Text(
            'Understand the result',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final status in VerificationStatus.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultLabel(status),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(switch (status) {
                    VerificationStatus.pass =>
                      'The required visible installation checks match the supplied reference. This is not permission to fly.',
                    VerificationStatus.incorrectInstallation =>
                      'An installation mismatch was found. Follow the affected motor’s guidance with the drone disarmed.',
                    VerificationStatus.unableToVerify =>
                      'The evidence or configuration is insufficient. Improve the image or supply the required reference; no approval is given.',
                  }),
                ],
              ),
            ),
        ],
      );
}

class _GuideRow extends StatelessWidget {
  const _GuideRow(this.icon, this.title, this.body);
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: DecoratedBox(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: inspectionLine))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 5),
                      Text(body,
                          style: const TextStyle(color: inspectionMuted)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            )),
      );
}

class ProjectView extends StatelessWidget {
  const ProjectView({super.key, required this.state});
  final InspectionState state;
  @override
  Widget build(BuildContext context) {
    final r = state.result;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Evidence behind the check',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Pluto Inspector compares visible propeller installation with a supplied reference. The vision implementation and validation belong to the project’s core modules.',
        ),
        const SizedBox(height: 28),
        Text(
          'Current inspection',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _EvidenceRow('Reference', r?.referenceVersion ?? 'Not supplied'),
        _EvidenceRow('Vision engine', r?.engineVersion ?? 'Not connected'),
        _EvidenceRow(
          'Evidence',
          r == null
              ? 'No completed inspection'
              : r.evidenceSource == 'fixture'
                  ? 'Simulated UI fixture'
                  : 'Engine output',
        ),
        _EvidenceRow(
          'Inference time',
          r?.elapsedMs == null
              ? 'Not measured'
              : '${r!.elapsedMs!.toStringAsFixed(0)} ms',
        ),
        const SizedBox(height: 28),
        Text(
          'Verification scope',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Propeller type, motor position and visually distinguishable installation orientation. An unclear or unsupported view must receive Unable to Verify.',
        ),
        const SizedBox(height: 28),
        Text('Validation', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        const Text(
          'Dataset and accuracy results are published in the project validation report when available. No detection accuracy is claimed by this interface.',
        ),
        const SizedBox(height: 28),
        Text('Safety boundary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        const Text(
          'Operate only with the drone disarmed and motors stopped. A photo or confirmation cannot establish the hardware’s armed state. The app does not control motors.',
        ),
      ],
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: LayoutBuilder(
          builder: (context, c) => c.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(value),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(label)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(value, textAlign: TextAlign.end)),
                  ],
                ),
        ),
      );
}
