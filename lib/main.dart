import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';
import 'src/app/egress.dart';
import 'src/app/gate.dart';
import 'src/app/logs.dart';
import 'src/app/notifications.dart';
import 'src/app/machines.dart';
import 'src/app/newer_version.dart';
import 'src/app/one_instance.dart';
import 'src/app/where_you_were.dart';
import 'src/app/agent_inventory.dart';
import 'src/app/start_work.dart';
import 'src/app/widening.dart';
import 'src/app/window.dart';
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

  // Two interfaces watching the same machines raise every question twice and answer it from
  // whichever window somebody happened to see. A second launch asks the first to come forward and
  // then leaves, saying so — a launch that simply vanished would read as one that crashed.
  final only = await OneInstance.take(comeForward: Window.comeForward);
  if (!only.inCharge) {
    stderr.writeln('Sokar is already open, and has been brought to the front. '
        'One interface watches each machine: a second would raise every decision twice.');
    exit(0);
  }

  final newerVersion = NewerVersion()..watch();
  final whereYouWere = WhereYouWere(settings, machines, shell);
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
    widening: Widening(),
    starting: StartWork(),
    inventory: AgentInventory(),
    newerVersion: newerVersion,
  ));

  // Deliberately after the first frame: the window opens and says it is connecting, rather
  // than staying blank until a socket answers or does not. Every machine at once, because a
  // clearance prompt has a deadline and one nobody is connected to expires unseen.
  unawaited(machines.load().then((_) async {
    await whereYouWere.restore();
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
