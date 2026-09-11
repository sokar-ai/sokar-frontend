import 'package:flutter/material.dart';

import '../app/commands.dart';
import '../app/fleet_model.dart';
import '../app/machines.dart';
import '../app/shell_model.dart';
import 'command_menu.dart';
import 'machine_switcher.dart';
import 'machine_view.dart';
import 'tokens.dart';

/// The left of the window: what needs a person, then every machine with its projects under it.
///
/// A machine opens like an accordion. Under it come the work running there, a way to describe a
/// new project, and every project. The stop for every machine stays at the foot.
class MachineTree extends StatelessWidget {
  /// Constructor taking what the tree shows and what choosing an entry does.
  const MachineTree({
    required this.machines,
    required this.shell,
    required this.needing,
    required this.muted,
    required this.width,
    required this.onNeedsYou,
    required this.onMachine,
    required this.onToggle,
    required this.onRunning,
    required this.onNewProject,
    required this.onProject,
    required this.onStopEverywhere,
    super.key,
  });

  /// Every machine watched.
  final Machines machines;

  /// Where the window is.
  final ShellModel shell;

  /// How many things need somebody, across every machine.
  final int needing;

  /// Projects nothing is notified about.
  final Set<String> muted;

  /// How wide the tree is.
  final double width;

  /// Goes to what needs a person.
  final VoidCallback onNeedsYou;

  /// Opens a machine and shows what runs there.
  final void Function(Machine machine) onMachine;

  /// Opens or closes a machine's projects under it.
  final void Function(Machine machine) onToggle;

  /// Shows every running piece of work on a machine.
  final void Function(Machine machine) onRunning;

  /// Describes a new project on a machine.
  final void Function(Machine machine) onNewProject;

  /// Shows one project of a machine.
  final void Function(Machine machine, String project) onProject;

  /// Asks before stopping everything on every machine.
  final VoidCallback onStopEverywhere;

  @override
  Widget build(BuildContext context) {
    final current = machines.current;
    final onMachineSide = shell.section == Section.machine;
    final creating = shell.opened is ProjectCreationOpened;
    return SizedBox(
      width: width,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              key: const Key('machine-tree'),
              children: <Widget>[
                ListTile(
                  dense: true,
                  selected: !onMachineSide,
                  leading: Badge(
                    key: const Key('needing-count-badge'),
                    isLabelVisible: needing > 0,
                    label: Text('$needing'),
                    child: Icon(
                      onMachineSide
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_active,
                    ),
                  ),
                  title: const Text('Needs you'),
                  onTap: onNeedsYou,
                ),
                const Divider(height: 1),
                for (final machine in machines.all)
                  ..._machine(
                    context,
                    machine,
                    here: onMachineSide && machine == current,
                    creating: creating,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.small),
            child: _StopEverywhere(onPressed: onStopEverywhere),
          ),
        ],
      ),
    );
  }

  List<Widget> _machine(
    BuildContext context,
    Machine machine, {
    required bool here,
    required bool creating,
  }) {
    final fleet = machines.of(machine);
    final open = shell.isExpanded(machine.name);
    final highlight = here ? shell.highlight : null;
    final narrowed = fleet.selectedProject?.name;
    final running = fleet.tasks.where((task) => task.running).length;
    return <Widget>[
      ListTile(
        key: ValueKey<String>('tree-machine ${machine.name}'),
        dense: true,
        leading: Badge(
          key: ValueKey<String>('waiting-count ${machine.name}'),
          isLabelVisible: fleet.clearance.count > 0,
          label: Text('${fleet.clearance.count}'),
          child: ReachIcon(
            name: machine.name,
            fleet: fleet,
            tunnel: machines.tunnels.of(machine),
          ),
        ),
        title: Text(
          machine.name,
          key: ValueKey<String>('rail-machine ${machine.name}'),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          key: ValueKey<String>('tree-toggle ${machine.name}'),
          icon: Icon(
            open ? Icons.expand_less : Icons.expand_more,
            size: Sizes.rowIcon,
          ),
          tooltip: open ? 'Hide its projects' : 'Show its projects',
          visualDensity: VisualDensity.compact,
          onPressed: () => onToggle(machine),
        ),
        onTap: () => onMachine(machine),
      ),
      if (open) ...<Widget>[
        _Entry(
          key: ValueKey<String>('tree-running ${machine.name}'),
          icon: Icons.play_circle_outline,
          title: 'Running',
          trailing: Text('$running'),
          selected: here && narrowed == null && !creating,
          onTap: () => onRunning(machine),
        ),
        Highlight(
          active: highlight == 'project.create',
          child: _Entry(
            key: here
                ? const Key('new-project')
                : ValueKey<String>('new-project ${machine.name}'),
            icon: Icons.add,
            title: 'New project',
            selected: here && creating,
            autofocus: highlight == 'project.create',
            onTap: () => onNewProject(machine),
          ),
        ),
        for (final project in fleet.projects)
          _projectEntry(
            context,
            machine,
            project,
            selected: here && !creating && narrowed == project.name,
            here: here,
          ),
      ],
    ];
  }

  Widget _projectEntry(
    BuildContext context,
    Machine machine,
    ProjectOnScreen project, {
    required bool selected,
    required bool here,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final entry = _Entry(
      key: here
          ? ValueKey<String>('project ${project.name}')
          : ValueKey<String>('project ${machine.name}/${project.name}'),
      icon: project.running > 0 ? Icons.folder : Icons.folder_outlined,
      title: project.label,
      selected: selected,
      onTap: () => onProject(machine, project.name),
      trailing: Wrap(
        spacing: Space.tight,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (muted.contains(project.name))
            Tooltip(
              message: 'Nothing about this project will be notified.',
              child: Icon(
                Icons.notifications_off_outlined,
                size: Sizes.mark,
                color: scheme.outline,
              ),
            ),
          // Waiting for review is what makes a project need a person, so it is a number here.
          if (project.project.pending > 0)
            Tooltip(
              message:
                  '${project.project.pending} '
                  '${project.project.pending == 1 ? 'push is' : 'pushes are'} waiting at the '
                  'gate, and will not leave this machine until somebody approves it.',
              child: Chip(
                avatar: Icon(
                  Icons.outbox_outlined,
                  size: Sizes.mark,
                  color: scheme.onTertiaryContainer,
                ),
                label: Text('${project.project.pending}'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                backgroundColor: scheme.tertiaryContainer,
              ),
            ),
          if (!project.project.prepared)
            Tooltip(
              message:
                  'Its environment is not prepared: a task started here would have to '
                  'build an image first.',
              child: Icon(
                Icons.construction_outlined,
                key: const Key('project-unprepared'),
                size: Sizes.mark,
                color: scheme.tertiary,
              ),
            ),
          // Prepared and up to date are different questions.
          if (project.project.environmentIsStale)
            Tooltip(
              message:
                  'Its environment was built before the project file changed.',
              child: Icon(
                Icons.update_disabled,
                key: const Key('project-stale'),
                size: Sizes.mark,
                color: scheme.error,
              ),
            ),
          if (!project.canBeActedOn)
            Tooltip(
              message:
                  'No project file recorded, so nothing can act on it. '
                  'Running a task with it once records one.',
              child: Icon(
                Icons.link_off,
                size: Sizes.mark,
                color: scheme.outline,
              ),
            ),
        ],
      ),
    );
    return selected
        ? KeyedSubtree(key: const Key('selected-row'), child: entry)
        : entry;
  }
}

/// One entry under a machine, indented beneath it.
class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.autofocus = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    autofocus: autofocus,
    contentPadding: const EdgeInsets.only(left: Space.wide, right: Space.small),
    selected: selected,
    leading: Icon(icon, size: Sizes.rowIcon),
    title: Text(title, overflow: TextOverflow.ellipsis),
    trailing: trailing,
    onTap: onTap,
  );
}

/// The stop for every machine at once, at the foot of the tree where it is always on screen.
class _StopEverywhere extends StatelessWidget {
  const _StopEverywhere({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final red = Theme.of(context).colorScheme.error;
    return Tooltip(
      message:
          'Stop everything on every machine\nWork is stopped, never removed.',
      child: TextButton.icon(
        key: const Key('stop-everywhere'),
        onPressed: onPressed,
        icon: Icon(Icons.pan_tool_outlined, size: Sizes.rowIcon, color: red),
        label: Text('Stop everything', style: TextStyle(color: red)),
      ),
    );
  }
}

/// The selected project above its work: what it is, what state it is in, and its menu.
class ProjectHeader extends StatelessWidget {
  /// Constructor taking the project and what it can be told to do.
  const ProjectHeader({
    required this.project,
    required this.muted,
    required this.menu,
    this.highlight,
    this.onShown,
    super.key,
  });

  /// The project.
  final ProjectOnScreen project;

  /// Whether nothing about it is notified.
  final bool muted;

  /// What it can be told to do.
  final List<Command> menu;

  /// The command the finder went to.
  final String? highlight;

  /// Called once the menu opened on [highlight].
  final VoidCallback? onShown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = project.project;
    final facts = <String>[
      if (!p.prepared) 'environment not prepared',
      if (p.environmentIsStale) 'environment older than its project file',
      if (p.pending > 0) '${p.pending} waiting at the gate',
      if (muted) 'not notified',
      if (!project.canBeActedOn) 'no project file recorded',
    ];
    return Container(
      key: const Key('project-header'),
      padding: const EdgeInsets.fromLTRB(
        Space.normal,
        Space.small,
        Space.small,
        Space.small,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.folder_outlined,
            size: Sizes.rowIcon,
            color: scheme.primary,
          ),
          const SizedBox(width: Space.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  project.label,
                  key: const Key('project-title'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${project.running} of ${project.howMuchWork} running'
                  '${p.securityClass.isEmpty ? '' : ' · ${p.securityClass}'}',
                  key: const Key('project-counts'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (facts.isNotEmpty)
                  Text(
                    facts.join('  ·  '),
                    key: const Key('project-facts'),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                // How far behind, with the age of the measurement in the same sentence.
                if (p.behindReason.isNotEmpty)
                  Text(
                    p.behindWords,
                    key: const Key('project-behind'),
                    overflow: TextOverflow.ellipsis,
                    style: p.hasFallenBehind
                        ? theme.textTheme.bodySmall?.copyWith(
                            color: scheme.tertiary,
                          )
                        : theme.textTheme.bodySmall,
                  ),
                if (p.file.isNotEmpty)
                  Text(
                    p.file,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          CommandMenu(
            key: const Key('project-menu'),
            commands: menu,
            tooltip: 'What ${project.label} can be told to do',
            highlight: highlight,
            onShown: onShown,
          ),
        ],
      ),
    );
  }
}
