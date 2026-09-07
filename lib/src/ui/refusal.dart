import 'package:flutter/material.dart';

import '../app/fleet_model.dart';
import 'tokens.dart';

/// What `Stop` refused to do, and the choice about it.
///
/// A pane rather than a toast or a dialog, and it takes the place of whatever was open: the
/// refusal *is* the product working, and it is the most important thing on the screen until
/// somebody has decided about it.
///
/// **Nothing here is a "force" button that quietly discards work.** Each way out says what it
/// does to what is held, and leaving it alone is one of them.
class RefusalView extends StatelessWidget {
  /// Constructor taking the refusal and the ways out of it.
  const RefusalView({required this.refusal, required this.fleet, super.key});

  /// What was refused, and what it said.
  final Refusal refusal;

  /// What the choice acts on.
  final FleetModel fleet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final task = refusal.task;

    return Container(
      color: scheme.errorContainer,
      padding: const EdgeInsets.all(Space.wide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.pan_tool, color: scheme.onErrorContainer),
              const SizedBox(width: Space.small),
              Expanded(
                child: Text(
                  '$task was not removed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.normal),
          Text(
            refusal.holdsWork
                ? 'It holds work that never reached the gate. It has been left exactly as it '
                    'was, and nothing has been discarded.'
                : 'Nothing could say whether it holds any work, so it has been left exactly as '
                    'it was.',
          ),
          if (refusal.result.work.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.normal),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.normal),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(Radii.small),
              ),
              child: SelectableText(
                refusal.result.work,
                key: const Key('what-is-held'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: Space.loose),
          Wrap(
            spacing: Space.small,
            runSpacing: Space.small,
            children: <Widget>[
              // Leaving it alone is first and is the plain button: it is the answer that destroys
              // nothing, and it should be the easiest one to give.
              FilledButton(
                onPressed: fleet.letItBe,
                child: const Text('Leave it alone'),
              ),
              if (refusal.holdsWork)
                OutlinedButton(
                  onPressed: () => fleet.stopWork(task, rescue: true),
                  child: const Text('Push what it holds to the mirror, then remove it'),
                ),
              if (refusal.holdsWork)
                OutlinedButton(
                  onPressed: () => fleet.stopWork(task, purge: true),
                  child: const Text('Discard what it holds and remove it'),
                ),
              if (refusal.nothingKnows)
                OutlinedButton(
                  onPressed: () => fleet.stopWork(task, force: true),
                  child: const Text('Remove it anyway, without knowing'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks before stopping, naming what goes with it.
///
/// What is named here is only what this side knows: the container and the helpers beside it. What
/// the task *holds* is the daemon's answer, and it arrives as a refusal rather than as a guess
/// made in a dialog.
Future<bool> confirmStop(
  BuildContext context, {
  required String task,
  required int helpers,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stop $task and remove it?'),
        content: Text(
          'The container goes, and so do the '
          '${helpers == 1 ? 'helper' : '$helpers helpers'} beside it. '
          'Whatever the agent installed inside it — packages, caches, anything it built — goes '
          'with it and exists nowhere else.\n\n'
          'Work it holds that never reached the gate will stop this, and say so, rather than '
          'being destroyed.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop and remove'),
          ),
        ],
      ),
    ) ??
    false;
