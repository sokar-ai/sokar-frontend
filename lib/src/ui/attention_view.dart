import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/attention.dart';
import '../app/fleet_model.dart';
import 'how_long.dart';
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
    required this.onAttach,
    required this.onReview,
    super.key,
  });

  /// Every tile, most urgent first.
  final Attention attention;

  /// Answers a question, on the machine that asked it.
  final void Function(Tile tile, Prompt prompt, {required bool allow}) onDecide;

  /// Opens a session in the work.
  final void Function(Tile tile) onAttach;

  /// Opens the gate for the work's project.
  final void Function(Tile tile) onReview;

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
          final tiles = widget.attention.tiles;
          final needing = widget.attention.needingSomebody;
          _keepTicking(
              tiles.any((tile) => tile.questions.any((question) => question.expiresAt != null)));
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
                child: tiles.isEmpty
                    ? const Center(
                        child: Text('No machine has any work on it.', key: Key('no-work-anywhere')),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(Space.normal),
                        child: Wrap(
                          spacing: Space.normal,
                          runSpacing: Space.normal,
                          children: <Widget>[
                            for (final tile in tiles)
                              _TileCard(
                                tile: tile,
                                onDecide: widget.onDecide,
                                onAttach: widget.onAttach,
                                onReview: widget.onReview,
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

/// One tile. Its state is legible without opening it, and it carries its own actions.
class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.tile,
    required this.onDecide,
    required this.onAttach,
    required this.onReview,
  });

  final Tile tile;
  final void Function(Tile tile, Prompt prompt, {required bool allow}) onDecide;
  final void Function(Tile tile) onAttach;
  final void Function(Tile tile) onReview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final task = tile.task;
    final urgent = tile.demand == Demand.question || tile.demand == Demand.unreachable;
    final first = tile.questions.isEmpty ? null : tile.questions.first;
    final answering = first != null && tile.fleet.clearance.answering(first);
    final aboutTheDeadline = first == null ? null : _deadlineLine(first);

    return SizedBox(
      width: 320,
      child: Card(
        key: ValueKey<String>('tile ${tile.machine.name} ${task?.name ?? first?.task ?? ''}'),
        color: urgent ? scheme.errorContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(Space.normal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_headline(tile), key: const Key('tile-headline'), style: text.titleSmall),
              if (tile.inferred)
                Text(
                  'a guess, not a question',
                  key: const Key('tile-inferred'),
                  style: text.labelSmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              if (aboutTheDeadline != null)
                Text(aboutTheDeadline, key: const Key('tile-deadline'), style: text.bodySmall),
              const SizedBox(height: Space.small),
              if (task != null || first != null)
                Text(
                  task == null ? first!.task : (task.label.isEmpty ? task.name : task.label),
                  key: const Key('tile-what'),
                ),
              Text(_where(tile), key: const Key('tile-where'), style: text.bodySmall),
              if (first != null ||
                  (task?.running ?? false) ||
                  (task?.hasWorkWaiting ?? false)) ...<Widget>[
                const SizedBox(height: Space.small),
                Wrap(
                  spacing: Space.small,
                  children: <Widget>[
                    if (first != null) ...<Widget>[
                      TextButton(
                        key: const Key('tile-let-through'),
                        onPressed: answering ? null : () => onDecide(tile, first, allow: true),
                        child: const Text('Let it through'),
                      ),
                      TextButton(
                        key: const Key('tile-keep-blocked'),
                        onPressed: answering ? null : () => onDecide(tile, first, allow: false),
                        child: const Text('Keep it blocked'),
                      ),
                    ],
                    if (task?.running ?? false)
                      TextButton(
                        key: const Key('tile-attach'),
                        onPressed: () => onAttach(tile),
                        child: const Text('Work in it by hand'),
                      ),
                    if (task?.hasWorkWaiting ?? false)
                      TextButton(
                        key: const Key('tile-review'),
                        onPressed: () => onReview(tile),
                        child: const Text('Review at the gate'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _headline(Tile tile) {
    final task = tile.task;
    final since = task == null ? null : howLong(task);
    final forHowLong = since == null ? '' : ' for $since';
    return switch (tile.demand) {
      Demand.question when tile.questions.isNotEmpty => _question(tile.questions),
      Demand.question => 'Waiting on '
          '${(task?.waitingFor ?? '').isEmpty ? 'an answer' : task!.waitingFor}$forHowLong',
      Demand.unreachable => switch (tile.fleet.reachability) {
          Reachability.connecting => 'Still connecting, so nothing is known yet',
          Reachability.incompatible => 'Serves nothing this build understands',
          _ => 'Cannot be reached',
        },
      Demand.gate => 'Its work waits for review',
      Demand.working => 'Working$forHowLong',
      Demand.quiet => 'Quiet$forHowLong',
      Demand.unseen => 'Cannot be seen from here',
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
    if (ends == null) return 'The machine gives up on its own timeout, and does not say when.';
    return howLongUntil(ends) == null
        ? 'Its time is up; the machine may already have given up on it.'
        : null;
  }

  static String _where(Tile tile) {
    final task = tile.task;
    return <String>[
      tile.machine.name,
      if (task != null && task.project.isNotEmpty) task.project,
      if (task != null && task.agent.isNotEmpty) task.agent,
      if (tile.demand == Demand.unreachable && tile.fleet.status.isNotEmpty) tile.fleet.status,
    ].join(' · ');
  }
}
