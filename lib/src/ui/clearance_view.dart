import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/clearance.dart';
import 'panes.dart';
import 'tokens.dart';

/// Every blocked connection on this machine, in one view.
///
/// One view rather than one per piece of work: several tasks can be waiting at once, and a person
/// watching five windows is a person who misses the sixth. Each row says what was attempted, by
/// which work, and which rule stopped it.
class ClearanceView extends StatelessWidget {
  /// Constructor taking what is waiting and how to answer it.
  const ClearanceView({
    required this.clearance,
    required this.onDecide,
    super.key,
  });

  /// What is waiting, and what has been settled.
  final Clearance clearance;

  /// Answers one.
  final void Function(Prompt prompt, {required bool allow}) onDecide;

  @override
  Widget build(BuildContext context) {
    final waiting = clearance.waiting;
    final settled = clearance.settled;

    return Column(
      children: <Widget>[
        PaneHeader(
          title: 'Blocked connections',
          trailing: waiting.isEmpty
              ? null
              : Text('${waiting.length} waiting',
                  style: Theme.of(context).textTheme.labelMedium),
        ),
        if (clearance.problem != null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(Space.normal),
            child: Text(clearance.problem!, key: const Key('clearance-problem')),
          ),
        Expanded(
          child: waiting.isEmpty && settled.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(Space.loose),
                    child: Text(
                      'Nothing has been blocked. Work that asks for something it may not '
                      'reach turns up here, and waits.',
                    ),
                  ),
                )
              : ListView(
                  children: <Widget>[
                    for (final prompt in waiting)
                      _Asking(
                        prompt: prompt,
                        answering: clearance.answering(prompt),
                        askedBefore: clearance.askedBefore(prompt),
                        onDecide: onDecide,
                      ),
                    if (settled.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Space.normal, Space.wide, Space.normal, Space.small),
                        child: Text('Already settled',
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                    for (final prompt in settled) _Settled(prompt: prompt),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Asking extends StatelessWidget {
  const _Asking({
    required this.prompt,
    required this.answering,
    required this.askedBefore,
    required this.onDecide,
  });

  final Prompt prompt;
  final bool answering;
  final bool askedBefore;
  final void Function(Prompt prompt, {required bool allow}) onDecide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(Space.normal, Space.small, Space.normal, 0),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(Radii.medium),
      ),
      padding: const EdgeInsets.all(Space.normal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(prompt.shown,
              key: const Key('blocked-destination'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: Space.tight),
          Text(
            '${prompt.task} · ${prompt.protocol}'
            '${prompt.prefix.isEmpty ? '' : ' · stopped by ${prompt.prefix}'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (askedBefore) ...<Widget>[
            const SizedBox(height: Space.tight),
            Text(
              'This was let through before. A decision is remembered per address, so a host '
              'that answers on several addresses asks again for each one.',
              key: const Key('asked-before'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: Space.normal),
          if (answering)
            Text('Telling it…', style: Theme.of(context).textTheme.bodySmall)
          else
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => onDecide(prompt, allow: false),
                  child: const Text('Keep it blocked'),
                ),
                const SizedBox(width: Space.small),
                FilledButton(
                  onPressed: () => onDecide(prompt, allow: true),
                  child: const Text('Let it through'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Settled extends StatelessWidget {
  const _Settled({required this.prompt});

  final Prompt prompt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // An expired one is the case this whole field exists for: nothing asks about it again, so a
    // question that simply stopped arriving would be indistinguishable from one still waiting.
    // "This host is now reachable" and never "the request that just failed will now succeed":
    // the packet that was dropped is gone, and whether the work retries is the work's business.
    final (IconData icon, Color color, String what) = prompt.expired
        ? (Icons.timer_off_outlined, scheme.error, 'ran out — it stays blocked')
        : prompt.verdict == 'allow'
            ? (
                Icons.check_circle_outline,
                scheme.primary,
                'now reachable — the attempt that was refused is gone'
              )
            : (Icons.block, scheme.outline, 'kept blocked');

    return ListTile(
      dense: true,
      leading: Icon(icon, size: Sizes.mark, color: color),
      title: Text(prompt.shown,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      subtitle: Text('${prompt.task} · $what'),
    );
  }
}
