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
    titleBarStyle: TitleBarStyle.hidden,
    size: Size(1280, 720),
    center: true,
    skipTaskbar: false,
    title: 'Falcon GUI',
    windowButtonVisibility: false,
  );
  await windowManager.setPreventClose(true);

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // await windowManager.maximize();
    await windowManager.show();
    // await windowManager.focus();
  });

  graphManager.addListener(() {
    unawaited(falconManager.saveYaml(graphManager.graphAsYaml));
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
          home: const HomePage(),
          navigatorKey: globalNavigatorKey,
          themeMode: themeNotifier.value,
          theme: FalconTheme(Theme.of(context).textTheme).light(),
          darkTheme: FalconTheme(Theme.of(context).textTheme).dark(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  bool _isMaximized = false;
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_syncState());
  }

  Future<void> _syncState() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    await falconManager.killFalcon();

    await windowManager.destroy();
  }

  Future<void> _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: _toggleMaximize,
            onPanStart: (_) {
              unawaited(windowManager.startDragging());
            },
            child: Container(
              height: 40,
              width: double.infinity,
              color: context.c.surfaceContainerLowest,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Text(
                    'Falcon',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.remove,
                      size: 18,
                    ),
                    onPressed: windowManager.minimize,
                  ),
                  IconButton(
                    icon: Icon(
                      _isMaximized ? Icons.filter_none : Icons.crop_square,
                      size: 18,
                    ),
                    onPressed: _toggleMaximize,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                    ),
                    onPressed: windowManager.close,
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: GraphEditor()),
        ],
      ),
    );
  }
}
