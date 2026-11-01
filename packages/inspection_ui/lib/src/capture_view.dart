import 'package:flutter/material.dart';

import 'theme.dart';

/// A focused native camera surface; the runtime injects preview and shutter.
class CaptureView extends StatelessWidget {
  const CaptureView(
      {super.key,
      required this.preview,
      required this.busy,
      required this.onClose,
      this.notice});
  final Widget? preview;
  final Widget? notice;
  final bool busy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onClose();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
                tooltip: 'Close camera',
                onPressed: onClose,
                icon: const Icon(Icons.close)),
            title: const Text('Capture photo'),
          ),
          body: SafeArea(
              top: false,
              child: Column(children: [
                if (notice != null) notice!,
                // With the runtime's 72dp shutter area, the viewfinder occupies about
                // 68% of a portrait phone. Flex also accommodates short/large-text views.
                Flexible(
                    child: SizedBox(
                  key: const ValueKey('capture-stage'),
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height * .78,
                  child: ColoredBox(
                      color: cameraGround,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (preview != null) preview!,
                          if (busy)
                            Positioned(
                                top: 16,
                                left: 16,
                                right: 16,
                                child: Semantics(
                                    liveRegion: true,
                                    child: Center(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: cameraGround,
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text('Preparing photo...',
                                                style: TextStyle(
                                                    color: Colors.white))),
                                      ),
                                    ))),
                        ],
                      )),
                )),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Text(
                        'Keep the whole drone in view.\nDrone disarmed. Motors stopped.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium)),
              ])),
        ),
      );
}
