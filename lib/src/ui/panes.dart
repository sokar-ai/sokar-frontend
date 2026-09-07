import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/commands.dart';
import '../app/fleet_model.dart';
import 'command_menu.dart';
import 'how_long.dart';
import 'selection_list.dart';
import 'tokens.dart';

/// The heading over a pane, so a pane is identifiable when it is the only one on screen.
class PaneHeader extends StatelessWidget {
  /// Constructor taking what the pane is called and anything to show beside it.
  const PaneHeader({required this.title, this.trailing, this.leading, super.key});

  /// What the pane is.
  final String title;

  /// Shown at the end of the header, usually a count.
  final Widget? trailing;

  /// Shown before the title, usually a way back on a narrow window.
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
          leading == null ? Space.normal : Space.tight,
          Space.small,
          Space.normal,
          Space.small,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: <Widget>[
            ?leading,
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            ?trailing,
          ],
        ),
      );
}

/// The projects on the machine, and which of them have work running.
///
/// This is the opening view and it answers before anything is selected, which is the point of
/// it: a person should know whether the machine needs them without opening anything.
class ProjectsPane extends StatelessWidget {
  /// Constructor taking the fleet, this pane's focus and what Return does.
  const ProjectsPane({
    required this.fleet,
    required this.focusNode,
    required this.onActivate,
    required this.onFocused,
    required this.mutedProjects,
    this.leading,
    super.key,
  });

  /// What is on the machine.
  final FleetModel fleet;

  /// This pane's keyboard focus.
  final FocusNode focusNode;

  /// Called when a project is opened, rather than merely selected.
  final VoidCallback onActivate;

  /// Called when the pointer puts the keyboard in this pane, so closing something opened from
  /// here comes back here rather than wherever the keyboard happened to be last.
  final VoidCallback onFocused;

  /// Projects nothing is notified about.
  final Set<String> mutedProjects;

  /// A way back, on a window too narrow for two panes.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final projects = fleet.projects;
    final running = projects.fold<int>(0, (total, project) => total + project.running);

    return Column(
      children: <Widget>[
        PaneHeader(
          title: 'Projects',
          leading: leading,
          trailing: Text(
            projects.isEmpty ? '' : '$running running',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: SelectionList<ProjectOnScreen>(
            items: projects,
            idOf: (project) => project.name,
            selected: fleet.selectedProject?.name,
            onSelect: (name) {
              onFocused();
              fleet.selectProject(name);
            },
            onActivate: (_) => onActivate(),
            focusNode: focusNode,
            emptyMessage: _emptyMessage(fleet),
            rowOf: (context, project, selected) => _ProjectRow(
              project: project,
              onOpen: onActivate,
              muted: mutedProjects.contains(project.name),
            ),
          ),
        ),
      ],
    );
  }

  static String _emptyMessage(FleetModel fleet) => switch (fleet.reachability) {
        Reachability.connecting => 'Asking the backend what is here.',
        Reachability.unreachable =>
          'Not connected, so what is here is unknown.\nThis is not an empty machine.',
        Reachability.incompatible => 'This backend speaks nothing this build understands.',
        // Projects are derived from the tasks that mention them, so a project that has never
        // run anything cannot appear here at all. That is F02, and it needs a backend method.
        Reachability.connected =>
          'No work has run on this machine, so no project names itself yet.',
      };
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.project,
    required this.onOpen,
    required this.muted,
  });

  final ProjectOnScreen project;
  final VoidCallback onOpen;

  /// Whether nothing about this project is notified. Shown, because a switch nobody can see the
  /// state of is one people turn off twice and never back on.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final classification = project.project.securityClass;
    return Row(
      children: <Widget>[
        // A project is not a task: what it has is work running or not, so a dot rather than an
        // activity, which belongs to one piece of work and not to a group of them.
        Container(
          width: Sizes.dot,
          height: Sizes.dot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: project.running > 0 ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        const SizedBox(width: Space.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(project.label, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                '${project.running} of ${project.howMuchWork} running'
                '${classification.isEmpty ? '' : ' · $classification'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (muted)
          Tooltip(
            message: 'Nothing about this project will be notified.',
            child: Icon(Icons.notifications_off_outlined,
                size: Sizes.rowIcon, color: scheme.outline),
          ),
        // Waiting for review is the one thing that makes a project need a person, so it is a
        // number on the row rather than something found by opening it. It says what is waiting
        // and what happens next: a bare count needed explaining, which means it was not saying
        // anything.
        if (project.project.pending > 0)
          Tooltip(
            message: '${project.project.pending} '
                '${project.project.pending == 1 ? 'push is' : 'pushes are'} waiting at the '
                'gate.\nWork an agent finished and pushed, which will not leave this machine '
                'until somebody approves it.',
            child: Chip(
              // An outbox: work that is finished and has not been sent. `Approve` is the only
              // call in the whole contract that sends anything anywhere, so that is exactly what
              // is waiting here.
              avatar: Icon(Icons.outbox_outlined,
                  size: Sizes.rowIcon, color: scheme.onTertiaryContainer),
              label: Text('${project.project.pending}'),
              visualDensity: VisualDensity.compact,
              backgroundColor: scheme.tertiaryContainer,
            ),
          ),
        // A project the daemon has no file for can be listed and not acted on. Saying so on the
        // row beats a refusal at the point somebody tries.
        if (!project.canBeActedOn)
          Tooltip(
            message: 'No project file recorded, so nothing can act on it. '
                'Running a task with it once records one.',
            child: Icon(Icons.link_off, size: Sizes.rowIcon, color: scheme.outline),
          ),
        _OpenButton(tooltip: 'Show the work in ${project.label}', onPressed: onOpen),
      ],
    );
  }
}

/// The work under the selected project.
class WorkPane extends StatelessWidget {
  /// Constructor taking the fleet, this pane's focus and what Return does.
  const WorkPane({
    required this.fleet,
    required this.focusNode,
    required this.onActivate,
    required this.onFocused,
    required this.actionsFor,
    this.leading,
    super.key,
  });

  /// What is on the machine.
  final FleetModel fleet;

  /// This pane's keyboard focus.
  final FocusNode focusNode;

  /// Called when a piece of work is opened.
  final VoidCallback onActivate;

  /// Called when the pointer puts the keyboard in this pane, so closing something opened from
  /// here comes back here rather than wherever the keyboard happened to be last.
  final VoidCallback onFocused;

  /// What one piece of work offers, acted on from the same place it is listed.
  final List<Command> Function(Task task) actionsFor;

  /// A way back, on a window too narrow for two panes.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final project = fleet.selectedProject;
    final work = fleet.workInView;

    return Column(
      children: <Widget>[
        PaneHeader(
          title: project == null ? 'Work' : 'Work in ${project.label}',
          leading: leading,
          trailing: Text(
            work.isEmpty ? '' : '${work.length}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: SelectionList<Task>(
            items: work,
            idOf: (task) => task.name,
            selected: fleet.selectedTask?.name,
            onSelect: (name) {
              onFocused();
              fleet.selectTask(name);
            },
            onActivate: (_) => onActivate(),
            focusNode: focusNode,
            emptyMessage: project == null
                ? 'Select a project to see the work under it.'
                : 'Nothing has run in ${project.label}.',
            rowOf: (context, task, selected) => _WorkRow(
              task: task,
              onOpen: onActivate,
              actions: actionsFor(task),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkRow extends StatelessWidget {
  const _WorkRow({
    required this.task,
    required this.onOpen,
    required this.actions,
  });

  final Task task;
  final VoidCallback onOpen;
  final List<Command> actions;

  @override
  Widget build(BuildContext context) {
    final age = howLong(task);
    return Row(
      children: <Widget>[
        ActivityMark(activity: task.activity, running: task.running),
        const SizedBox(width: Space.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(task.name, style: Theme.of(context).textTheme.bodyLarge),
              // The activity and how long it has been that way, then the runtime's own words.
              // "Idle for forty minutes" is arithmetic on `since`; `state` is prose and is never
              // parsed for it.
              Text(
                <String>[
                  task.activity.label,
                  if (age != null) 'for $age',
                  if (task.state.isNotEmpty) '· ${task.state}',
                ].join(' '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (task.activity == Activity.waiting && task.waitingFor.isNotEmpty)
                Text(
                  'waiting on ${task.waitingFor}',
                  key: const Key('waiting-for'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ),
        // Nothing asks and nothing is refused for this one. Somebody chose that; showing it like
        // any other run would hide the choice, which is the whole reason the field exists.
        if (task.unenforced)
          Tooltip(
            message: 'Nothing is enforcing what this work may reach. '
                'No connection will be refused and nothing will be asked.',
            child: Chip(
              key: const Key('unenforced'),
              avatar: Icon(Icons.gpp_bad_outlined,
                  size: Sizes.rowIcon,
                  color: Theme.of(context).colorScheme.onErrorContainer),
              label: const Text('unenforced'),
              visualDensity: VisualDensity.compact,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
          ),
        _OpenButton(tooltip: 'Open ${task.name}', onPressed: onOpen),
        CommandMenu(commands: actions, tooltip: 'What ${task.name} can be told to do'),
      ],
    );
  }
}

/// Opens what a row points at, for somebody working with a pointer.
///
/// The keyboard has Return for this. A pointer needs its own way in, because a pointer is
/// optional everywhere and must therefore be sufficient everywhere it is used.
class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.chevron_right, size: Sizes.rowIcon),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
      );
}

/// One piece of work, opened over the frame.
class WorkDetail extends StatelessWidget {
  /// Constructor taking the work and how to close it.
  const WorkDetail({required this.task, required this.onClose, super.key});

  /// What is open.
  final Task task;

  /// Closes it, leaving the selection where it was.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // A container that is up with no helpers has lost its gate or its clearance watcher, and is
    // not the same thing as a healthy task. It is the one reading worth calling out here.
    final ungated = task.running && task.helpers == 0;

    return Column(
      children: <Widget>[
        PaneHeader(
          title: task.name,
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close (Esc)',
            onPressed: onClose,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Space.wide),
            children: <Widget>[
              _Field(name: 'Project', value: task.project.isEmpty ? '—' : task.project),
              _Field(
                name: 'Security class',
                value: task.securityClass.isEmpty ? '—' : task.securityClass,
              ),
              _Field(name: 'Agent', value: task.agent.isEmpty ? '—' : task.agent),
              _Field(name: 'Mode', value: task.mode.label),
              _Field(name: 'Branch', value: task.branch.isEmpty ? '—' : task.branch),
              _Field(name: 'Doing', value: task.activity.label),
              _Field(
                name: 'Egress',
                value: switch (task.clearance) {
                  'off' => 'nothing is enforcing it',
                  'prompt' => 'asks before letting anything new through',
                  'allow' => 'lets anything new through',
                  'deny' => 'refuses anything new without asking',
                  _ => 'not recorded',
                },
              ),
              if (task.activity == Activity.waiting && task.waitingFor.isNotEmpty)
                _Field(name: 'Waiting on', value: task.waitingFor),
              _Field(name: 'For', value: howLong(task) ?? 'not recorded'),
              _Field(name: 'Runtime says', value: task.state),
              _Field(name: 'Helpers alive', value: '${task.helpers}'),
              if (task.prompt.isNotEmpty)
                _Field(name: 'Asked to', value: task.prompt),
              if (ungated) ...<Widget>[
                const SizedBox(height: Space.wide),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(Space.normal),
                    child: Text(
                      'This container is up with no helpers alive: its gate or its clearance '
                      'watcher is gone.',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.tight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 140,
              child: Text(name, style: Theme.of(context).textTheme.labelLarge),
            ),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
}

/// What the work is doing, in the space of a dot.
///
/// **`UNKNOWN` gets its own mark and is never drawn as idle.** It is the normal answer for a task
/// somebody attached a terminal to, and a state that is silently wrong is worse than one that
/// says it cannot see.
class ActivityMark extends StatelessWidget {
  /// Constructor taking what the work is doing and whether the container is up.
  const ActivityMark({required this.activity, required this.running, super.key});

  /// What the work is doing.
  final Activity activity;

  /// Whether the runtime says the container is up.
  final bool running;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = switch (activity) {
      Activity.waiting => (Icons.pan_tool_outlined, scheme.error),
      Activity.working => (Icons.play_circle_outline, scheme.primary),
      Activity.idle => (Icons.pause_circle_outline, scheme.outline),
      Activity.dead => (Icons.stop_circle_outlined, scheme.outlineVariant),
      Activity.unknown => (Icons.help_outline, scheme.outline),
      // A value from a later release, or a task older than these fields. Fall back to the one
      // thing that has always been there rather than picking a meaning.
      _ => (
          running ? Icons.play_circle_outline : Icons.stop_circle_outlined,
          scheme.outlineVariant
        ),
    };
    return Tooltip(
      message: activity.label,
      child: Icon(icon, size: Sizes.mark, color: color),
    );
  }
}
