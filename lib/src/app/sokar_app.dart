import 'package:flutter/material.dart';

import '../ui/shell.dart';
import 'logs.dart';
import 'machines.dart';
import 'operations.dart';
import 'settings.dart';
import 'shell_model.dart';

/// The application: one window, one frame, one backend at a time.
class SokarApp extends StatelessWidget {
  /// Constructor taking the state the whole interface is drawn from.
  const SokarApp({
    required this.machines,
    required this.shell,
    required this.settings,
    required this.operations,
    required this.logs,
    super.key,
  });

  /// Every machine being watched.
  final Machines machines;

  /// What is open and where the keyboard is.
  final ShellModel shell;

  /// How the interface looks.
  final Settings settings;

  /// What this session has run.
  final Operations operations;

  /// What this session is reading.
  final Logs logs;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        // Only the appearance rebuilds the application; everything else rebuilds the frame.
        // A status line changing must not rebuild a theme.
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'Sokar',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: Colors.teal),
          darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
          themeMode: settings.appearance,
          home: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[machines, shell, operations, logs]),
            builder: (context, _) => Shell(
              machines: machines,
              shell: shell,
              settings: settings,
              operations: operations,
              logs: logs,
            ),
          ),
        ),
      );
}
