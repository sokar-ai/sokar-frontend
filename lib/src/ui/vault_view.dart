import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/vault.dart';
import '../app/vault_devices.dart';
import 'panes.dart';
import 'tokens.dart';

/// The protected store: what it holds, by name, and the devices that open it.
///
/// Opening, shutting and enrolling are the button in the machine's title, where somebody looks for
/// them; this is what there is to read and the one thing to undo, revoking a device.
class VaultView extends StatelessWidget {
  /// Constructor taking the store and what can be done to it.
  const VaultView({
    required this.vault,
    required this.onRevoke,
    required this.onClose,
    super.key,
  });

  /// What the store says about itself.
  final Vault vault;

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
                  const _Line(
                    'Nothing can be listed while it is shut. That is not the same as it holding '
                    'nothing.',
                    id: 'shut-not-empty',
                  )
                else if (vault.credentials.isEmpty)
                  const _Line(
                    'It is open and holds nothing. That is a state, not a failure.',
                    id: 'open-and-empty',
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
              ],
              _Devices(devices: vault.devices, onRevoke: (slot) => _revoke(context, slot)),
              const SizedBox(height: Space.wide),
              // One line for everything that happens at the machine instead: a daemon has no
              // terminal to take a passphrase at.
              const _Line(
                'At the machine: `sokar vault unlock` opens it without a device, `sokar vault '
                'passphrase` changes its passphrase.',
                id: 'at-the-machine',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _revoke(BuildContext context, Keyslot slot) async {
    final itself = vault.devices.mine?.slot == slot.id;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revoke "${slot.name}"?'),
        content: Text(
          itself
              ? 'This device will no longer open the store, and forgets its key.'
              : '"${slot.name}" will no longer open the store.',
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
    return credential.characters == 0 ? kind : '$kind · ${credential.characters} characters';
  }
}

/// The devices that open the store, this one marked.
class _Devices extends StatelessWidget {
  const _Devices({required this.devices, required this.onRevoke});

  final VaultDevices devices;
  final ValueChanged<Keyslot> onRevoke;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Heading(words: 'Devices that open it'),
        if (devices.problem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.normal, 0, Space.normal, Space.small),
            child: Text(devices.problem!,
                key: const Key('devices-problem'),
                style: small?.copyWith(color: Theme.of(context).colorScheme.error)),
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
            // The way in when every device is gone, changed at the machine; revoking it from a
            // window that may have lost its devices is not offered.
            trailing: slot.recovery
                ? null
                : IconButton(
                    key: Key('revoke-${slot.id}'),
                    tooltip: 'Revoke',
                    icon: const Icon(Icons.remove_circle_outline, size: Sizes.rowIcon),
                    onPressed: devices.busy ? null : () => onRevoke(slot),
                  ),
          ),
      ],
    );
  }

  static String _about(Keyslot slot) {
    if (slot.recovery) return 'The passphrase, used at the machine.';
    final used = slot.lastUsed.isEmpty ? 'not used yet' : 'last used ${_day(slot.lastUsed)}';
    return '${storageWords(slot.storage)} Enrolled ${_day(slot.enrolled)}, $used.';
  }

  static String _day(String instant) =>
      instant.length >= 10 ? instant.substring(0, 10) : instant;
}

class _Line extends StatelessWidget {
  const _Line(this.words, {required this.id});

  final String words;
  final String id;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.normal, 0, Space.normal, Space.small),
        child: Text(words, key: Key(id), style: Theme.of(context).textTheme.bodySmall),
      );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.words});

  final String words;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.normal, Space.wide, Space.normal, Space.small),
        child: Text(words, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _Field extends StatelessWidget {
  const _Field({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.normal, vertical: Space.tight),
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
