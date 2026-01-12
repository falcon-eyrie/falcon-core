import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class LogsPanel extends StatelessWidget {
  const LogsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: falconManager,
      builder: (context, _) {
        final logs = falconManager.logs.reversed;

        return Container(
          height: 400,
          color: context.c.surfaceContainer,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Falcon Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemBuilder: (context, index) {
                    final log = logs.elementAtOrNull(index);
                    if (log == null) {
                      return null;
                    }

                    return ListTile(
                      title: Text(
                        '[${log.timestamp.toIso8601String()}] '
                        '[${log.type}] ${log.message}',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
