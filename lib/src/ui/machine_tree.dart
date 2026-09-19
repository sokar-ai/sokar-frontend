import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

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
/// A machine opens like an accordion. Under it come the work running there, a way to follow a
/// repository, and every project. The stop for every machine stays at the foot.
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
    required this.onFollow,
    required this.onProject,
    required this.onStopEverywhere,
    required this.onRefresh,
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

  /// Follows a repository on a machine, which is how a project comes to it.
  final void Function(Machine machine) onFollow;

  /// Shows one project of a machine.
  final void Function(Machine machine, String project) onProject;

  /// Asks before stopping everything on every machine.
  final VoidCallback onStopEverywhere;

  /// Asks every machine again, now.
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final current = machines.current;
    final onMachineSide = shell.section == Section.machine;
    final following = shell.opened is ProjectFollowingOpened;
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
                    following: following,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.small),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Tooltip(
                  message: 'Ask every machine again, now',
                  child: TextButton.icon(
                    key: const Key('refresh-all'),
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: Sizes.rowIcon),
                    label: const Text('Refresh'),
                  ),
                ),
                _StopEverywhere(
                  onPressed: machines.all.any(
                    (each) => machines.of(each).reachability == Reachability.connected,
                  )
                      ? onStopEverywhere
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _machine(
    BuildContext context,
    Machine machine, {
    required bool here,
    required bool following,
  }) {
    final fleet = machines.of(machine);
    final open = shell.isExpanded(machine.name);
    final highlight = here ? shell.highlight : null;
    final narrowed = fleet.selectedProject?.name;
    final running = fleet.tasks.where((task) => task.running).length;
    final answering = fleet.reachability == Reachability.connected;
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
          selected: here && narrowed == null && !following,
          onTap: () => onRunning(machine),
        ),
        Highlight(
          active: highlight == 'project.follow',
          child: Tooltip(
            message: answering ? '' : 'Not answering, so nothing can be followed there',
            child: _Entry(
            key: here
                ? const Key('follow-a-repository')
                : ValueKey<String>('follow-a-repository ${machine.name}'),
            icon: Icons.add_link,
            title: 'Follow a repository',
            selected: here && following,
            autofocus: highlight == 'project.follow',
            onTap: () => onFollow(machine),
            enabled: answering,
          ),
          ),
        ),
        for (final project in fleet.projects)
          _projectEntry(
            context,
            machine,
            project,
            selected: here && !following && narrowed == project.name,
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
          // Said wherever the project is: nothing checks what this machine is handed for it.
          if (project.project.following?.unverified ?? false)
            Tooltip(
              message:
                  'Followed unverified: anybody who can push to its repository decides what this '
                  'machine runs.',
              child: Icon(
                Icons.gpp_maybe_outlined,
                key: const Key('project-unverified'),
                size: Sizes.mark,
                color: scheme.error,
              ),
            ),
          if (!project.canBeActedOn)
            Tooltip(
              message:
                  'This machine does not follow it, so nothing can act on it. '
                  'Following its repository makes it a project here.',
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
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    autofocus: autofocus,
    contentPadding: const EdgeInsets.only(left: Space.wide, right: Space.small),
    enabled: enabled,
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

  final VoidCallback? onPressed;

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
    this.onSync,
    this.onBackups,
    this.onOpens,
    this.onReach,
    super.key,
  });

  /// The project.
  final ProjectOnScreen project;

  /// Asks one repository's upstream how far behind it is, now.
  final void Function(String repository)? onSync;

  /// Shows what has been backed up of one repository.
  final void Function(String repository)? onBackups;

  /// Shows what work in one repository would open, creating nothing.
  final void Function(String repository)? onOpens;

  /// Shows, and changes, what one repository adds to what the project may reach.
  final void Function(String repository)? onReach;

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
      if (!project.canBeActedOn) 'not followed here',
      if (p.following?.unverified ?? false) 'unverified',
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
                // **One line per repository once there is more than one** (Sokar B67): each has
                // its own upstream, gate and backups, and one number for all of them was the
                // project's own shown against every other.
                if (p.repositoryStates.length > 1)
                  for (final repository in p.repositoryStates)
                    _RepositoryLine(
                      repository: repository,
                      onSync: project.canBeActedOn ? onSync : null,
                      onBackups: project.canBeActedOn ? onBackups : null,
                      onOpens: project.canBeActedOn ? onOpens : null,
                      onReach: project.canBeActedOn ? onReach : null,
                    )
                // How far behind, with the age of the measurement in the same sentence.
                else if (p.behindReason.isNotEmpty)
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
                // Where this account's following has got, and why it stopped when it did.
                if (p.following case final followed?)
                  Text(
                    followed.words,
                    key: const Key('project-following'),
                    overflow: TextOverflow.ellipsis,
                    style: followed.needsAPerson
                        ? theme.textTheme.bodySmall?.copyWith(color: scheme.error)
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

/// One of a project's repositories: how far it has got, and its own sync and backups.
class _RepositoryLine extends StatelessWidget {
  const _RepositoryLine(
      {required this.repository, this.onSync, this.onBackups, this.onOpens, this.onReach});

  final Repository repository;

  final void Function(String repository)? onSync;

  final void Function(String repository)? onBackups;

  final void Function(String repository)? onOpens;

  final void Function(String repository)? onReach;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = repository.name;
    final opens = onOpens;
    final reach = onReach;
    final sync = onSync;
    final backups = onBackups;
    return Row(
      key: Key('repository-$name'),
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                <String>[
                  repository.own ? '$name, its own' : name,
                  if (repository.pending > 0) '${repository.pending} waiting at the gate',
                  if (repository.behindReason.isNotEmpty) repository.behindWords,
                ].join(' · '),
                overflow: TextOverflow.ellipsis,
                style: repository.hasFallenBehind
                    ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary)
                    : theme.textTheme.bodySmall,
              ),
              // A repository's limits replace the project's key by key; the ones it replaced are
              // marked. The rest are never said to be the project's choice: they may be Sokar's.
              if (repository.limits case final limits?)
                Text(
                  limits.words,
                  key: Key('limits-$name'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        IconButton(
          key: Key('sync-$name'),
          icon: const Icon(Icons.sync, size: Sizes.rowIcon),
          visualDensity: VisualDensity.compact,
          tooltip: "Ask $name's upstream how far behind it is, now",
          onPressed: sync == null ? null : () => sync(name),
        ),
        IconButton(
          key: Key('backups-$name'),
          icon: const Icon(Icons.inventory_2_outlined, size: Sizes.rowIcon),
          visualDensity: VisualDensity.compact,
          tooltip: 'Backups of $name',
          onPressed: backups == null ? null : () => backups(name),
        ),
        // A repository's egress is added to the project's (Sokar B68), so this is the project's
        // plan and what this repository adds to it — the daemon's reply says which is which.
        IconButton(
          key: Key('opens-$name'),
          icon: const Icon(Icons.travel_explore, size: Sizes.rowIcon),
          visualDensity: VisualDensity.compact,
          tooltip: 'Show what work in $name would open, creating nothing',
          onPressed: opens == null ? null : () => opens(name),
        ),
        IconButton(
          key: Key('reach-$name'),
          icon: const Icon(Icons.public, size: Sizes.rowIcon),
          visualDensity: VisualDensity.compact,
          tooltip: 'What $name may reach, on top of what the project grants',
          onPressed: reach == null ? null : () => reach(name),
        ),
      ],
    );
  }
}
