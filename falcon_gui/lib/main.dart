import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setBackgroundColor(Colors.transparent);

  const windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    size: Size(800, 600),
    center: true,
    skipTaskbar: false,
    title: 'Falcon GUI',
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const DesktopApp());
}

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  bool isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_syncState());
  }

  Future<void> _syncState() async {
    isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  @override
  void onWindowMaximize() {
    setState(() => isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => isMaximized = false);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (_) {
              unawaited(windowManager.startDragging());
            },
            child: Container(
              height: 40,
              width: double.infinity,
              color: Colors.grey.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Text(
                    'Falcon GUI',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: windowManager.minimize,
                  ),
                  IconButton(
                    icon: Icon(
                      isMaximized ? Icons.filter_none : Icons.crop_square,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () async {
                      if (isMaximized) {
                        await windowManager.unmaximize();
                      } else {
                        await windowManager.maximize();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: windowManager.close,
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Hello'),
            ),
          ),
        ],
      ),
    );
  }
}
