import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/start_work.dart';
import '../app/templates.dart';
import 'choice_field.dart';
import 'tokens.dart';
import 'dialog_scroll.dart';
import '../app/links.dart';

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
  required VoidCallback onKeep,
  Future<void> Function()? onStoreTheCredential,
  Future<void> Function(Agent agent)? onLogIn,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => StartWorkDialog(
          starting: starting,
          onStart: onStart,
          onKeep: onKeep,
          onStoreTheCredential: onStoreTheCredential,
          onLogIn: onLogIn),
    ) ??
    false;

/// The dialog itself, separated so it can be built directly in a test.
class StartWorkDialog extends StatefulWidget {
  /// Constructor taking the model and what to do with it.
  const StartWorkDialog({
    required this.starting,
    required this.onStart,
    required this.onKeep,
    this.onStoreTheCredential,
    this.onLogIn,
    super.key,
  });

  /// What is being started.
  final StartWork starting;

  /// Starts it.
  final VoidCallback onStart;

  /// Keeps what is on screen as a recurring job under the name that was typed.
  final VoidCallback onKeep;

  /// Stores the missing credential in a terminal on the machine, then asks again; null where
  /// nothing here reaches that machine.
  final Future<void> Function()? onStoreTheCredential;

  /// Runs the agent's own login in a terminal on the machine, then asks again; null likewise.
  final Future<void> Function(Agent agent)? onLogIn;

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
            title: Text(switch ((continuing, starting.from)) {
              (final Task task, _) => 'Continue ${task.name}',
              (_, final Template job) =>
                'Run ${job.name} in ${starting.project?.name ?? ''}',
              _ => 'Start work in ${starting.project?.name ?? ''}',
            }),
            content: SizedBox(
              width: 560,
              child: DialogScroll(
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
                      decoration: InputDecoration(
                        labelText: 'A name for this run',
                        border: const OutlineInputBorder(),
                        helperText: 'Optional. It names this piece of work and its container on the '
                            'machine; left empty, the machine picks one.',
                        errorText: starting.nameProblem,
                      ),
                      onChanged: starting.callIt,
                    ),
                    if (starting.needsARepository) ...<Widget>[
                      const SizedBox(height: Space.wide),
                      Text('Which repository', style: Theme.of(context).textTheme.labelLarge),
                      _WhichRepository(starting: starting),
                    ],
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
                    // Answered before anything is created, and shown before the button. Three of
                    // its outcomes are different actions — choose a provider, store a secret,
                    // unlock the vault — and sending somebody to the wrong one costs more than
                    // saying nothing would.
                    if (starting.readiness != null &&
                        !starting.readiness!.ready &&
                        !starting.readinessIsAboutTheName &&
                        !starting.readinessIsAboutTheRepository) ...<Widget>[
                      const SizedBox(height: Space.wide),
                      _NotReady(
                          starting: starting,
                          onStoreTheCredential: widget.onStoreTheCredential,
                          onLogIn: widget.onLogIn),
                    ],
                    const SizedBox(height: Space.wide),
                    _KeepAsTemplate(starting: starting, onKeep: widget.onKeep),
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

/// The project's repositories, the project's own first, with **none chosen** until somebody
/// chooses — not even when there is only one (Sokar B67, the operator's decision).
class _WhichRepository extends StatelessWidget {
  const _WhichRepository({required this.starting});

  final StartWork starting;

  @override
  Widget build(BuildContext context) {
    final project = starting.project!;
    return ChoiceField<String>(
      id: 'start-repository',
      label: 'Which repository',
      value: starting.repository,
      onChanged: (chosen) => chosen == null ? null : starting.chooseRepository(chosen),
      choices: <Choice<String>>[
        for (final name in project.repositories)
          Choice(name, name,
              id: 'start-repository-$name',
              means: name == project.name
                  ? "The project's own: its file, its planning, its issues."
                  : ''),
      ],
    );
  }
}

/// The three ways of being involved, with nothing chosen until somebody chooses.
class _WhichMode extends StatelessWidget {
  const _WhichMode({required this.starting});

  final StartWork starting;

  @override
  Widget build(BuildContext context) => ChoiceField<Mode>(
        // `Start` would default this — `UNATTENDED` with a prompt, `SHELL` without. Not relied
        // on: work is started *with* a mode, and a screen that picked one quietly
        // would be deciding whether anybody is going to be there.
        id: 'start-mode',
        label: 'How you take part',
        value: starting.mode,
        onChanged: (chosen) => chosen == null ? null : starting.chooseMode(chosen),
        choices: const <Choice<Mode>>[
          Choice(Mode.shell, 'A shell, driven by hand', id: 'start-mode-shell',
              means: 'A terminal in the container. Nothing runs until you run it.'),
          Choice(Mode.agent, 'An agent session, worked through', id: 'start-mode-agent',
              means: "The agent's own session, with you in it."),
          Choice(Mode.unattended, 'Unattended, against a prompt', id: 'start-mode-unattended',
              means: 'It runs on its own. Nobody is expected to be watching.'),
        ],
      );
}

/// Keeping what is on screen as a recurring job.
///
/// Deliberately at the bottom and deliberately small: a template is worth naming after the choices
/// have been made, not before. Nothing here can carry a setting the dialog above does not show,
/// which is what keeps a template from quietly widening what work may reach.
class _KeepAsTemplate extends StatefulWidget {
  const _KeepAsTemplate({required this.starting, required this.onKeep});

  final StartWork starting;
  final VoidCallback onKeep;

  @override
  State<_KeepAsTemplate> createState() => _KeepAsTemplateState();
}

class _KeepAsTemplateState extends State<_KeepAsTemplate> {
  late final TextEditingController _name =
      TextEditingController(text: widget.starting.templateName);
  bool _kept = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: TextField(
              key: const Key('template-name'),
              controller: _name,
              decoration: const InputDecoration(
                // **Not "a recurring job".** That wording reads as *recurring on its own*, and
                // it misled the backend into answering a question about schedules that nobody
                // asked — there is no scheduler, and a job kept here starts when somebody starts
                // it. Both facts a person would otherwise assume wrongly are said in the helper.
                labelText: 'Save these choices as a job, under a name',
                hintText: 'nightly-tests',
                border: OutlineInputBorder(),
                helperText: 'For starting the same again with one click: it keeps the repository, '
                    'the agent, the mode and the prompt — nothing else. It stays with you rather '
                    'than with the project, and nothing starts it but you. Not the name of this run.',
              ),
              onChanged: (typed) {
                widget.starting.callTheTemplate(typed);
                if (_kept) setState(() => _kept = false);
              },
            ),
          ),
          const SizedBox(width: Space.small),
          Padding(
            padding: const EdgeInsets.only(top: Space.small),
            child: OutlinedButton(
              key: const Key('template-keep'),
              onPressed: widget.starting.asTemplate == null
                  ? null
                  : () {
                      widget.onKeep();
                      setState(() => _kept = true);
                    },
              child: Text(_kept ? 'Kept' : 'Keep'),
            ),
          ),
        ],
      );
}

/// What stands in the way of starting, and what to do about it.
///
/// Coloured by whether the person can act on it here. Unlocking a vault happens at the machine —
/// a daemon has no terminal to take a passphrase at — and that is a different sentence from *this
/// cannot be done*, so it is not drawn as a fault.
class _NotReady extends StatelessWidget {
  const _NotReady({required this.starting, this.onStoreTheCredential, this.onLogIn});

  final StartWork starting;
  final Future<void> Function()? onStoreTheCredential;
  final Future<void> Function(Agent agent)? onLogIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final answer = starting.readiness!;
    final elsewhere = answer.outcome.answeredAtTheMachine;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.normal),
      decoration: BoxDecoration(
        color: elsewhere ? scheme.tertiaryContainer : scheme.errorContainer,
        borderRadius: BorderRadius.circular(Radii.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(answer.whatToDo, key: const Key('not-ready')),
          // The daemon's own words, under ours. Never parsed, only shown.
          if (answer.detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.tight),
            Text(answer.detail,
                key: const Key('not-ready-detail'),
                style: Theme.of(context).textTheme.bodySmall),
          ],
          // Not a sentence to act on elsewhere: the way to store it, here, in a terminal there.
          if (onStoreTheCredential != null &&
              const <String>{'CREDENTIAL_MISSING', 'CREDENTIAL_UNUSABLE'}.contains(answer.outcome.name)) ...<Widget>[
            const SizedBox(height: Space.small),
            OutlinedButton.icon(
              key: const Key('store-the-credential'),
              onPressed: () => onStoreTheCredential!(),
              icon: const Icon(Icons.terminal, size: Sizes.rowIcon),
              label: Text('Store ${answer.credential.isEmpty ? 'it' : answer.credential} now, in a '
                  'terminal on the machine'),
            ),
            // The agent's own way in, where it declares one: a browser page here, no key to paste.
            if (onLogIn != null && (starting.chosenAgent?.canLogIn ?? false)) ...<Widget>[
              const SizedBox(height: Space.tight),
              OutlinedButton.icon(
                key: const Key('log-in-with-the-agent'),
                onPressed: () => onLogIn!(starting.chosenAgent!),
                icon: const Icon(Icons.login, size: Sizes.rowIcon),
                label: Text('Log in with ${_labelOf(starting.chosenAgent!)}: this runs the agent’s '
                    'own login, in a terminal on the machine'),
              ),
              if (starting.chosenAgent!.loginDocumentation.isNotEmpty)
                TextButton.icon(
                  key: const Key('login-documentation'),
                  onPressed: () => unawaited(openLink(Uri.parse(starting.chosenAgent!.loginDocumentation))),
                  icon: const Icon(Icons.open_in_new, size: Sizes.rowIcon),
                  label: const Text('How this login works'),
                ),
            ],
          ],
          if (starting.refusedOutright) ...<Widget>[
            const SizedBox(height: Space.small),
            Text(
              'An unattended run that cannot authenticate is refused before anything is created — '
              'no container, no workspace, nothing to clear up. Nobody would be watching it fail.',
              key: const Key('refused-outright'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (starting.whatItWouldCost != null) ...<Widget>[
            const SizedBox(height: Space.small),
            Text(starting.whatItWouldCost!,
                key: const Key('what-it-would-cost'),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

String _labelOf(Agent agent) => agent.label.isEmpty ? agent.name : agent.label;
