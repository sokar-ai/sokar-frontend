import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/agent_inventory.dart';
import 'panes.dart';
import 'tokens.dart';

/// What agents are installed on this machine, and what each may reach.
///
/// It never names an agent this build knows about: the list is whatever the machine answered.
///
/// **Shadowing is not shown, because it is not answered.** A copy of an agent shadowed by one in a
/// more specific directory never reaches this list — the daemon resolves it first and answers one
/// entry per name — and which copy lost is not on the wire. An earlier version of this view
/// detected duplicate names and marked them, which was a state the contract cannot produce; the
/// fixtures had been made to produce it, which is how it survived being tested.
class AgentsView extends StatelessWidget {
  /// Constructor taking the inventory and how to close it.
  const AgentsView({required this.inventory, required this.onClose, super.key});

  /// What the machine answered.
  final AgentInventory inventory;

  /// Closes the view.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        PaneHeader(
          title: 'Agents installed here',
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close (Esc)',
            onPressed: onClose,
          ),
        ),
        if (inventory.problem != null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(Space.normal),
            child: Text(inventory.problem!, key: const Key('agents-problem')),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Space.small),
            children: <Widget>[
              if (inventory.busy)
                const Padding(
                  padding: EdgeInsets.all(Space.normal),
                  child: Text('Asking the machine what it has…'),
                )
              else if (inventory.agents.isEmpty && inventory.failures.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(Space.normal),
                  child: Text(
                    'None is installed. That is a state, not a failure — an agent is installed '
                    'separately from the thing that runs it.',
                    key: Key('no-agents'),
                  ),
                ),
              for (final agent in inventory.agents) _AgentRow(agent: agent),
              if (inventory.failures.isNotEmpty) ...<Widget>[
                const _Heading(words: 'Installed and unusable'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Space.normal, 0, Space.normal, Space.small),
                  child: Text(
                    'These are here and could not be asked what they are. Listed rather than '
                    'left out: absent is the state nobody goes looking for.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final failure in inventory.failures.entries)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.error_outline,
                        size: Sizes.mark, color: Theme.of(context).colorScheme.error),
                    title: Text(failure.key,
                        key: const Key('agent-failure'),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    subtitle: Text(failure.value),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One installed agent, with what it may reach.
class _AgentRow extends StatelessWidget {
  const _AgentRow({required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        leading: const Icon(Icons.smart_toy_outlined, size: Sizes.mark),
        title: Text(agent.label.isEmpty ? agent.name : agent.label),
        subtitle: Text(agent.version.isEmpty
            ? '${agent.name} · version not reported'
            : '${agent.name} · ${agent.version}'),
        children: <Widget>[
          _Field(name: 'Found at', value: agent.from),
          _Field(name: 'Runs', value: agent.binary),
          const _Heading(words: 'Hosts it needs'),
          if (agent.allowedDomains.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  Space.normal, 0, Space.normal, Space.small),
              child: Text('None of its own. It reaches whatever the project allows.'),
            ),
          for (final host in agent.allowedDomains)
            ListTile(
              dense: true,
              title: Text(host,
                  key: const Key('agent-host'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.normal, 0, Space.normal, Space.normal),
            child: Text(
              'Added to a task\'s egress on top of the project\'s own. What a project asks for '
              'and is deliberately refused is shown where that project is configured, not here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
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

class _Field extends StatelessWidget {
  const _Field({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.normal, vertical: Space.tight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 110,
              child: Text(name, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
      );
}
