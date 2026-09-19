import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/egress.dart';
import 'panes.dart';
import 'tokens.dart';

/// What a project's work may reach, and the changing of it.
///
/// The most consequential edit in the product: nothing here writes until what it would do has been
/// shown and agreed to. A set is a name for several hosts — adding one opens eleven — and whoever
/// presses the button is entitled to see them.
class EgressView extends StatelessWidget {
  /// Constructor taking the egress and what can be done to it.
  const EgressView({
    required this.egress,
    required this.onConsider,
    required this.onApply,
    required this.onLetItBe,
    required this.onClose,
    super.key,
  });

  /// What the project may reach, and what is being considered.
  final Egress egress;

  /// Works out what adding or removing a set would do.
  final void Function({List<String>? addSets, List<String>? removeSets}) onConsider;

  /// Makes the change that was previewed.
  final VoidCallback onApply;

  /// Puts a preview or a result away.
  final VoidCallback onLetItBe;

  /// Closes the view.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final using = <String>{
      for (final host in egress.reachable)
        if (host.origin.startsWith('set ')) host.origin.substring(4),
    };

    return Column(
      children: <Widget>[
        PaneHeader(
          title: egress.repository == null
              ? 'What ${egress.project?.name ?? ''} may reach'
              : 'What ${egress.project?.name ?? ''} · ${egress.repository} may reach',
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close (Esc)',
            onPressed: onClose,
          ),
        ),
        if (egress.problem != null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(Space.normal),
            child: Text(egress.problem!, key: const Key('egress-problem')),
          ),
        if (egress.preview != null || egress.applied != null)
          _WhatItWouldDo(
            change: (egress.preview ?? egress.applied)!,
            previewing: egress.preview != null,
            onApply: onApply,
            onLetItBe: onLetItBe,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Space.small),
            children: <Widget>[
              _Heading(words: 'Reachable now'),
              if (egress.repository case final repository?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.normal, 0, Space.normal, Space.small),
                  child: Text(
                    'What every repository of ${egress.project?.name ?? ''} may reach, and what '
                    '$repository adds to it. A repository only ever adds: nothing here can take '
                    'away what the project grants. A change is written into $repository\'s own '
                    'block.',
                    key: const Key('what-a-repository-adds'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              // In the order the sources granted them: the first grant wins, so the order is what
              // says where a host came from. Sorting would destroy the answer.
              for (final host in egress.reachable)
                _Reachable(host: host, added: egress.addedByTheRepository(host)),
              if (egress.refused.isNotEmpty) ...<Widget>[
                _Heading(words: 'Asked for and refused'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Space.normal, 0, Space.normal, Space.small),
                  child: Text(
                    'The agent wants these and is deliberately not given them. A dropped packet '
                    'cannot tell that apart from nobody having added it.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final host in egress.refused) _Refused(host: host),
              ],
              _Heading(words: 'Sets installed on this machine'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Space.normal, 0, Space.normal, Space.small),
                child: Text(
                  'Chosen one at a time, and deliberately: there is no "all sets, including '
                  'ones installed later". A set shipped in a later release would widen this '
                  'project without anybody editing it.',
                  key: const Key('why-no-open-ended-sets'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (egress.sets.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(Space.normal),
                  child: Text('None is installed. That is a state, not a failure.'),
                ),
              for (final set in egress.sets)
                _SetRow(
                  set: set,
                  inUse: using.contains(set.name),
                  onAdd: () => onConsider(addSets: <String>[set.name]),
                  onRemove: () => onConsider(removeSets: <String>[set.name]),
                ),
              if (egress.locations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(Space.normal),
                  child: Text(
                    'Searched, most specific first: ${egress.locations.join(', ')}. '
                    'A set an operator drops into their own directory wins over a packaged one '
                    'of the same name, which is why the same name can behave differently on two '
                    'machines.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What a change would do, before it is made — or what it did.
class _WhatItWouldDo extends StatelessWidget {
  const _WhatItWouldDo({
    required this.change,
    required this.previewing,
    required this.onApply,
    required this.onLetItBe,
  });

  final EgressChange change;
  final bool previewing;
  final VoidCallback onApply;
  final VoidCallback onLetItBe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final refused = !previewing && !change.outcome.wrote;

    return Container(
      width: double.infinity,
      color: refused ? scheme.errorContainer : scheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(Space.normal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            previewing ? 'This is what it would do' : change.outcome.label,
            key: const Key('what-it-would-do'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (change.detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.tight),
            Text(change.detail, key: const Key('egress-detail')),
          ],
          // Usually empty, and it matters when it is not: filled only when *this* change makes a
          // forge reachable for a guarded project, and never repeated on a later edit — a warning
          // shown when nothing changed is one people learn to skip.
          if (change.cost.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.normal),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.normal),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(Radii.small),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.warning_amber_outlined, color: scheme.onErrorContainer),
                  const SizedBox(width: Space.small),
                  Expanded(child: Text(change.cost, key: const Key('egress-cost'))),
                ],
              ),
            ),
          ],
          if (change.opens.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.normal),
            Text('Opens ${change.opens.length} host'
                '${change.opens.length == 1 ? '' : 's'}'),
            for (final host in change.opens)
              _Line(host: host, opening: true),
          ],
          if (change.closes.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.normal),
            Text('Closes ${change.closes.length} host'
                '${change.closes.length == 1 ? '' : 's'}'),
            for (final host in change.closes)
              _Line(host: host, opening: false),
          ],
          const SizedBox(height: Space.normal),
          if (previewing)
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: onLetItBe,
                  child: const Text('Leave it as it is'),
                ),
                const SizedBox(width: Space.small),
                FilledButton(
                  onPressed: onApply,
                  child: const Text('Make this change'),
                ),
              ],
            )
          else ...<Widget>[
            // A container's ruleset is built when it starts, so nothing here reaches work that is
            // already running. Saying otherwise would be the most expensive kind of wrong.
            if (change.outcome.wrote)
              Text('This applies to the next task. Work already running keeps the ruleset it '
                  'started with.'),
            const SizedBox(height: Space.small),
            OutlinedButton(onPressed: onLetItBe, child: const Text('Right')),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.host, required this.opening});

  final EgressHost host;
  final bool opening;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: Space.normal, top: Space.tight),
        child: Text(
          '${opening ? '+' : '−'} ${host.host}   ${host.origin}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.words});

  final String words;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Space.normal, Space.wide, Space.normal, Space.small),
        child: Text(words, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _Reachable extends StatelessWidget {
  const _Reachable({required this.host, this.added = false});

  final EgressHost host;

  /// Whether the repository being looked at adds it, rather than every repository getting it.
  final bool added;

  @override
  Widget build(BuildContext context) => ListTile(
        key: added ? ValueKey<String>('added ${host.host}') : null,
        dense: true,
        leading: added
            ? Icon(Icons.add_circle_outline,
                size: Sizes.rowIcon, color: Theme.of(context).colorScheme.tertiary)
            : null,
        title: Text(host.host,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        trailing: Text(added ? 'added by this repository' : host.origin,
            style: Theme.of(context).textTheme.bodySmall),
      );
}

class _Refused extends StatelessWidget {
  const _Refused({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(Icons.block,
            size: Sizes.mark, color: Theme.of(context).colorScheme.error),
        title: Text(host,
            key: const Key('refused-host'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      );
}

/// One installed set, with the hosts it grants.
///
/// The domains are shown because a set exists so nobody authors host lists by hand, and that only
/// works if a person can see what the name means.
class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.inUse,
    required this.onAdd,
    required this.onRemove,
  });

  final EgressSet set;
  final bool inUse;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        leading: Icon(inUse ? Icons.check_circle_outline : Icons.circle_outlined,
            size: Sizes.mark),
        title: Text(set.label),
        subtitle: Text('${set.name} · ${set.domains.length} hosts'),
        trailing: inUse
            ? OutlinedButton(onPressed: onRemove, child: const Text('Remove'))
            : FilledButton(onPressed: onAdd, child: const Text('Add')),
        children: <Widget>[
          for (final domain in set.domains)
            ListTile(
              dense: true,
              title: Text(domain,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
        ],
      );
}
