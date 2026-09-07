import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/commands.dart';
import '../app/fleet_model.dart';
import 'command_menu.dart';
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
            rowOf: (context, project, selected) =>
                _ProjectRow(project: project, onOpen: onActivate),
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
  const _ProjectRow({required this.project, required this.onOpen});

  final ProjectOnScreen project;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final classification = project.project.securityClass;
    return Row(
      children: <Widget>[
        _RunningDot(running: project.running > 0),
        const SizedBox(width: Space.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(project.label, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                '${project.running} of ${project.tasks.length} running'
                '${classification.isEmpty ? '' : ' · $classification'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Waiting for review is the one thing that makes a project need somebody, so it is a
        // number on the row rather than something found by opening it.
        if (project.project.pending > 0)
          Tooltip(
            message: '${project.project.pending} waiting for review',
            child: Chip(
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
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          _RunningDot(running: task.running),
          const SizedBox(width: Space.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(task.name, style: Theme.of(context).textTheme.bodyLarge),
                Text(task.state, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          _OpenButton(tooltip: 'Open ${task.name}', onPressed: onOpen),
          CommandMenu(commands: actions, tooltip: 'What ${task.name} can be told to do'),
        ],
      );
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
              _Field(name: 'Runtime says', value: task.state),
              _Field(name: 'Up', value: task.running ? 'yes' : 'no'),
              _Field(name: 'Helpers alive', value: '${task.helpers}'),
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

class _RunningDot extends StatelessWidget {
  const _RunningDot({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) => Container(
        width: Sizes.dot,
        height: Sizes.dot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: running
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      );
}
