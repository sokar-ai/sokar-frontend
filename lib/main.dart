import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';
import 'src/app/egress.dart';
import 'src/app/gate.dart';
import 'src/app/logs.dart';
import 'src/app/notifications.dart';
import 'src/app/machines.dart';
import 'src/app/operations.dart';
import 'src/app/settings.dart';
import 'src/app/shell_model.dart';
import 'src/app/sokar_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = Settings(FileSettingsStore());
  await settings.load();

  final shell = ShellModel();
  final machines = Machines(settings);
  final operations = Operations();
  final notifications = Notifications(DesktopNotifier(), settings)
    ..watchOperations(operations, open: (_) {});
  await notifications.load();
  runApp(SokarApp(
    machines: machines,
    shell: shell,
    settings: settings,
    operations: operations,
    logs: Logs(),
    gate: Gate(),
    notifications: notifications,
    egress: Egress(),
  ));

  // Deliberately after the first frame: the window opens and says it is connecting, rather
  // than staying blank until a socket answers or does not. Every machine at once, because a
  // clearance prompt has a deadline and one nobody is connected to expires unseen.
  unawaited(machines.load().then((_) {
    // Clearance is per machine: a question knows its task, and only that machine's fleet can say
    // which project the task belongs to.
    for (final machine in machines.all) {
      final fleet = machines.of(machine);
      notifications.watchClearance(
        fleet.clearance,
        projectOf: (task) => fleet.tasks
            .firstWhere((each) => each.name == task,
                orElse: () => Task.from(const <String, dynamic>{}))
            .project,
        open: (_) => shell.goTo(Section.clearance),
      );
    }
  }));
}
