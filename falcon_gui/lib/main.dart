import 'dart:async';

import 'package:falcon_gui/graph_editor/graph_editor.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.dark);
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

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const DesktopApp());
}

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
          themeMode: _themeNotifier.value,
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
                  AnimatedBuilder(
                    animation: _themeNotifier,
                    builder: (context, _) {
                      return IconButton(
                        icon: Icon(
                          _themeNotifier.value == ThemeMode.dark
                              ? Icons.sunny
                              : Icons.dark_mode,
                          size: 18,
                        ),
                        onPressed: () => _themeNotifier.value =
                            _themeNotifier.value == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                      );
                    },
                  ),
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
