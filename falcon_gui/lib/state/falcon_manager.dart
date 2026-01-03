import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

final FalconManager falconManager = FalconManager.instance;

class FalconManager extends ChangeNotifier {
  FalconManager._internal();

  static final FalconManager instance = FalconManager._internal();

  String get _falconPath {
    final home = Platform.environment['HOME'] ?? '';
    return '~/falcon/bin/falcon'.replaceFirst('~', home);
  }

  Process? _falconProcess;
  PriorityStatus _priorityStatus = PriorityStatus.unknown;

  PriorityStatus get processPriority => _priorityStatus;

  String get processPriorityCommand =>
      'sudo setcap cap_sys_nice=eip $_falconPath';

  Future<void> createFalcon() async {
    if (_falconProcess != null) return;
    try {
      _falconProcess = await Process.start(_falconPath, []);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating falcon instance: $e');
    }
  }

  Future<void> killFalcon() async {
    if (_falconProcess == null) return;
    try {
      _falconProcess?.kill();
      _falconProcess = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error killing falcon instance: $e');
    }
  }

  Future<PriorityStatus> checkProcessPriority() async {
    try {
      final result = await Process.run('getcap', [_falconPath]);
      _priorityStatus = result.stdout.toString().contains('cap_sys_nice')
          ? PriorityStatus.prioritized
          : PriorityStatus.notPrioritized;
    } catch (e) {
      debugPrint('Error checking priority: $e');
      _priorityStatus = PriorityStatus.unknown;
    }
    notifyListeners();
    return _priorityStatus;
  }
}

/// Falcon process priority status.
enum PriorityStatus {
  prioritized,
  notPrioritized,
  unknown,
}
