import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/vault.dart';
import '../app/vault_devices.dart';
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
    required this.onEnroll,
    required this.onUnlock,
    required this.onRevoke,
    required this.onClose,
    super.key,
  });

  /// What the store says about itself.
  final Vault vault;

  /// Shuts it.
  final VoidCallback onLock;

  /// Enrolls this device under a name.
  final ValueChanged<String> onEnroll;

  /// Opens it with this device's key, for so many minutes or until it is shut.
  final ValueChanged<int?> onUnlock;

  /// Revokes one way in.
  final ValueChanged<Keyslot> onRevoke;

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
                  child: Wrap(
                    spacing: Space.small,
                    runSpacing: Space.small,
                    children: <Widget>[
                      OutlinedButton.icon(
                        key: const Key('lock-the-store'),
                        onPressed: vault.busy ? null : onLock,
                        icon: const Icon(Icons.lock_outline, size: Sizes.rowIcon),
                        label: const Text('Shut it'),
                      ),
                      // Beside the button that shuts it, for the same reason the sentence below is.
                      if (vault.devices.enrolledHere)
                        OutlinedButton.icon(
                          key: const Key('unlock-with-this-device'),
                          onPressed: vault.devices.busy ? null : () => _unlock(context),
                          icon: const Icon(Icons.lock_open_outlined, size: Sizes.rowIcon),
                          label: const Text('Open it with this device'),
                        ),
                    ],
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
                  why: 'A device enrolled below opens it from here, and its key is all that is '
                      'sent — a passphrase is never typed here. The store is unlocked where the '
                      'machine is otherwise, with `sokar vault unlock` — and the person reading '
                      'this holds an ssh connection to that machine already, because that is why '
                      'this window can see it at all.',
                  id: 'unlocking-elsewhere',
                ),
              ],
              _Devices(
                devices: vault.devices,
                onEnroll: () => _enroll(context),
                onRevoke: (slot) => _revoke(context, slot),
              ),
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

  Future<void> _enroll(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _EnrollDialog(storage: vault.devices.store.storage),
    );
    if (name != null) onEnroll(name);
  }

  Future<void> _unlock(BuildContext context) async {
    final minutes = await showDialog<_For>(
      context: context,
      builder: (context) => const _UnlockDialog(),
    );
    if (minutes != null) onUnlock(minutes.minutes);
  }

  Future<void> _revoke(BuildContext context, Keyslot slot) async {
    final itself = vault.devices.mine?.slot == slot.id;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revoke "${slot.name}"?'),
        content: Text(
          itself
              ? 'This device will no longer open the vault, and forgets its key. Enrolling it again '
                  'makes a new one.'
              : '"${slot.name}" will no longer open the vault. It is not asked: whatever it holds '
                  'stops working.',
          key: const Key('revoke-says'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            key: const Key('revoke-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (sure ?? false) onRevoke(slot);
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

/// The devices that open the store, this one marked, and enrolling it when it is not among them.
class _Devices extends StatelessWidget {
  const _Devices({required this.devices, required this.onEnroll, required this.onRevoke});

  final VaultDevices devices;
  final VoidCallback onEnroll;
  final ValueChanged<Keyslot> onRevoke;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Heading(words: 'Devices that open it'),
        if (devices.problem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.normal, 0, Space.normal, Space.small),
            child: Text(devices.problem!,
                key: const Key('devices-problem'), style: small?.copyWith(color: scheme.error)),
          ),
        if (devices.said != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.normal, 0, Space.normal, Space.small),
            child: Text(devices.said!, key: const Key('devices-said')),
          ),
        for (final slot in devices.slots)
          ListTile(
            key: Key('keyslot-${slot.id}'),
            dense: true,
            leading: Icon(slot.recovery ? Icons.password : Icons.devices_outlined,
                size: Sizes.mark),
            title: Text(
                devices.mine?.slot == slot.id ? '${slot.name} — this device' : slot.name),
            subtitle: Text(_about(slot)),
            // The recovery passphrase is the way in when every device is gone, and is changed at
            // the machine; revoking it from a window that may have lost its devices is not offered.
            trailing: slot.recovery
                ? null
                : IconButton(
                    key: Key('revoke-${slot.id}'),
                    tooltip: 'Revoke',
                    icon: const Icon(Icons.remove_circle_outline, size: Sizes.rowIcon),
                    onPressed: devices.busy ? null : () => onRevoke(slot),
                  ),
          ),
        if (!devices.enrolledHere && devices.problem == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.normal, Space.small, Space.normal, 0),
            child: OutlinedButton.icon(
              key: const Key('enroll-this-device'),
              onPressed: devices.busy ? null : onEnroll,
              icon: const Icon(Icons.add_moderator_outlined, size: Sizes.rowIcon),
              label: const Text('Enroll this device'),
            ),
          ),
      ],
    );
  }

  static String _about(Keyslot slot) {
    if (slot.recovery) return 'Used at the machine, with `sokar vault unlock`.';
    final used = slot.lastUsed.isEmpty ? 'not used yet' : 'last used ${_day(slot.lastUsed)}';
    return '${storageWords(slot.storage)} Enrolled ${_day(slot.enrolled)}, $used.';
  }

  static String _day(String instant) =>
      instant.length >= 10 ? instant.substring(0, 10) : instant;
}

/// Names this device before it is enrolled, and says **before** what its key is kept in.
class _EnrollDialog extends StatefulWidget {
  const _EnrollDialog({required this.storage});

  final KeyslotStorage storage;

  @override
  State<_EnrollDialog> createState() => _EnrollDialogState();
}

class _EnrollDialogState extends State<_EnrollDialog> {
  late final TextEditingController _name = TextEditingController(text: _hostName());

  static String _hostName() {
    try {
      return Platform.localHostname;
    } on Object {
      return '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    return AlertDialog(
      title: const Text('Enroll this device'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              key: const Key('device-name'),
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'What to call it in the list',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.normal),
            Text(
              'Its key: ${storageWords(widget.storage)}',
              key: const Key('enroll-storage'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('enroll-confirm'),
          onPressed: name.isEmpty ? null : () => Navigator.of(context).pop(name),
          child: const Text('Enroll'),
        ),
      ],
    );
  }
}

/// How long an unlock lasts, including not bounding it.
enum _For {
  quarterHour(15, 'for 15 minutes'),
  hour(60, 'for an hour'),
  workday(480, 'for 8 hours'),
  untilShut(null, 'until it is shut');

  const _For(this.minutes, this.words);

  final int? minutes;
  final String words;
}

/// Asks how long it stays open. **Nothing is chosen for the person** — a bound that crept in as a
/// default would decide how often they are asked, and so would its absence.
class _UnlockDialog extends StatefulWidget {
  const _UnlockDialog();

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  _For? _chosen;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Open the store'),
        content: RadioGroup<_For>(
          groupValue: _chosen,
          onChanged: (chosen) => setState(() => _chosen = chosen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final each in _For.values)
                RadioListTile<_For>(
                  key: Key('open-${each.name}'),
                  value: each,
                  title: Text(each.words),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('open-confirm'),
            onPressed: _chosen == null ? null : () => Navigator.of(context).pop(_chosen),
            child: const Text('Open it'),
          ),
        ],
      );
}
