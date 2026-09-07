import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/fleet_model.dart';
import 'selection_list.dart';

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
        padding: EdgeInsets.fromLTRB(leading == null ? 12 : 4, 8, 12, 8),
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
    this.leading,
    super.key,
  });

  /// What is on the machine.
  final FleetModel fleet;

  /// This pane's keyboard focus.
  final FocusNode focusNode;

  /// Called when a project is opened, rather than merely selected.
  final VoidCallback onActivate;

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
          child: SelectionList<Project>(
            items: projects,
            idOf: (project) => project.name,
            selected: fleet.selectedProject?.name,
            onSelect: fleet.selectProject,
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

  final Project project;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final classes = project.securityClasses.join(', ');
    return Row(
      children: <Widget>[
        _RunningDot(running: project.running > 0),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(project.label, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                '${project.running} of ${project.tasks.length} running'
                '${classes.isEmpty ? '' : ' · $classes'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
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
    this.leading,
    super.key,
  });

  /// What is on the machine.
  final FleetModel fleet;

  /// This pane's keyboard focus.
  final FocusNode focusNode;

  /// Called when a piece of work is opened.
  final VoidCallback onActivate;

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
            onSelect: fleet.selectTask,
            onActivate: (_) => onActivate(),
            focusNode: focusNode,
            emptyMessage: project == null
                ? 'Select a project to see the work under it.'
                : 'Nothing has run in ${project.label}.',
            rowOf: (context, task, selected) =>
                _WorkRow(task: task, onOpen: onActivate),
          ),
        ),
      ],
    );
  }
}

class _WorkRow extends StatelessWidget {
  const _WorkRow({required this.task, required this.onOpen});

  final Task task;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          _RunningDot(running: task.running),
          const SizedBox(width: 8),
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
        icon: const Icon(Icons.chevron_right, size: 18),
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
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
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
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: running
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      );
}
