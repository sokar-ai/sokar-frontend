import 'package:flutter/material.dart';

import '../app/commands.dart';

/// The commands, visible.
///
/// A third reader over the one list in `commands.dart`, beside the keyboard and the finder. That
/// is the point of the list: an action added once turns up as a shortcut, a finder entry and a
/// menu entry together, and a menu can never come to say something different from the key beside
/// it.
///
/// It exists because a finder alone leaves every action reachable only by somebody who already
/// suspects it is there. A pointer is optional everywhere and must therefore be *sufficient*
/// everywhere.
class CommandMenuBar extends StatelessWidget {
  /// Constructor taking everything the product can do.
  const CommandMenuBar({required this.commands, super.key});

  /// Every action, in the order the finder offers them.
  final List<Command> commands;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Command>>{};
    for (final command in commands) {
      grouped.putIfAbsent(command.group, () => <Command>[]).add(command);
    }

    return MenuBar(
      style: const MenuStyle(
        elevation: WidgetStatePropertyAll<double>(0),
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      children: <Widget>[
        for (final group in grouped.keys)
          SubmenuButton(
            menuChildren: <Widget>[
              for (final command in grouped[group]!)
                MenuItemButton(
                  // Kept and greyed out rather than dropped. An entry that vanishes reads as "no
                  // such action"; one that stays with its reason reads as "not now, because".
                  onPressed: command.available ? command.run : null,
                  shortcut: command.shortcut,
                  child: Tooltip(
                    message: command.unavailable == null
                        ? ''
                        : 'Unavailable: ${command.unavailable}',
                    child: Text(command.label),
                  ),
                ),
            ],
            child: Text(group),
          ),
      ],
    );
  }
}
