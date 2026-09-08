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
                // **"Today", not "never".** The reason given for never was partly that no
                // secret crosses this socket, and that rule changed on 2026-09-08: a credential
                // may be transferred, and only storing it here is forbidden. Whether that reopens
                // unlocking is the backend's to say — so this screen states where it happens and
                // stops short of a promise about always.
                const _Elsewhere(
                  what: 'Opening it again',
                  why: 'Nothing here opens it. The store is unlocked where the machine is, with '
                      '`sokar vault unlock` — and the person reading this holds an ssh connection '
                      'to that machine already, because that is why this window can see it at '
                      'all.',
                  id: 'unlocking-elsewhere',
                ),
              ],
              const _Heading(words: 'What else happens at the machine'),
              const _Elsewhere(
                what: 'Changing the passphrase',
                why: '`sokar vault passphrase`, at the machine, for the same reason as '
                    'unlocking. It re-encrypts what is here under the new one and drops the '
                    'cached passphrase — that one is now the wrong one, and keeping it would '
                    'turn the next command into a failure that reads like a damaged store. If '
                    'you are changing it because one leaked, stopping the tasks that already '
                    'hold it is the part that ends it.',
                id: 'passphrase-elsewhere',
              ),
              // **Where somebody looks for a relation that does not exist.** A credential is
              // held under a provider's name, falling back to an agent's for older vaults, and
              // nothing in a project file names one — so *"which keys reach this project"* has no
              // answer rather than a missing screen. Restated correctly it is *"which agents may
              // this project use"*, which is the roster, and a project does not have one either.
              const _Elsewhere(
                what: 'Which projects a key reaches',
                why: 'Nothing routes keys to projects, and nothing will. A credential is held '
                    'under the name of the provider that uses it, and a project file never names '
                    'one — so there is no link here to make or unmake. What bounds a project is '
                    'its security class, its egress and its gate.',
                id: 'no-key-routing',
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
                why: 'Unbounded unless somebody asks otherwise: the passphrase is cached until '
                    'the store is shut or the last session ends. `sokar vault unlock --for 30m` '
                    'bounds it, and the kernel does the discarding, so nothing has to remember. '
                    'There is deliberately no default — a bound that crept in would start asking '
                    'people for a passphrase they never used to be asked for.',
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
