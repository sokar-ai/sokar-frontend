import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/commands.dart';
import '../app/fleet_model.dart';
import '../app/work_held.dart';
import 'command_menu.dart';
import 'how_long.dart';
import 'tokens.dart';

/// The heading over a pane, so a pane is identifiable when it is the only one on screen.
class PaneHeader extends StatelessWidget {
  /// Constructor taking what the pane is called and anything to show beside it.
  const PaneHeader({
    required this.title,
    this.trailing,
    this.leading,
    super.key,
  });

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
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
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

/// One project on its machine: what it is, what state it is in, and what it can be told to do.
///
/// Tapping it narrows the work below to it; tapping it again shows all of it.
class ProjectCard extends StatelessWidget {
  /// Constructor taking the project and what it can be told to do.
  const ProjectCard({
    required this.project,
    required this.selected,
    required this.muted,
    required this.onTap,
    required this.menu,
    this.highlight,
    this.onShown,
    super.key,
  });

  /// The project.
  final ProjectOnScreen project;

  /// Whether the work below is narrowed to it.
  final bool selected;

  /// Whether nothing about it is notified. Shown, because a switch nobody can see the state of is
  /// one people turn off twice and never back on.
  final bool muted;

  /// Narrows the work to it, or widens it back.
  final VoidCallback onTap;

  /// What it can be told to do.
  final List<Command> menu;

  /// The command the finder went to.
  final String? highlight;

  /// Called once the menu opened on [highlight].
  final VoidCallback? onShown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final classification = project.project.securityClass;
    final card = SizedBox(
      width: 280,
      child: Card(
        key: ValueKey<String>('project ${project.name}'),
        shape: selected
            ? RoundedRectangleBorder(
                side: BorderSide(color: scheme.primary, width: 2),
                borderRadius: BorderRadius.circular(Radii.medium),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.normal,
              Space.tight,
              Space.tight,
              Space.normal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // A project is not a task: what it has is work running or not.
                    Container(
                      width: Sizes.dot,
                      height: Sizes.dot,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: project.running > 0
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(width: Space.small),
                    Expanded(child: Text(project.label, style: text.bodyLarge)),
                    CommandMenu(
                      commands: menu,
                      tooltip: 'What ${project.label} can be told to do',
                      highlight: highlight,
                      onShown: onShown,
                    ),
                  ],
                ),
                Text(
                  '${project.running} of ${project.howMuchWork} running'
                  '${classification.isEmpty ? '' : ' · $classification'}',
                  style: text.bodySmall,
                ),
                // How far behind, with the age of the measurement in the same sentence.
                if (project.project.behindReason.isNotEmpty)
                  Text(
                    project.project.behindWords,
                    key: const Key('project-behind'),
                    style: project.project.hasFallenBehind
                        ? text.bodySmall?.copyWith(color: scheme.tertiary)
                        : text.bodySmall,
                  ),
                const SizedBox(height: Space.tight),
                Wrap(
                  spacing: Space.tight,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    if (muted)
                      Tooltip(
                        message: 'Nothing about this project will be notified.',
                        child: Icon(
                          Icons.notifications_off_outlined,
                          size: Sizes.rowIcon,
                          color: scheme.outline,
                        ),
                      ),
                    // Waiting for review is what makes a project need a person.
                    if (project.project.pending > 0)
                      Tooltip(
                        message:
                            '${project.project.pending} '
                            '${project.project.pending == 1 ? 'push is' : 'pushes are'} waiting '
                            'at the gate.\nWork an agent finished and pushed, which will not '
                            'leave this machine until somebody approves it.',
                        child: Chip(
                          avatar: Icon(
                            Icons.outbox_outlined,
                            size: Sizes.rowIcon,
                            color: scheme.onTertiaryContainer,
                          ),
                          label: Text('${project.project.pending}'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: scheme.tertiaryContainer,
                        ),
                      ),
                    if (!project.project.prepared)
                      Tooltip(
                        message:
                            'Its environment is not prepared: a task started here would '
                            'have to build an image first.',
                        child: Icon(
                          Icons.construction_outlined,
                          key: const Key('project-unprepared'),
                          size: Sizes.rowIcon,
                          color: scheme.tertiary,
                        ),
                      ),
                    // Prepared and up to date are different questions.
                    if (project.project.environmentIsStale)
                      Tooltip(
                        message:
                            'Its environment was built before the project file changed. '
                            'Work started here would run in something the file no longer '
                            'describes.',
                        child: Icon(
                          Icons.update_disabled,
                          key: const Key('project-stale'),
                          size: Sizes.rowIcon,
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
                          size: Sizes.rowIcon,
                          color: scheme.outline,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return selected
        ? KeyedSubtree(key: const Key('selected-row'), child: card)
        : card;
  }
}

/// One piece of work, opened over the frame.
class WorkDetail extends StatelessWidget {
  /// Constructor taking the work and how to close it.
  const WorkDetail({
    required this.task,
    required this.held,
    required this.onClose,
    super.key,
  });

  /// What is open.
  final Task task;

  /// What it holds that never reached the gate, asked when this opened.
  final WorkHeld held;

  /// Closes it, leaving the selection where it was.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: held,
    builder: (context, _) => _detail(context),
  );

  Widget _detail(BuildContext context) {
    // A container that is up with no helpers has lost its gate or its clearance watcher, and is
    // not the same thing as a healthy task. It is the one reading worth calling out here.
    final ungated = task.running && task.helpers == 0;

    return Column(
      children: <Widget>[
        PaneHeader(
          title: task.label.isEmpty ? task.name : task.label,
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
              // Only when a caption is standing in front of it: the heading is the name when
              // there is no caption, and repeating it would be noise. When there is one, the
              // identity has to be somewhere — it is what every other call takes.
              if (task.label.isNotEmpty)
                _Field(name: 'Its name', value: task.name),
              _Field(
                name: 'Project',
                value: task.project.isEmpty ? '—' : task.project,
              ),
              _Field(
                name: 'Security class',
                value: task.securityClass.isEmpty ? '—' : task.securityClass,
              ),
              _Field(
                name: 'Agent',
                value: task.agent.isEmpty ? '—' : task.agent,
              ),
              _Field(name: 'Mode', value: task.mode.label),
              _Field(
                name: 'Branch',
                value: task.branch.isEmpty ? '—' : task.branch,
              ),
              // **Answered by the task, never joined.** `Task.name` is a container name and a
              // pending push carries a task name, and several containers over time share one
              // ref — so a client lining the two up would be right for at most one of them.
              //
              // An `online` task answers `0` and that is not a smaller number: nothing is ever
              // reviewed there, so it is a question the class does not have, and saying *nothing
              // is waiting* would imply somebody could be.
              _Field(name: 'At the gate', value: task.atTheGate),
              // **The other half of the same question, and it costs a call.** What is waiting at
              // the gate comes free with the task; what never reached it runs git inside the
              // container, so it is asked when this opens and never while drawing a list.
              //
              // Three answers rather than two: *holds nothing* and *nobody could look* are
              // different, and only one of them makes it safe to remove a task without asking.
              if (held.words(task.name).isNotEmpty)
                _Field(name: 'Never pushed', value: held.words(task.name)),
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
              if (task.activity == Activity.waiting &&
                  task.waitingFor.isNotEmpty)
                _Field(name: 'Waiting on', value: task.waitingFor),
              _Field(name: 'For', value: howLong(task) ?? 'not recorded'),
              _Field(name: 'Runtime says', value: task.state),
              _Field(name: 'Helpers alive', value: '${task.helpers}'),
              if (task.prompt.isNotEmpty)
                _Field(name: 'Asked to', value: task.prompt),
              // **Where somebody asks what this agent was told, and the honest answer is "not
              // here".** Standing instructions live in the repository, checked in or not, and
              // Sokar does not know what they are called — `CLAUDE.md`, `AGENTS.md`, whatever an
              // agent invents next year — nor how a given agent combines several of them.
              //
              // A screen that guessed a set of filenames would answer *"no instructions"* with
              // confidence for a task that had them, which is worse than saying nothing.
              const _Field(
                name: 'Standing instructions',
                value: 'in the repository — nothing here has a view of them',
              ),
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
  const ActivityMark({
    required this.activity,
    required this.running,
    super.key,
  });

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
        scheme.outlineVariant,
      ),
    };
    return Tooltip(
      message: activity.label,
      child: Icon(icon, size: Sizes.mark, color: color),
    );
  }
}

/// Asks what a piece of work should read as.
///
/// **A caption, never a rename.** The container name is the identity — what every other call
/// takes, and what the gate ref, the workspace and the log files are built from — so it is shown
/// here rather than edited, and emptying the box takes the caption away rather than storing
/// nothing under a name.
Future<String?> askWhatItReadsAs(BuildContext context, {required Task task}) =>
    showDialog<String>(
      context: context,
      builder: (context) => _WhatItReadsAs(task: task),
    );

class _WhatItReadsAs extends StatefulWidget {
  const _WhatItReadsAs({required this.task});

  final Task task;

  @override
  State<_WhatItReadsAs> createState() => _WhatItReadsAsState();
}

class _WhatItReadsAsState extends State<_WhatItReadsAs> {
  late final TextEditingController _caption = TextEditingController(
    text: widget.task.label,
  );

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('What should this read as?'),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Its name stays ${widget.task.name}. That is what every other action takes, and '
            'what you would type on the machine — a caption sits in front of it in lists, '
            'never in place of it.',
            key: const Key('name-does-not-move'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Space.normal),
          TextField(
            key: const Key('what-it-reads-as'),
            controller: _caption,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Reads as',
              hintText: 'schema migration, second attempt',
              helperText: 'Leave it empty to take the caption away.',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (typed) => Navigator.of(context).pop(typed.trim()),
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Leave it'),
      ),
      FilledButton(
        key: const Key('name-it'),
        onPressed: () => Navigator.of(context).pop(_caption.text.trim()),
        child: const Text('Use it'),
      ),
    ],
  );
}
