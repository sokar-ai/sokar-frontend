import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_model.dart';
import 'notifications.dart';
import 'operations.dart';
import 'settings.dart';
import 'shell_model.dart';
import 'start_work.dart';
import 'widening.dart';

/// One action in the product, by name.
///
/// Everything the interface can do is declared here rather than only wired to a widget, for two
/// reasons that are the same reason: the command finder can then name an action belonging to a
/// screen that is not open, and a keyboard shortcut cannot drift from the menu entry beside it.
@immutable
class Command {
  /// Constructor taking everything the finder and the keyboard need.
  const Command({
    required this.id,
    required this.label,
    required this.group,
    required this.run,
    this.shortcut,
    this.unavailable,
  });

  /// Stable identifier, used to route a keystroke to this command.
  final String id;

  /// What it is called, in the words the person would search for.
  final String label;

  /// What it belongs to, so a long list stays readable.
  final String group;

  /// What it does.
  final VoidCallback run;

  /// The key that runs it, when it has one.
  final SingleActivator? shortcut;

  /// Why it cannot be run now, or null when it can.
  ///
  /// An unavailable command is still listed. Hiding it would make the finder answer "there is
  /// no such action" when the truth is "not yet, and here is what is missing".
  final String? unavailable;

  /// Whether it can be run now.
  bool get available => unavailable == null;
}

/// Every action in the product, in the order the finder should offer them.
///
/// This is the whole list, and it is deliberately shorter than the product will be: about a
/// third of the requirements have no backend method behind them, so their actions do not exist
/// to be named yet. See `doc/Contract-Gaps.md`.
/// What can be done to one piece of work, wherever it is offered.
///
/// One builder for the row's own menu and for the menu bar, so an action cannot be offered in one
/// place and forgotten in the other. Actions that no backend method can perform stay in the list
/// **named and unavailable, with the reason** — an action that simply is not there reads as one
/// nobody thought of, rather than as one the daemon cannot do yet.
List<Command> workCommands({
  required Task? task,
  required FleetModel fleet,
  required void Function(Task task) askToStop,
  required void Function(Task task) askWhichLog,
}) {
  const nothingSelected = 'no work is selected';
  return <Command>[
    Command(
      id: 'work.resume',
      label: 'Start it again',
      group: 'Work',
      run: () => fleet.resumeWork(task!.name),
      unavailable: task == null
          ? nothingSelected
          : task.running
              ? 'it is already running'
              : null,
    ),
    Command(
      id: 'work.stop',
      label: 'Stop it and remove it',
      group: 'Work',
      run: () => askToStop(task!),
      unavailable: task == null ? nothingSelected : null,
    ),
    Command(
      id: 'work.log',
      label: 'Read one of its logs',
      group: 'Work',
      run: () => askWhichLog(task!),
      unavailable: task == null ? nothingSelected : null,
    ),
    Command(
      id: 'work.recreate',
      label: 'Recreate it from scratch, to pick up a newly built environment',
      group: 'Work',
      run: () {},
      // Stop then Start, and Start needs the path to the project file. Nothing maps the project
      // name a task carries to that path. See doc/Contract-Gaps.md.
      unavailable: 'the backend cannot say where a project file is',
    ),
    Command(
      id: 'work.rename',
      label: 'Rename it',
      group: 'Work',
      run: () {},
      unavailable: 'the backend has no method for renaming work',
    ),
  ];
}

List<Command> commandsFor({
  required FleetModel fleet,
  required ShellModel shell,
  required Settings settings,
  required Operations operations,
  required Notifications notifications,
  required VoidCallback openFinder,
  required VoidCallback checkWorkCanStart,
  required void Function(Task task) askToStop,
  required void Function(Task task) askWhichLog,
  required VoidCallback openTheGate,
  required VoidCallback openEgress,
  required VoidCallback widenTheWork,
  required VoidCallback startWork,
  required VoidCallback continueTheWork,
  required VoidCallback quit,
}) {
  final selectedProject = fleet.selectedProject;
  final selectedTask = fleet.selectedTask;
  final latest = operations.latest;

  return <Command>[
    // Grouped for the menu bar, which reads the same list: a group is a menu, and the order here
    // is the order both it and the finder offer.
    Command(
      id: 'app.quit',
      label: 'Quit',
      group: 'Sokar',
      shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
      run: quit,
    ),
    Command(
      id: 'detail.open',
      label: 'Open the selected work',
      group: 'Work',
      shortcut: const SingleActivator(LogicalKeyboardKey.enter, control: true),
      run: shell.openDetail,
      unavailable: selectedTask == null ? 'no work selected' : null,
    ),
    Command(
      id: 'detail.close',
      label: 'Close what is open over the frame',
      group: 'Work',
      shortcut: const SingleActivator(LogicalKeyboardKey.escape),
      run: shell.close,
      unavailable: shell.anythingOpen ? null : 'nothing is open over the frame',
    ),
    ...workCommands(
      task: selectedTask,
      fleet: fleet,
      askToStop: askToStop,
      askWhichLog: askWhichLog,
    ),
    Command(
      id: 'notifications.mute',
      label: selectedProject != null && notifications.mutedFor(selectedProject.name)
          ? 'Tell me about ${selectedProject.name} again'
          : 'Stop telling me about this project',
      group: 'Work',
      run: () => notifications.setMuted(
        selectedProject!.name,
        muted: !notifications.mutedFor(selectedProject.name),
      ),
      unavailable: selectedProject == null ? 'no project selected' : null,
    ),
    Command(
      id: 'egress.open',
      label: 'Change what this project may reach',
      group: 'Work',
      shortcut: const SingleActivator(LogicalKeyboardKey.keyE, control: true),
      run: openEgress,
      unavailable: selectedProject == null
          ? 'no project selected'
          : !selectedProject.canBeActedOn
              ? 'no project file is recorded for ${selectedProject.name}'
              : selectedProject.project.securityClass == 'offline'
                  // An offline project declares no egress at all, and the daemon refuses with
                  // REFUSED_BY_CLASS. Offering something that will be refused is worse than not
                  // offering it and saying why.
                  ? 'an offline project declares no egress at all'
                  : null,
    ),
    Command(
      id: 'work.start',
      label: 'Start work in this project',
      group: 'Work',
      shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
      run: startWork,
      unavailable: StartWork.whyNot(selectedProject?.project),
    ),
    Command(
      id: 'work.continue',
      label: 'Continue this work with a new prompt',
      group: 'Work',
      run: continueTheWork,
      // Three separate reasons, each said rather than collapsed into "not now": still running,
      // not an unattended run, or nothing recorded what it was asked to do.
      unavailable: StartWork.whyNotContinue(selectedTask),
    ),
    Command(
      id: 'work.widen',
      label: 'Let this work reach something new',
      group: 'Work',
      run: widenTheWork,
      // Both refusals the daemon would give are knowable here — NOT_RUNNING and
      // REFUSED_BY_CLASS — so they are said rather than discovered. An action offered and then
      // refused teaches people to distrust the ones that are offered.
      unavailable: Widening.whyNot(selectedTask),
    ),
    Command(
      id: 'gate.open',
      label: 'Review what is waiting at the gate',
      group: 'Work',
      shortcut: const SingleActivator(LogicalKeyboardKey.keyG, control: true),
      run: openTheGate,
      unavailable: selectedProject == null
          ? 'no project selected'
          : selectedProject.canBeActedOn
              ? null
              : 'no project file is recorded for ${selectedProject.name}',
    ),
    Command(
      id: 'work.check',
      // Named for what it does, which is less than it used to claim. `Start(dryRun:)` reports
      // what the project file opens and returns — before the runtime check, before the hooks
      // check, and before anything touches the vault. It is not a rehearsal of starting.
      label: 'Show what this project would open, creating nothing',
      group: 'Work',
      run: checkWorkCanStart,
      unavailable: fleet.reachability != Reachability.connected
          ? 'not connected to a backend'
          : selectedProject == null
              ? 'no project selected'
              : selectedProject.canBeActedOn
                  ? null
                  : 'no project file is recorded for ${selectedProject.name}',
    ),
    Command(
      id: 'operations.show',
      label: 'Show what this session has run',
      group: 'Operations',
      shortcut: const SingleActivator(LogicalKeyboardKey.keyO, control: true),
      run: () => shell.goTo(Section.operations),
    ),
    Command(
      id: 'operations.latest',
      label: 'Watch the last operation',
      group: 'Operations',
      run: () => shell.openOperation(latest!.id),
      unavailable: latest == null ? 'nothing has been run from here yet' : null,
    ),
    Command(
      id: 'fleet.refresh',
      label: 'Refresh from the backend',
      group: 'Backend',
      shortcut: const SingleActivator(LogicalKeyboardKey.f5),
      run: fleet.refresh,
    ),
    Command(
      id: 'fleet.reconnect',
      label: 'Reconnect to the backend',
      group: 'Backend',
      run: fleet.connect,
    ),
    Command(
      id: 'finder.open',
      label: 'Find a command',
      group: 'View',
      shortcut: const SingleActivator(LogicalKeyboardKey.keyK, control: true),
      run: openFinder,
    ),
    Command(
      id: 'section.work',
      label: 'Go to work',
      group: 'View',
      shortcut: const SingleActivator(LogicalKeyboardKey.digit1, control: true),
      run: () => shell.goTo(Section.work),
    ),
    Command(
      id: 'section.operations',
      label: 'Go to this session',
      group: 'View',
      shortcut: const SingleActivator(LogicalKeyboardKey.digit2, control: true),
      run: () => shell.goTo(Section.operations),
    ),
    Command(
      id: 'focus.projects',
      label: 'Go to the project list',
      group: 'View',
      run: () => shell.focus(Pane.projects),
      unavailable:
          shell.section == Section.work ? null : 'the project list is not showing',
    ),
    Command(
      id: 'focus.work',
      label: 'Go to the work list',
      group: 'View',
      run: () => shell.focus(Pane.work),
      unavailable: selectedProject == null ? 'no project selected' : null,
    ),
    Command(
      id: 'appearance.light',
      label: 'Appearance: light',
      group: 'View',
      run: () => settings.setAppearance(ThemeMode.light),
    ),
    Command(
      id: 'appearance.dark',
      label: 'Appearance: dark',
      group: 'View',
      run: () => settings.setAppearance(ThemeMode.dark),
    ),
    Command(
      id: 'appearance.system',
      label: 'Appearance: follow the desktop',
      group: 'View',
      run: () => settings.setAppearance(ThemeMode.system),
    ),
  ];
}

/// Renders a shortcut the way a keyboard is labeled.
String describeShortcut(SingleActivator shortcut) {
  final parts = <String>[
    if (shortcut.control) 'Ctrl',
    if (shortcut.alt) 'Alt',
    if (shortcut.shift) 'Shift',
    shortcut.trigger.keyLabel,
  ];
  return parts.join('+');
}
