import 'dart:async';
import 'package:flutter/material.dart';
import 'src/app/gate.dart';
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
    gate: Gate(),
  ));

  // Deliberately after the first frame: the window opens and says it is connecting, rather
  // than staying blank until a socket answers or does not. Every machine at once, because a
  // clearance prompt has a deadline and one nobody is connected to expires unseen.
  unawaited(machines.load());
}
