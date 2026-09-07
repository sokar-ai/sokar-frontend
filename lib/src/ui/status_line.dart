import 'package:flutter/material.dart';

import '../app/fleet_model.dart';

/// One line across the bottom saying what just happened, and to which machine.
///
/// The words stay put while something else runs: a status line that is replaced by a spinner
/// answers "is it busy" and forgets "did the last thing work", which is the question somebody
/// coming back to the window actually has.
class StatusLine extends StatelessWidget {
  /// Constructor taking the fleet whose state it reports.
  const StatusLine({required this.fleet, super.key});

  /// What is being talked to.
  final FleetModel fleet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = fleet.info;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 2,
          child: fleet.busy ? const LinearProgressIndicator(minHeight: 2) : null,
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: <Widget>[
              _Reachability(reachability: fleet.reachability),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fleet.status,
                  key: const Key('status-line'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (fleet.reachability == Reachability.connected && !fleet.liveUpdates)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('not live', style: theme.textTheme.bodySmall),
                ),
              if (info != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
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
      child: Icon(icon, size: 16, color: colour),
    );
  }
}
