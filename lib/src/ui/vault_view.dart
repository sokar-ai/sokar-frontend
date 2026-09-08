import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/vault.dart';
import 'panes.dart';
import 'tokens.dart';

/// The protected store: what it holds, by name, and what happens elsewhere.
///
/// Four of this requirement's seven criteria are answered by a sentence rather than a control, and
/// the sentences are the point. **"This happens at the machine" is not "this cannot be done"** —
/// a daemon has no terminal to take a passphrase at, so unlocking and changing a passphrase belong
/// where a person is present. Leaving those blank would read as work somebody forgot.
class VaultView extends StatelessWidget {
  /// Constructor taking the store and what can be done to it.
  const VaultView({
    required this.vault,
    required this.onLock,
    required this.onClose,
    super.key,
  });

  /// What the store says about itself.
  final Vault vault;

  /// Shuts it.
  final VoidCallback onLock;

  /// Closes the view.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = vault.state;

    return Column(
      children: <Widget>[
        PaneHeader(
          title: 'The protected store',
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close (Esc)',
            onPressed: onClose,
          ),
        ),
        if (vault.problem != null)
          Container(
            width: double.infinity,
            color: scheme.errorContainer,
            padding: const EdgeInsets.all(Space.normal),
            child: Text(vault.problem!, key: const Key('vault-problem')),
          ),
        if (vault.shut != null)
          Container(
            width: double.infinity,
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(Space.normal),
            // `holding` in the same breath as "shut", never in a detail underneath: a running
            // task's proxy read the secret at start and holds it where locking cannot reach.
            // Reporting the store closed without that claims more than happened.
            child: Text(vault.shut!.words, key: const Key('vault-shut')),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Space.small),
            children: <Widget>[
              if (vault.busy && state == null)
                const Padding(
                  padding: EdgeInsets.all(Space.normal),
                  child: Text('Asking the machine…'),
                )
              else if (state != null) ...<Widget>[
                _Field(name: 'Where it is', value: state.vault),
                _Field(
                  name: 'State',
                  value: switch ((state.exists, state.readable)) {
                    (false, _) => 'no store on this machine yet',
                    (true, true) => 'open — its contents can be read',
                    (true, false) => 'shut, so nothing here can say what it holds',
                  },
                ),
                const _Heading(words: 'What it holds'),
                if (!state.readable)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                        Space.normal, 0, Space.normal, Space.small),
                    child: Text(
                      'Nothing can be listed while it is shut. That is not the same as it '
                      'holding nothing.',
                      key: Key('shut-not-empty'),
                    ),
                  )
                else if (vault.credentials.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                        Space.normal, 0, Space.normal, Space.small),
                    child: Text(
                      'It is open and holds nothing. That is a state, not a failure.',
                      key: Key('open-and-empty'),
                    ),
                  ),
                // Names, kinds and lengths. **Never a value** — that is the whole promise of the
                // method, and this interface reaches a socket that can be forwarded over ssh.
                for (final credential in vault.credentials)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.key_outlined, size: Sizes.mark),
                    title: Text(credential.name,
                        key: const Key('credential-name'),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    subtitle: Text(_describe(credential)),
                  ),
                const SizedBox(height: Space.wide),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.normal),
                  child: OutlinedButton.icon(
                    key: const Key('lock-the-store'),
                    onPressed: vault.busy ? null : onLock,
                    icon: const Icon(Icons.lock_outline, size: Sizes.rowIcon),
                    label: const Text('Shut it'),
                  ),
                ),
                // Beside the button that shuts it, because that is where somebody looks for the
                // one that opens it. At the bottom of the pane it would be an explanation nobody
                // reached; here it is the answer to the question the button raises.
                const _Elsewhere(
                  what: 'Opening it again',
                  why: 'A daemon has no terminal to take a passphrase at, so it can shut the '
                      'store and can never open it. Run `sokar vault unlock` where the machine '
                      'is.',
                  id: 'unlocking-elsewhere',
                ),
              ],
              const _Heading(words: 'What else happens at the machine'),
              const _Elsewhere(
                what: 'Changing the passphrase',
                why: 'Nothing can do this yet — not here and not in the command line either. It '
                    'is coming, and it will be at the machine for the same reason as unlocking.',
                id: 'passphrase-elsewhere',
              ),
              const _Elsewhere(
                what: 'A recovery secret',
                why: 'This interface never reveals a stored value: it answers names, kinds and '
                    'lengths, over a socket that can be forwarded. If a recovery secret is ever '
                    'introduced it belongs at the machine, with a person present.',
                id: 'recovery-elsewhere',
              ),
              const _Elsewhere(
                what: 'How long it stays open',
                why: 'Today there is one behaviour and no choice: the passphrase is cached until '
                    'it is shut or the last session ends. A bounded unlock is coming, and it is a '
                    'choice about how long rather than about where.',
                id: 'remembering-elsewhere',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// What is known about one entry, without any of it.
  static String _describe(Credential credential) {
    final kind = credential.type.isEmpty ? 'kind not recorded' : credential.type;
    return credential.characters == 0
        ? kind
        : '$kind · ${credential.characters} characters';
  }
}

/// Something this interface deliberately does not do, and where it is done instead.
class _Elsewhere extends StatelessWidget {
  const _Elsewhere({required this.what, required this.why, required this.id});

  final String what;
  final String why;
  final String id;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Space.normal, Space.normal, Space.normal, Space.normal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(what, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Space.tight),
            Text(why,
                key: Key(id), style: Theme.of(context).textTheme.bodySmall),
          ],
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
                  key: Key('vault-${name.toLowerCase().replaceAll(' ', '-')}'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
      );
}
