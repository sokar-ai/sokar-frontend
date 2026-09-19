import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/project_following.dart';
import 'tokens.dart';

/// Follows a project's repository — the only way a project comes to a machine.
///
/// **How its commits are checked is chosen, never defaulted.** Pinning a key means only commits
/// signed with it are taken; following unverified means whoever can push to the repository decides
/// what this machine runs, and that is said beside the choice rather than after it.
///
/// **A rewritten history is a second decision, never a retry.** A properly signed commit that does
/// not descend from the one in force is either its owner rebasing or somebody re-serving an older
/// signed configuration to put back a rule that was taken away, and nothing here can tell which.
class ProjectFollowingPanel extends StatelessWidget {
  /// Constructor taking the answers and what each button does.
  const ProjectFollowingPanel({
    required this.following,
    required this.onFollow,
    required this.onDone,
    this.onUnlockHere,
    this.onSetUpItsConnection,
    this.onStoreInATerminal,
    super.key,
  });

  final ProjectFollowing following;

  /// Follows it; with `true`, a person's answer to a rewritten history.
  final Future<void> Function({bool acceptRewrite}) onFollow;

  /// Puts it away, saying whether the project is now on the machine.
  final void Function(bool taken) onDone;

  /// Opens the machine's vault by its passphrase, for a credential that is in it.
  final VoidCallback? onUnlockHere;

  /// Sets up a connection for the repository's address, in the machine's connections.
  final VoidCallback? onSetUpItsConnection;

  /// Stores the missing value by the command the check named, typed into a terminal there.
  final VoidCallback? onStoreInATerminal;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: following,
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;
          final answer = following.answer;
          return Align(
            alignment: Alignment.topCenter,
            child: AlertDialog(
              title: Text(following.taken ? 'Following' : 'Follow a repository'),
              content: SizedBox(
                width: Sizes.dialog,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (following.held)
                        _Block(
                          color: scheme.errorContainer,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(following.checkWords, key: const Key('follow-check-says')),
                              if (following.check!.detail.isNotEmpty)
                                Text(following.check!.detail,
                                    style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: Space.small),
                              Wrap(
                                spacing: Space.small,
                                children: <Widget>[
                                  if (following.check!.outcome == 'VAULT_LOCKED' && onUnlockHere != null)
                                    OutlinedButton(
                                      key: const Key('follow-unlock'),
                                      onPressed: onUnlockHere,
                                      child: const Text('Open the vault'),
                                    ),
                                  if (following.check!.outcome == 'NO_CREDENTIAL' &&
                                      onSetUpItsConnection != null)
                                    OutlinedButton(
                                      key: const Key('follow-set-up-connection'),
                                      onPressed: onSetUpItsConnection,
                                      child: const Text('Set up its connection'),
                                    ),
                                  if (following.check!.storeCommand.isNotEmpty &&
                                      following.check!.storeStdin.isEmpty &&
                                      onStoreInATerminal != null)
                                    OutlinedButton(
                                      key: const Key('follow-store-value'),
                                      onPressed: onStoreInATerminal,
                                      child: const Text('Store its value in a terminal'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (following.problem != null)
                        _Block(
                          color: scheme.errorContainer,
                          child: Text(following.problem!, key: const Key('follow-problem')),
                        )
                      else if (answer != null)
                        _Block(
                          color: following.taken
                              ? scheme.surfaceContainerHighest
                              : scheme.errorContainer,
                          child: _WhatCameOfIt(answer: answer),
                        ),
                      if (!following.taken) ...<Widget>[
                        const Text(
                          'Its project.yml is written in the repository, where you commit. '
                          'The machine checks it when it follows, and says what is wrong with it.',
                        ),
                        const SizedBox(height: Space.small),
                        _Field(
                          id: 'follow-name',
                          label: 'What the project is called — the name its project.yml gives',
                          value: following.name,
                          onChanged: (typed) => following.answerWith(() => following.name = typed),
                        ),
                        _Field(
                          id: 'follow-url',
                          label: 'Where its repository is — a URL, or a directory on that machine',
                          value: following.url,
                          onChanged: (typed) => following.answerWith(() => following.url = typed),
                        ),
                        const SizedBox(height: Space.small),
                        Text('How its commits are checked',
                            style: Theme.of(context).textTheme.labelLarge),
                        RadioGroup<Checking>(
                          groupValue: following.checking,
                          onChanged: (chosen) =>
                              following.answerWith(() => following.checking = chosen),
                          child: const Column(
                            children: <Widget>[
                              RadioListTile<Checking>(
                                key: Key('follow-pinned'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: Checking.pinned,
                                title: Text('Only commits signed with this key'),
                              ),
                              RadioListTile<Checking>(
                                key: Key('follow-unverified'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: Checking.unverified,
                                title: Text('Unverified'),
                                subtitle: Text(
                                  'Anybody who can push to the repository decides what this machine '
                                  'runs. Shown as unverified wherever the project is.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (following.checking == Checking.pinned)
                          _Field(
                            id: 'follow-key',
                            // Its fingerprint works too — the string a refused signature shows.
                            label: 'The public key, or its fingerprint (SHA256:…)',
                            value: following.key,
                            onChanged: (typed) => following.answerWith(() => following.key = typed),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                if (following.taken)
                  FilledButton(
                    key: const Key('follow-done'),
                    onPressed: () => onDone(true),
                    child: const Text('Go to it'),
                  )
                else ...<Widget>[
                  TextButton(
                    key: const Key('follow-leave'),
                    onPressed: () => onDone(false),
                    child: const Text('Leave it'),
                  ),
                  if (following.rewritten)
                    OutlinedButton(
                      key: const Key('follow-accept-rewrite'),
                      onPressed: following.busy ? null : () => onFollow(acceptRewrite: true),
                      child: const Text('Take the rewritten history'),
                    ),
                  FilledButton(
                    key: const Key('follow-it'),
                    onPressed: following.ready && !following.busy ? () => onFollow() : null,
                    child: const Text('Follow it'),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

/// What the machine made of it, in the same words the project's header uses.
class _WhatCameOfIt extends StatelessWidget {
  const _WhatCameOfIt({required this.answer});

  final Followed answer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(answer.words, key: const Key('follow-says')),
        if (answer.signer.isNotEmpty)
          SelectableText('Signed by ${answer.signer}', style: text.bodySmall),
        if (answer.detail.isNotEmpty) Text(answer.detail, style: text.bodySmall),
        if (answer.outcome == 'REWRITTEN')
          Text(
            'This is its owner rebasing, or somebody serving an older signed configuration to put '
            'back a rule that was taken away. Nothing here can tell which.',
            key: const Key('follow-rewrite-cost'),
            style: text.bodySmall,
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.id, required this.label, required this.value, required this.onChanged});

  final String id;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.small),
        child: TextFormField(
          key: Key(id),
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          onChanged: onChanged,
        ),
      );
}

class _Block extends StatelessWidget {
  const _Block({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: Space.normal),
        padding: const EdgeInsets.all(Space.normal),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Radii.small)),
        child: child,
      );
}
