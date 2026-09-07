import 'package:flutter/material.dart';

import '../app/fleet_model.dart';
import '../app/operations.dart';
import 'tokens.dart';

/// One line across the bottom saying what just happened, and to which machine.
///
/// The words stay put while something else runs: a status line that is replaced by a spinner
/// answers "is it busy" and forgets "did the last thing work", which is the question somebody
/// coming back to the window actually has.
class StatusLine extends StatelessWidget {
  /// Constructor taking what it reports on and the way into the record.
  const StatusLine({
    required this.fleet,
    required this.operations,
    required this.onShowOperations,
    super.key,
  });

  /// What is being talked to.
  final FleetModel fleet;

  /// What this session has run.
  final Operations operations;

  /// Opens the record.
  final VoidCallback onShowOperations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = fleet.info;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 2,
          child: fleet.busy || operations.running > 0
              ? const LinearProgressIndicator(minHeight: 2)
              : null,
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.normal,
            vertical: Space.tight,
          ),
          child: Row(
            children: <Widget>[
              _Reachability(reachability: fleet.reachability),
              const SizedBox(width: Space.small),
              Expanded(
                child: Text(
                  fleet.status,
                  key: const Key('status-line'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              _Operations(
                operations: operations,
                onShow: onShowOperations,
              ),
              if (fleet.reachability == Reachability.connected && !fleet.liveUpdates)
                Padding(
                  padding: const EdgeInsets.only(left: Space.small),
                  child: Text('not live', style: theme.textTheme.bodySmall),
                ),
              if (info != null)
                Padding(
                  padding: const EdgeInsets.only(left: Space.small),
                  // The daemon's build version, for a bug report. Never for gating a feature.
                  child: Text(
                    '${fleet.backend.label} · ${info.version}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Reachability extends StatelessWidget {
  const _Reachability({required this.reachability});

  final Reachability reachability;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color colour, String words) = switch (reachability) {
      Reachability.connecting => (Icons.cloud_queue, scheme.outline, 'Connecting'),
      Reachability.connected => (Icons.cloud_done, scheme.primary, 'Connected'),
      Reachability.unreachable => (Icons.cloud_off, scheme.error, 'Not connected'),
      Reachability.incompatible => (Icons.report, scheme.error, 'Incompatible backend'),
    };
    return Tooltip(
      message: words,
      child: Icon(icon, size: Sizes.mark, color: colour),
    );
  }
}

/// How much this session has run, and the way into it.
///
/// A count rather than the newest line: output belongs in the operation's own view, and a status
/// line that scrolled a build would bury the outcome of the last action under it.
class _Operations extends StatelessWidget {
  const _Operations({required this.operations, required this.onShow});

  final Operations operations;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final all = operations.all;
    if (all.isEmpty) return const SizedBox.shrink();
    final running = operations.running;
    final failed = all.where((operation) => operation.failed).length;
    return TextButton(
      key: const Key('operations-indicator'),
      onPressed: onShow,
      child: Text(
        running > 0
            ? '$running running'
            : failed > 0
                ? '${all.length} run, $failed failed'
                : '${all.length} run',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
