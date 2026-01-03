import 'dart:async';

import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FalconProcessPriorityStatus extends StatefulWidget {
  const FalconProcessPriorityStatus({super.key});

  @override
  State<FalconProcessPriorityStatus> createState() =>
      _FalconProcessPriorityStatusState();
}

class _FalconProcessPriorityStatusState
    extends State<FalconProcessPriorityStatus> {
  late Timer _priorityCheckTimer;
  bool _justCopied = false;

  @override
  void initState() {
    super.initState();
    _priorityCheckTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => falconManager.checkProcessPriority(),
    );
  }

  @override
  void dispose() {
    _priorityCheckTimer.cancel();
    super.dispose();
  }

  Future<void> _copyCommand(String command) async {
    await Clipboard.setData(ClipboardData(text: command));
    setState(() => _justCopied = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 700,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Falcon Priority',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: falconManager,
                builder: (context, _) {
                  final isPrioritized =
                      falconManager.processPriority ==
                      PriorityStatus.prioritized;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isPrioritized) ...[
                        Text(
                          _processPriorityExplanation,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CommandBox(
                                command: falconManager.processPriorityCommand,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _copyCommand(
                                falconManager.processPriorityCommand,
                              ),
                              icon: const Icon(Icons.content_copy, size: 18),
                              label: Text(_justCopied ? 'Copied!' : 'Copy'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(25),
                            border: Border.all(
                              color: Colors.green.withAlpha(77),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Falcon is prioritized and running optimally.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      _StatusIndicator(isPrioritized: isPrioritized),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.isPrioritized});
  final bool isPrioritized;

  @override
  Widget build(BuildContext context) {
    final (label, color) = isPrioritized
        ? ('Prioritized', Colors.green)
        : ('Not Prioritized', Colors.orange);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandBox extends StatelessWidget {
  const _CommandBox({required this.command});
  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceDim,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        command,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

const _processPriorityExplanation =
    'Modern operating systems run many processes concurrently. '
    'Assigning Falcon high CPU priority ensures it receives '
    'processing resources first, minimizing interference from '
    'other programs and supporting reliable real-time operation.\n\n'
    'Run the command below in a terminal to grant Falcon permission to '
    'prioritize itself. This only needs to be done once, as the setting '
    'will persist for all future runs.';
