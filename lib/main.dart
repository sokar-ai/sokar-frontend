import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';
import 'src/app/egress.dart';
import 'src/app/gate.dart';
import 'src/app/host_readiness.dart';
import 'src/app/logs.dart';
import 'src/app/notifications.dart';
import 'src/app/machines.dart';
import 'src/app/narrowing.dart';
import 'src/app/newer_version.dart';
import 'src/app/one_instance.dart';
import 'src/app/where_you_were.dart';
import 'src/app/agent_inventory.dart';
import 'src/app/authentication.dart';
import 'src/app/emergency_stop.dart';
import 'src/app/start_work.dart';
import 'src/app/templates.dart';
import 'src/app/keystore.dart';
import 'src/app/vault.dart';
import 'src/app/widening.dart';
import 'src/app/work_held.dart';
import 'src/app/window.dart';
import 'src/app/operations.dart';
import 'src/app/backups.dart';
import 'src/app/connections.dart';
import 'src/app/project_following.dart';
import 'src/app/project_deletion.dart';
import 'src/app/session.dart';
import 'src/app/settings.dart';
import 'src/app/shell_model.dart';
import 'src/app/sokar_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await sokar());
}

/// The interface, composed once per process and handed back again on every later call.
///
/// An integration test shows it anew for each scenario, because the test framework clears the
/// widget tree between them; composing it again would find its own instance lock and leave.
Future<SokarApp> sokar() => _composed ??= _compose();
Future<SokarApp>? _composed;

Future<SokarApp> _compose() async {
  final settings = Settings(FileSettingsStore());
  await settings.load();

  final shell = ShellModel();
  // Read rather than awaited: a named job that arrives a frame late costs nothing, and the
  // window opening does not wait on a file.
  final templates = Templates(settings);
  unawaited(templates.load());
  final machines = Machines(settings, lookFor: Machine.mock());

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
  // Nothing is opened here: a session exists only once somebody asks for one, and the list is
  // what makes several of them tellable apart.
  final sessions = Sessions();
  final whereYouWere = WhereYouWere(settings, machines, shell);
  final operations = Operations(store: FileOperationsStore());
  await operations.load();
  final notifications = Notifications(DesktopNotifier(), settings)
    ..watchOperations(operations, open: (_) {});
  await notifications.load();
  final app = SokarApp(
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
    templates: templates,
    stopping: EmergencyStop(),
    vault: Vault(keys: PlatformDeviceKeyStore()),
    newerVersion: newerVersion,
    sessions: sessions,
    deleting: ProjectDeletion(),
    readiness: HostReadiness(),
    authentication: Authentication(),
    following: ProjectFollowing(),
    connections: Connections(),
    backups: Backups(),
    narrowing: Narrowing(),
    held: WorkHeld(),
  );

  // Deliberately after the first frame: the window opens and says it is connecting, rather
  // than staying blank until a socket answers or does not. Every machine at once, because a
  // clearance prompt has a deadline and one nobody is connected to expires unseen.
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(machines.load().then((_) async {
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
        open: (_) => shell.goTo(Section.attention),
      );
    }
  })));
  return app;
}
