import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/start_work.dart';
import 'tokens.dart';

/// Starts work: a project, an agent, a way of being involved, and what to ask for.
///
/// The mode is the decision here. It is what says whether anybody is going to be there, and it
/// governs the rest of the form: a prompt belongs to an unattended run and to nothing else,
/// because the backend would accept `SHELL` with a prompt and record it — a run nobody is
/// attached to, described as one somebody is driving.
Future<bool> openStartWork(
  BuildContext context, {
  required StartWork starting,
  required VoidCallback onStart,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => StartWorkDialog(starting: starting, onStart: onStart),
    ) ??
    false;

/// The dialog itself, separated so it can be built directly in a test.
class StartWorkDialog extends StatefulWidget {
  /// Constructor taking the model and what to do with it.
  const StartWorkDialog({required this.starting, required this.onStart, super.key});

  /// What is being started.
  final StartWork starting;

  /// Starts it.
  final VoidCallback onStart;

  @override
  State<StartWorkDialog> createState() => _StartWorkDialogState();
}

class _StartWorkDialogState extends State<StartWorkDialog> {
  late final TextEditingController _prompt =
      TextEditingController(text: widget.starting.prompt);

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.starting,
        builder: (context, _) {
          final starting = widget.starting;
          final continuing = starting.continuing;

          return AlertDialog(
            title: Text(continuing == null
                ? 'Start work in ${starting.project?.name ?? ''}'
                : 'Continue ${continuing.name}'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (continuing != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.normal),
                        child: Text(
                          'What it was asked to do last time is below. Continuing means asking '
                          'for something more, so it is here to be edited rather than sent as '
                          'it stands.',
                          key: const Key('start-continuing'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (starting.problem != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.normal),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Space.normal),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(Radii.small),
                          ),
                          child: Text(starting.problem!,
                              key: const Key('start-problem')),
                        ),
                      ),
                    TextField(
                      key: const Key('start-name'),
                      decoration: const InputDecoration(
                        labelText: 'What to call it',
                        border: OutlineInputBorder(),
                        helperText: 'Optional. Left empty, the machine names it.',
                      ),
                      onChanged: starting.callIt,
                    ),
                    const SizedBox(height: Space.wide),
                    Text('Which agent', style: Theme.of(context).textTheme.labelLarge),
                    if (starting.busy)
                      const Padding(
                        padding: EdgeInsets.all(Space.normal),
                        child: Text('Asking the machine what it has…'),
                      )
                    else if (starting.agents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: Space.small),
                        child: Text(
                          'None is installed on this machine. That is a state, not a failure, '
                          'and nothing can be started until one is.',
                          key: Key('start-no-agents'),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        key: const Key('start-agent'),
                        initialValue: starting.agent,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: <DropdownMenuItem<String>>[
                          for (final agent in starting.agents)
                            DropdownMenuItem<String>(
                              value: agent.name,
                              child: Text(agent.version.isEmpty
                                  ? agent.label
                                  : '${agent.label} · ${agent.version}'),
                            ),
                        ],
                        onChanged: (chosen) =>
                            chosen == null ? null : starting.chooseAgent(chosen),
                      ),
                    // Shown, never dropped: an agent missing from a list looks exactly like one
                    // that was never installed, and only one of those is worth fixing.
                    for (final failure in starting.failures.entries)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.tight),
                        child: Text('${failure.key} could not be read: ${failure.value}',
                            key: const Key('start-agent-failure'),
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    const SizedBox(height: Space.wide),
                    Text('How you are involved',
                        style: Theme.of(context).textTheme.labelLarge),
                    _WhichMode(starting: starting),
                    const SizedBox(height: Space.normal),
                    TextField(
                      key: const Key('start-prompt'),
                      controller: _prompt,
                      enabled: starting.takesAPrompt,
                      maxLines: 4,
                      minLines: 2,
                      decoration: InputDecoration(
                        labelText: 'What to ask it to do',
                        border: const OutlineInputBorder(),
                        helperText: starting.takesAPrompt
                            ? 'It runs on its own until this is done or its time is up.'
                            : 'Only an unattended run is given a prompt. The other two are '
                                'driven by a person, and a prompt would say otherwise.',
                      ),
                      onChanged: starting.ask,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                key: const Key('start-go'),
                onPressed: starting.ready
                    ? () {
                        widget.onStart();
                        Navigator.of(context).pop(true);
                      }
                    : null,
                child: Text(continuing == null ? 'Start it' : 'Continue it'),
              ),
            ],
          );
        },
      );
}

/// The three ways of being involved, with nothing chosen until somebody chooses.
class _WhichMode extends StatelessWidget {
  const _WhichMode({required this.starting});

  final StartWork starting;

  @override
  Widget build(BuildContext context) => RadioGroup<Mode>(
        // `Start` would default this — `UNATTENDED` with a prompt, `SHELL` without. Not relied
        // on: F08 asks for work started *with* a mode, and a screen that picked one quietly
        // would be deciding whether anybody is going to be there.
        groupValue: starting.mode,
        onChanged: (chosen) => chosen == null ? null : starting.chooseMode(chosen),
        child: const Column(
          children: <Widget>[
            RadioListTile<Mode>(
              key: Key('start-mode-shell'),
              value: Mode.shell,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('A shell, driven by hand'),
              subtitle: Text('A terminal in the container. Nothing runs until you run it.'),
            ),
            RadioListTile<Mode>(
              key: Key('start-mode-agent'),
              value: Mode.agent,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('An agent session, worked through'),
              subtitle: Text("The agent's own session, with you in it."),
            ),
            RadioListTile<Mode>(
              key: Key('start-mode-unattended'),
              value: Mode.unattended,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('Unattended, against a prompt'),
              subtitle: Text('It runs on its own. Nobody is expected to be watching.'),
            ),
          ],
        ),
      );
}
