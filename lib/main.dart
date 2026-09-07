import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import 'src/app/logs.dart';
import 'src/app/machines.dart';
import 'src/app/operations.dart';
import 'src/app/settings.dart';
import 'src/app/shell_model.dart';
import 'src/app/sokar_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = Settings(FileSettingsStore());
  await settings.load();

  final machines = Machines(settings);
  runApp(SokarApp(
    machines: machines,
    shell: ShellModel(),
    settings: settings,
    operations: Operations(),
    logs: Logs(),
  ));

  // Deliberately after the first frame: the window opens and says it is connecting, rather
  // than staying blank until a socket answers or does not. Every machine at once, because a
  // clearance prompt has a deadline and one nobody is connected to expires unseen.
  unawaited(machines.load());
}

/// Which backend to open.
///
/// `SOKAR_SOCKET` points this at another socket — a forwarded one for a machine somewhere else,
/// or the mock daemon while the interface is being worked on. One string is the whole
/// difference between a local and a remote Sokar, which is why there is no second transport.
Backend backendFromEnvironment() {
  final socket = Platform.environment['SOKAR_SOCKET'];
  if (socket == null || socket.isEmpty) return Backend.local();
  return Backend(socketPath: socket, label: 'socket $socket');
}
