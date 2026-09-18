import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/attention.dart';
import '../app/commands.dart';
import '../app/fleet_model.dart';
import '../app/machines.dart';
import '../app/operations.dart';
import 'command_menu.dart';
import 'how_long.dart';
import 'operations.dart';
import 'panes.dart';
import 'tokens.dart';

/// What needs a person, from every machine at once. The window opens here.
///
/// **A landing surface, not a second view.** The rail is for going somewhere to change something;
/// this is for finding out whether anything needs you, and answering it where it is.
class AttentionView extends StatefulWidget {
  /// Constructor taking what to show and what the tiles can do.
  const AttentionView({
    required this.attention,
    required this.onDecide,
    required this.actionsFor,
    required this.onReview,
    this.onPutAway,
    this.onSelect,
    this.onOpenOperation,
    super.key,
  });

  /// Every tile, most urgent first.
  final Attention attention;

  /// Goes to a tile's work where it lives.
  final void Function(Tile tile)? onSelect;

  /// Answers a question, on the machine that asked it.
  final void Function(Tile tile, Prompt prompt, {required bool allow}) onDecide;

  /// What the work on a tile can be told to do, on the tile's own machine.
  final List<Command> Function(Tile tile) actionsFor;

  /// Opens the gate for the work's project.
  final void Function(Tile tile) onReview;

  /// Puts away the outcome of a question, on the machine that asked it.
  final void Function(Tile tile, Prompt prompt)? onPutAway;

  /// Opens what a failed operation printed, which is what puts it away.
  final void Function(Operation operation)? onOpenOperation;

  @override
  State<AttentionView> createState() => _AttentionViewState();
}

class _AttentionViewState extends State<AttentionView> {
  // A countdown that does not move overstates the time left, so it ticks while one is on screen.
  Timer? _ticker;

  void _keepTicking(bool wanted) {
    if (wanted && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) setState(() {});
      });
    } else if (!wanted && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.attention,
    builder: (context, _) {
      final tiles = widget.attention.needing;
      final silent = widget.attention.silent;
      final failed = widget.attention.failedUnseen;
      final needing = widget.attention.needingSomebody;
      _keepTicking(
        tiles.any(
          (tile) =>
              tile.questions.any((question) => question.expiresAt != null),
        ),
      );
      return Column(
        children: <Widget>[
          PaneHeader(
            title: 'Needs you',
            trailing: Flexible(
              child: Text(
                needing == 0 ? 'nothing needs you' : '$needing need you',
                key: const Key('needing-count'),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          Expanded(
            child: tiles.isEmpty && silent.isEmpty && failed.isEmpty
                ? const Center(
                    // Not "no work": the work that needs nobody is still there, in its machine.
                    child: Text(
                      'Nothing needs you on any machine.',
                      key: Key('nothing-needs-you'),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(Space.normal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final machine in silent)
                          _MachineNotice(
                                machine: machine,
                                fleet: widget.attention.fleetOf(machine),
                                onSeen: () => widget.attention.markSeen(machine),
                              ),
                        if (silent.isNotEmpty)
                          const SizedBox(height: Space.small),
                        Wrap(
                          spacing: Space.normal,
                          runSpacing: Space.normal,
                          children: <Widget>[
                            // A question can still be answered, so it comes before a failure.
                            for (final tile in tiles)
                              if (tile.demand == Demand.question) _tile(tile),
                            for (final operation in failed)
                              _FailedOperation(
                                operation: operation,
                                onOpen: widget.onOpenOperation == null
                                    ? null
                                    : () => widget.onOpenOperation!(operation),
                              ),
                            for (final tile in tiles)
                              if (tile.demand != Demand.question) _tile(tile),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );
    },
  );
}

extension on _AttentionViewState {
  Widget _tile(Tile tile) => TaskTile(
        tile: tile,
        actions: tile.task == null ? const <Command>[] : widget.actionsFor(tile),
        onDecide: widget.onDecide,
        onReview: widget.onReview,
        onPutAway: widget.onPutAway,
        onSelect: widget.onSelect == null ? null : () => widget.onSelect!(tile),
      );
}

/// An operation somebody started that failed, waiting until they have opened it.
class _FailedOperation extends StatelessWidget {
  const _FailedOperation({required this.operation, required this.onOpen});

  final Operation operation;

  /// Opens what it printed.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 320,
      child: Card(
        key: ValueKey<String>('failed-operation ${operation.id}'),
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(Space.normal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                operation.machine.isEmpty ? 'this window' : operation.machine,
                key: const Key('failed-operation-machine'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Space.small),
              Row(
                children: <Widget>[
                  OperationMark(operation: operation),
                  const SizedBox(width: Space.small),
                  Expanded(child: Text(operation.title, style: text.bodyLarge)),
                ],
              ),
              Text(operation.summary, style: text.bodySmall),
              TextButton(
                key: const Key('failed-operation-open'),
                onPressed: onOpen,
                child: const Text('Open what it printed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A machine that is not answering, said about the machine: it is not work, so it is not a tile.
class _MachineNotice extends StatelessWidget {
  const _MachineNotice({required this.machine, required this.fleet, required this.onSeen});

  final Machine machine;
  final FleetModel fleet;

  /// Marks it seen, so it goes from what needs a person until the machine answers again.
  final VoidCallback onSeen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final what = switch (fleet.reachability) {
      Reachability.connecting => 'is still connecting, so nothing is known yet',
      Reachability.incompatible => 'serves nothing this build understands',
      _ => 'cannot be reached',
    };
    return Container(
      key: ValueKey<String>('machine-notice ${machine.name}'),
      margin: const EdgeInsets.only(bottom: Space.small),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.normal,
        vertical: Space.small,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(Radii.small),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.cloud_off,
            size: Sizes.rowIcon,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: Space.small),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: machine.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ' $what, and anything it is asking waits unseen.',
                  ),
                  if (fleet.status.isNotEmpty)
                    TextSpan(text: '  ${fleet.status}', style: text.bodySmall),
                ],
              ),
            ),
          ),
          TextButton(
            key: ValueKey<String>('notice-seen ${machine.name}'),
            onPressed: onSeen,
            child: const Text('Seen'),
          ),
        ],
      ),
    );
  }
}

/// One tile. Its state is legible without opening it, and it carries its own actions.
class TaskTile extends StatelessWidget {
  /// Constructor taking the tile and what it can do.
  const TaskTile({
    required this.tile,
    required this.actions,
    required this.onDecide,
    required this.onReview,
    this.onPutAway,
    this.selected = false,
    this.onSelect,
    this.onOpen,
    this.highlight,
    this.onShown,
    super.key,
  });

  /// What the tile is about.
  final Tile tile;

  /// What its work can be told to do.
  final List<Command> actions;

  /// Answers a question, on the machine that asked it.
  final void Function(Tile tile, Prompt prompt, {required bool allow}) onDecide;

  /// Opens the gate for the work's project.
  final void Function(Tile tile) onReview;

  /// Puts away the outcome of a question, on the machine that asked it. No button without it.
  final void Function(Tile tile, Prompt prompt)? onPutAway;

  /// Whether its work is the one selected.
  final bool selected;

  /// Selects its work.
  final VoidCallback? onSelect;

  /// Opens its work over the frame.
  final VoidCallback? onOpen;

  /// The command the finder went to.
  final String? highlight;

  /// Called once the menu opened on [highlight].
  final VoidCallback? onShown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final task = tile.task;
    final urgent = tile.demand == Demand.question;
    final first = tile.questions.isEmpty ? null : tile.questions.first;
    final answering = first != null && tile.fleet.clearance.answering(first);
    // Nothing on a machine that is not answering can be told anything.
    final answers = tile.fleet.reachability == Reachability.connected;
    final aboutTheDeadline = first == null ? null : _deadlineLine(first);
    // The tile's button and its menu run the same command, so they cannot disagree about it.
    final session = actions
        .where((command) => command.id == 'work.session')
        .firstOrNull;

    final card = SizedBox(
      width: 320,
      child: GestureDetector(
        onSecondaryTapDown: actions.isEmpty
            ? null
            : (details) =>
                  showCommandMenu(context, details.globalPosition, actions),
        child: Card(
          key: ValueKey<String>(
            'tile ${tile.machine.name} ${task?.name ?? first?.task ?? ''}',
          ),
          color: urgent ? scheme.errorContainer : null,
          shape: selected
              ? RoundedRectangleBorder(
                  side: BorderSide(color: scheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(Radii.medium),
                )
              : null,
          child: InkWell(
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.all(Space.normal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Two machines can serve the same socket path, and only the name tells them apart.
                  Text(
                    tile.machine.name,
                    key: const Key('tile-machine'),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _headline(tile),
                          key: const Key('tile-headline'),
                          style: text.titleSmall,
                        ),
                      ),
                      if (onOpen != null && task != null)
                        IconButton(
                          key: const Key('tile-open'),
                          icon: const Icon(
                            Icons.chevron_right,
                            size: Sizes.rowIcon,
                          ),
                          tooltip: 'Open ${task.name}',
                          visualDensity: VisualDensity.compact,
                          onPressed: onOpen,
                        ),
                      if (actions.isNotEmpty)
                        CommandMenu(
                          key: const Key('tile-menu'),
                          commands: actions,
                          tooltip:
                              'What ${task?.name ?? 'this'} can be told to do',
                          highlight: highlight,
                          onShown: onShown,
                        ),
                    ],
                  ),
                  if (tile.inferred)
                    Text(
                      'a guess, not a question',
                      key: const Key('tile-inferred'),
                      style: text.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (aboutTheDeadline != null)
                    Text(
                      aboutTheDeadline,
                      key: const Key('tile-deadline'),
                      style: text.bodySmall,
                    ),
                  // What was attempted and which rule stopped it: a destination alone does not say
                  // whose it was, and five tasks can be asking at once.
                  if (first != null) ...<Widget>[
                    Text(
                      first.shown,
                      key: const Key('blocked-destination'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${first.protocol}${first.prefix.isEmpty ? '' : ' · stopped by ${first.prefix}'}',
                      style: text.bodySmall,
                    ),
                    if (tile.fleet.clearance.askedBefore(first))
                      Text(
                        'This was let through before. A decision is remembered per address, so a '
                        'host that answers on several addresses asks again for each one.',
                        key: const Key('asked-before'),
                        style: text.bodySmall,
                      ),
                  ],
                  const SizedBox(height: Space.small),
                  // Selectable, because the name is what somebody types into `sokar` on the machine.
                  if (task != null || first != null)
                    SelectableText(
                      task == null
                          ? first!.task
                          : (task.label.isEmpty ? task.name : task.label),
                      key: const Key('tile-what'),
                    ),
                  if (task != null && task.label.isNotEmpty)
                    SelectableText(
                      task.name,
                      key: const Key('tile-name'),
                      style: text.bodySmall,
                    ),
                  Text(
                    _where(tile),
                    key: const Key('tile-where'),
                    style: text.bodySmall,
                  ),
                  // Said here as well: the status line is easy to miss from a tile.
                  if (task != null && tile.fleet.saidAbout(task.name) != null)
                    Text(
                      tile.fleet.saidAbout(task.name)!,
                      key: const Key('tile-said'),
                      style: text.bodySmall,
                    ),
                  if (task != null &&
                      task.activity == Activity.waiting &&
                      task.waitingFor.isNotEmpty)
                    Text(
                      'waiting on ${task.waitingFor}',
                      key: const Key('waiting-for'),
                      style: text.bodySmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // Nothing asks and nothing is refused for this one, and somebody chose that.
                  if (task != null && task.unenforced)
                    Tooltip(
                      message:
                          'Nothing is enforcing what this work may reach. '
                          'No connection will be refused and nothing will be asked.',
                      child: Chip(
                        key: const Key('unenforced'),
                        avatar: Icon(
                          Icons.gpp_bad_outlined,
                          size: Sizes.rowIcon,
                          color: scheme.onErrorContainer,
                        ),
                        label: const Text('unenforced'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: scheme.errorContainer,
                      ),
                    ),
                  // The last answer, so a question that ran out does not quietly disappear.
                  if (first == null && tile.settled != null)
                    Text(
                      _settledWords(tile.settled!),
                      key: const Key('tile-settled'),
                      style: text.bodySmall,
                    ),
                  // Until then it stays on what needs a person, so nobody misses it.
                  if (first == null && tile.settled != null && onPutAway != null)
                    TextButton(
                      key: const Key('tile-put-away'),
                      onPressed: () => onPutAway!(tile, tile.settled!),
                      child: const Text('Got it'),
                    ),
                  if (first != null ||
                      (session?.available ?? false) ||
                      (task?.hasWorkWaiting ?? false)) ...<Widget>[
                    const SizedBox(height: Space.small),
                    Wrap(
                      spacing: Space.small,
                      children: <Widget>[
                        if (first != null) ...<Widget>[
                          TextButton(
                            key: const Key('tile-let-through'),
                            onPressed: answering || !answers ? null : () => onDecide(tile, first, allow: true),
                            child: const Text('Let it through'),
                          ),
                          TextButton(
                            key: const Key('tile-keep-blocked'),
                            onPressed: answering || !answers ? null : () => onDecide(tile, first, allow: false),
                            child: const Text('Keep it blocked'),
                          ),
                        ],
                        if (session != null && session.available)
                          TextButton(
                            key: const Key('tile-attach'),
                            onPressed: session.run,
                            child: Text(session.label),
                          ),
                        if (task?.hasWorkWaiting ?? false)
                          TextButton(
                            key: const Key('tile-review'),
                            onPressed: answers ? () => onReview(tile) : null,
                            child: const Text('Review at the gate'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return selected
        ? KeyedSubtree(key: const Key('selected-row'), child: card)
        : card;
  }

  static String _settledWords(Prompt prompt) => prompt.expired
      ? '${prompt.shown} ran out — it stays blocked'
      : prompt.verdict == 'allow'
      ? '${prompt.shown} is now reachable — the attempt that was refused is gone'
      : '${prompt.shown} was kept blocked';

  static String _headline(Tile tile) {
    final task = tile.task;
    final since = task == null ? null : howLong(task);
    final forHowLong = since == null ? '' : ' for $since';
    return switch (tile.demand) {
      Demand.question when tile.questions.isNotEmpty => _question(
        tile.questions,
      ),
      Demand.question =>
        'Waiting on '
            '${(task?.waitingFor ?? '').isEmpty ? 'an answer' : task!.waitingFor}$forHowLong',
      Demand.gate => 'Its work waits for review',
      Demand.working => 'Working$forHowLong',
      Demand.quiet => 'Quiet$forHowLong',
      // Only that it runs: nothing here can see what it is doing, and nothing claims to.
      Demand.unseen => 'Running$forHowLong',
      Demand.stopped => 'Not running',
    };
  }

  /// Time left when the machine says when it runs out; how long it has waited when it does not.
  static String _question(List<Prompt> questions) {
    final first = questions.first;
    final more = questions.length - 1;
    final ends = first.expiresAt;
    final left = howLongUntil(ends);
    final since = howLongSince(DateTime.tryParse(first.at));
    final when = ends != null
        ? (left == null ? ' · out of time' : ' · $left left')
        : (since == null ? '' : ' · blocked for $since');
    return 'Asks to reach ${first.shown}${more > 0 ? ' and $more more' : ''}$when';
  }

  /// What to say about when it runs out, or null when the headline already says how long is left.
  static String? _deadlineLine(Prompt question) {
    if (question.neverRunsOut) return 'This one does not run out.';
    final ends = question.expiresAt;
    if (ends == null) {
      return 'The machine gives up on its own timeout, and does not say when.';
    }
    return howLongUntil(ends) == null
        ? 'Its time is up; the machine may already have given up on it.'
        : null;
  }

  static String _where(Tile tile) {
    final task = tile.task;
    final project = task == null ? null : tile.fleet.projectOf(task);
    // Named once there is more than one to tell apart; a project of one repository says nothing new.
    final repository = task == null || project == null || project.repositories.length < 2
        ? null
        : project.repositoryOf(task);
    return <String>[
      if (tile.machine.host.isNotEmpty) tile.machine.host,
      if (task != null && task.project.isNotEmpty) task.project,
      if (repository != null) 'in $repository',
      if (task != null && task.agent.isNotEmpty) task.agent,
    ].join(' · ');
  }
}
