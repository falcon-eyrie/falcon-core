import 'dart:async';
import 'dart:io';

import 'package:falcon_gui/graph_editor/graph_editor.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/settings/theme_mode_setting.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/priority_dialog.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setBackgroundColor(Colors.transparent);

  const windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.normal,
    size: Size(1280, 720),
    center: true,
    skipTaskbar: false,
    title: 'Falcon GUI',
    windowButtonVisibility: true,
  );
  await windowManager.setPreventClose(true);

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    // await windowManager.focus();
  });

  await loadThemeModeFromSharedPreferences();
  unawaited(_tempLoadGraph());

  Future.delayed(const Duration(milliseconds: 1000), maybeShowPriorityDialog);
  runApp(const DesktopApp());
}

Future<void> _tempLoadGraph() async {
  try {
    final p = File('/home/device/falcon/resources/graphs/current.yaml');
    final yaml = await p.readAsString();
    graphManager.loadGraph(FalconGraphSerializerX.fromYaml(yaml));
  } catch (_) {}
}

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const RootPage(),
          navigatorKey: globalNavigatorKey,
          themeMode: themeNotifier.value,
          theme: FalconTheme(Theme.of(context).textTheme).light(),
          darkTheme: FalconTheme(Theme.of(context).textTheme).dark(),
        );
      },
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    debugPrint('Window close requested, calling killFalcon()...');
    await falconManager.killFalcon();
    debugPrint('killFalcon() completed, destroying window...');
    unawaited(windowManager.destroy());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GraphEditor(),
    );
  }
}
