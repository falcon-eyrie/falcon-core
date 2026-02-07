import 'dart:async';

import 'package:falcon_gui/dialogs/on_close_gui_dialog.dart';
import 'package:falcon_gui/graph_editor/graph_editor.dart';
import 'package:falcon_gui/settings/theme_mode_setting.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/local_config.dart';
import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  await initLoggerIsolate();
  await runZonedGuarded(
    _entrypoint,
    (error, stackTrace) => logError('Uncaught error: $error\n$stackTrace'),
  );
}

Future<void> _entrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setBackgroundColor(Colors.transparent);

  const windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.normal,
    size: Size(1280, 720),
    center: true,
    skipTaskbar: false,
    title: 'Falcon',
    windowButtonVisibility: true,
  );
  await windowManager.setPreventClose(true);

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    // await windowManager.focus();
  });

  await LocalConfigManager.loadConfig();

  await setThemeModeFromConfig();
  _listenForLoadedGraphFile();

  unawaited(falconManager.initialize());
  // Future.delayed(const Duration(milliseconds: 1000),
  // maybeShowPriorityDialog);

  runApp(const DesktopApp());
}

void _listenForLoadedGraphFile() {
  falconManager.graphLoadedNotifier.addListener(() {
    final graph = falconManager.graphLoadedNotifier.value;
    if (graph != null) {
      graphManager.loadGraph(graph);
    }

    if (falconManager.currentGraphFileName != null) {
      unawaited(
        windowManager.setTitle(
          'Falcon - ${falconManager.currentGraphFileName}',
        ),
      );
    } else {
      unawaited(windowManager.setTitle('Falcon'));
    }
  });
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
    logInfo('Window close requested, calling on close dialog...');
    await showOnCloseGUIDialog();
    logInfo('On close dialog completed, destroying window...');
    unawaited(windowManager.destroy());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GraphEditor(),
    );
  }
}
