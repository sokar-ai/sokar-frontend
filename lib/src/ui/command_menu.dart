import 'package:flutter/material.dart';

import '../app/commands.dart';

/// The commands one thing offers, as one menu.
///
/// One menu rather than a button each: a row with five actions is wider than the pane, and icons
/// say nothing about what they do. What cannot be run stays in the menu, greyed out, carrying the
/// reason — a row whose actions disappear reads as a row with nothing to offer.
class CommandMenu extends StatelessWidget {
  /// Constructor taking what to offer and what to say it is for.
  const CommandMenu({required this.commands, required this.tooltip, super.key});

  /// What this thing can do, runnable or not.
  final List<Command> commands;

  /// What the button says it is for.
  final String tooltip;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Command>(
        tooltip: tooltip,
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (command) => command.run(),
        itemBuilder: (context) => commandMenuEntries(commands),
      );
}

/// The entries of a command menu, so a button and a right-click offer the same list.
List<PopupMenuEntry<Command>> commandMenuEntries(List<Command> commands) =>
    <PopupMenuEntry<Command>>[
      for (final command in commands)
        PopupMenuItem<Command>(
          value: command,
          enabled: command.available,
          child: ListTile(
            dense: true,
            enabled: command.available,
            contentPadding: EdgeInsets.zero,
            title: Text(command.label),
            subtitle: command.available ? null : Text('Unavailable: ${command.unavailable}'),
          ),
        ),
    ];

/// Opens a command menu where the pointer is, and runs what is chosen.
Future<void> showCommandMenu(BuildContext context, Offset at, List<Command> commands) async {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final chosen = await showMenu<Command>(
    context: context,
    position: RelativeRect.fromRect(at & const Size(1, 1), Offset.zero & overlay.size),
    items: commandMenuEntries(commands),
  );
  chosen?.run();
}
