// import 'package:falcon_gui/settings/falcon_priority_status.dart';
// import 'package:falcon_gui/state/falcon_manager.dart';
// import 'package:falcon_gui/dialogs/dialog_view.dart';
// import 'package:falcon_gui/utils/misc.dart';
// import 'package:flutter/material.dart';

// Future<void> maybeShowPriorityDialog() async {
//   final status = await falconManager.checkProcessPriority();
//   if (status != PriorityStatus.prioritized) {
//     await showDialog<void>(
//       context: globalNavigatorKey.currentContext!,
//       barrierDismissible: false,
//       builder: (context) {
//         return const DialogView(
//           title: 'Warning',
//           content: FalconProcessPriorityStatus(),
//         );
//       },
//     );
//   }
// }
