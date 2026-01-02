import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

enum PriorityStatus {
  prioritized,
  notPrioritized,
  unknown,
}

final FalconManager falconManager = FalconManager.instance;

class FalconManager extends ChangeNotifier {
  FalconManager._internal() {
    unawaited(_initializePriorityStatus());
  }

  static final FalconManager instance = FalconManager._internal();

  final String falconPath = '~/falcon/bin/falcon';
  Process? _falconProcess;
  PriorityStatus _priorityStatus = PriorityStatus.unknown;

  PriorityStatus get priorityStatus => _priorityStatus;

  Future<void> _initializePriorityStatus() async {
    _priorityStatus = await _checkPrioritized();
    notifyListeners();
  }

  Future<void> createFalcon() async {
    if (_falconProcess != null) return;
    try {
      _falconProcess = await Process.start(falconPath, []);
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

  Future<PriorityStatus> _checkPrioritized() async {
    try {
      final result = await Process.run('getcap', [falconPath]);
      return result.stdout.toString().contains('cap_sys_nice')
          ? PriorityStatus.prioritized
          : PriorityStatus.notPrioritized;
    } catch (e) {
      debugPrint('Error checking priority: $e');
      return PriorityStatus.unknown;
    }
  }

  Future<void> prioritizeProcess() async {
    try {
      await Process.run('sudo', ['setcap', 'cap_sys_nice=pe', falconPath]);
      _priorityStatus = PriorityStatus.prioritized;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting priority: $e');
    }
  }
}
