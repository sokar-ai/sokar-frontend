import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fleet_model.dart';
import 'settings.dart';
import 'shell_model.dart';

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
List<Command> commandsFor({
  required FleetModel fleet,
  required ShellModel shell,
  required Settings settings,
  required VoidCallback openFinder,
  required VoidCallback quit,
}) {
  final selectedProject = fleet.selectedProject;
  final selectedTask = fleet.selectedTask;

  return <Command>[
    Command(
      id: 'finder.open',
      label: 'Find a command',
      group: 'Interface',
      shortcut: const SingleActivator(LogicalKeyboardKey.keyK, control: true),
      run: openFinder,
    ),
    Command(
      id: 'focus.projects',
      label: 'Go to projects',
      group: 'Interface',
      shortcut: const SingleActivator(LogicalKeyboardKey.digit1, control: true),
      run: () => shell.focus(Pane.projects),
    ),
    Command(
      id: 'focus.work',
      label: 'Go to work',
      group: 'Interface',
      shortcut: const SingleActivator(LogicalKeyboardKey.digit2, control: true),
      run: () => shell.focus(Pane.work),
      unavailable: selectedProject == null ? 'no project selected' : null,
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
      label: 'Close the detail',
      group: 'Work',
      shortcut: const SingleActivator(LogicalKeyboardKey.escape),
      run: shell.closeDetail,
      unavailable: shell.detailOpen ? null : 'nothing is open over the frame',
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
      id: 'appearance.light',
      label: 'Appearance: light',
      group: 'Interface',
      run: () => settings.setAppearance(ThemeMode.light),
    ),
    Command(
      id: 'appearance.dark',
      label: 'Appearance: dark',
      group: 'Interface',
      run: () => settings.setAppearance(ThemeMode.dark),
    ),
    Command(
      id: 'appearance.system',
      label: 'Appearance: follow the desktop',
      group: 'Interface',
      run: () => settings.setAppearance(ThemeMode.system),
    ),
    Command(
      id: 'app.quit',
      label: 'Quit',
      group: 'Interface',
      shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
      run: quit,
    ),
  ];
}

/// Renders a shortcut the way a keyboard is labelled.
String describeShortcut(SingleActivator shortcut) {
  final parts = <String>[
    if (shortcut.control) 'Ctrl',
    if (shortcut.alt) 'Alt',
    if (shortcut.shift) 'Shift',
    shortcut.trigger.keyLabel,
  ];
  return parts.join('+');
}
