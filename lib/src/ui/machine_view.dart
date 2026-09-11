import 'package:flutter/material.dart';

import '../app/commands.dart';
import '../app/fleet_model.dart';
import '../app/machines.dart';
import '../app/templates.dart';
import '../app/tunnel.dart';
import 'command_menu.dart';
import 'emergency_stop_view.dart';
import 'machine_switcher.dart';
import 'tokens.dart';

/// Marks where the finder went: an outline around it, and a key the way there can be followed by.
class Highlight extends StatelessWidget {
  /// Constructor taking whether it is marked and what is.
  const Highlight({required this.active, required this.child, super.key});

  /// Whether the finder went here.
  final bool active;

  /// What is marked.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return KeyedSubtree(
      key: const Key('highlighted'),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.tertiary,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(Radii.medium),
        ),
        child: child,
      ),
    );
  }
}

/// The top of a machine: which one it is, how it is reached, its emergency stop and its menu.
///
/// The stop sits here rather than in the menu: somebody reaching for it has just realised
/// something is wrong, and a person in that minute does not go looking through menus.
class MachineTitle extends StatelessWidget {
  /// Constructor taking the machine and what it can be told to do.
  const MachineTitle({
    required this.machine,
    required this.fleet,
    required this.kind,
    required this.onStop,
    required this.menu,
    this.tunnel,
    this.highlight,
    this.onShown,
    super.key,
  });

  /// The machine.
  final Machine machine;

  /// Its model.
  final FleetModel fleet;

  /// What kind of way in it is, and which node it shares, after its name.
  final String kind;

  /// Asks before stopping everything on it.
  final VoidCallback onStop;

  /// What the machine can be told to do.
  final List<Command> menu;

  /// The forward this interface raised for it, or null.
  final Tunnel? tunnel;

  /// The command the finder went to.
  final String? highlight;

  /// Called once a menu opened on [highlight].
  final VoidCallback? onShown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = fleet.info;
    final where = <String>[
      if (machine.needsATunnel) machine.host else machine.socketPath,
      if (info != null) '${info.product} ${info.version}',
    ].join('  ·  ');
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Space.normal,
        Space.small,
        Space.small,
        Space.small,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: <Widget>[
          ReachIcon(name: machine.name, fleet: fleet, tunnel: tunnel),
          const SizedBox(width: Space.small),
          Flexible(
            child: Text(
              machine.name,
              key: const Key('machine-title'),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: Space.normal),
          Expanded(
            child: Text(
              '$where$kind',
              key: const Key('machine-kind'),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Highlight(
            active: highlight == 'machine.panic',
            child: EmergencyStopButton(onPressed: onStop),
          ),
          CommandMenu(
            key: const Key('machine-menu'),
            commands: menu,
            tooltip: 'What ${machine.name} can be told to do',
            highlight: highlight,
            onShown: onShown,
          ),
        ],
      ),
    );
  }
}

/// Describes a new project on this machine.
class NewProjectCard extends StatelessWidget {
  /// Constructor taking what it opens.
  const NewProjectCard({
    required this.onPressed,
    this.highlighted = false,
    super.key,
  });

  /// Opens the description of a new project.
  final VoidCallback onPressed;

  /// Whether the finder went here.
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Highlight(
    active: highlighted,
    child: SizedBox(
      width: 180,
      height: 64,
      child: OutlinedButton.icon(
        key: const Key('new-project'),
        autofocus: highlighted,
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: Sizes.rowIcon),
        label: const Text('New project…'),
      ),
    ),
  );
}

/// Starts work: in the project the work is narrowed to, or in one chosen here.
class StartTile extends StatelessWidget {
  /// Constructor taking where work can start and what starting does.
  const StartTile({
    required this.projects,
    required this.onStart,
    this.inProject,
    this.unavailable,
    this.highlighted = false,
    super.key,
  });

  /// The projects work can be started in.
  final List<String> projects;

  /// The project the work is narrowed to, or null.
  final String? inProject;

  /// Starts work in a project.
  final void Function(String project) onStart;

  /// Why nothing can start in [inProject], or null.
  final String? unavailable;

  /// Whether the finder went here.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final project = inProject;
    final label = project == null ? 'Start work…' : 'Start work in $project…';
    final Widget button = project != null
        ? OutlinedButton.icon(
            key: const Key('start-work'),
            autofocus: highlighted,
            onPressed: unavailable == null ? () => onStart(project) : null,
            icon: const Icon(Icons.play_arrow_outlined, size: Sizes.rowIcon),
            label: Text(label, overflow: TextOverflow.ellipsis),
          )
        : PopupMenuButton<String>(
            key: const Key('start-work'),
            tooltip: 'Choose the project to start work in',
            enabled: projects.isNotEmpty,
            onSelected: onStart,
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              for (final each in projects)
                PopupMenuItem<String>(
                  value: each,
                  key: ValueKey<String>('start in $each'),
                  child: Text(each),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(Space.small),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.play_arrow_outlined, size: Sizes.rowIcon),
                  const SizedBox(width: Space.small),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
    return Highlight(
      active: highlighted,
      child: SizedBox(
        width: 220,
        height: 64,
        child: Tooltip(
          message: unavailable ?? '',
          child: Center(child: button),
        ),
      ),
    );
  }
}

/// A job somebody named, started again from its own tile.
class TemplateTile extends StatelessWidget {
  /// Constructor taking the job and what starting it does.
  const TemplateTile({
    required this.job,
    required this.onPressed,
    this.unavailable,
    this.highlighted = false,
    super.key,
  });

  /// The job.
  final Template job;

  /// Starts it.
  final VoidCallback onPressed;

  /// Why it cannot run now, or null.
  final String? unavailable;

  /// Whether the finder went here.
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Highlight(
    active: highlighted,
    child: SizedBox(
      width: 220,
      height: 48,
      child: Tooltip(
        message: unavailable ?? 'Run ${job.name} in ${job.project}',
        child: OutlinedButton.icon(
          key: ValueKey<String>('job ${job.project}/${job.name}'),
          autofocus: highlighted,
          onPressed: unavailable == null ? onPressed : null,
          icon: const Icon(Icons.replay, size: Sizes.rowIcon),
          label: Text('Run ${job.name}', overflow: TextOverflow.ellipsis),
        ),
      ),
    ),
  );
}
