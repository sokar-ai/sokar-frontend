import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sokar_frontend/client.dart';

import '../app/connections.dart';
import 'choice_field.dart';
import 'panes.dart';
import 'pick_a_file.dart';
import 'tokens.dart';

/// What a value kept outside the vault means, said wherever such a value is chosen or shown.
const _notInTheVault = 'Not in the vault: it is kept in plain form on the machine, where anyone who '
    "can read this account's files can read it, and shutting the vault does not protect it.";

/// What one declaration asks for, as a person chose it.
typedef Declaration = ({
  String kind,
  String match,
  String? user,
  String? purpose,
  String source,
  String? id,
});

/// How a machine connects out: every credential it is configured with, and what to do about one.
///
/// **Listed with the vault shut too**, because the list holds no secret — which is what tells
/// *"configured, open the vault"* from *"nothing here"*. A credential kept outside the vault is shown
/// as not protected, and never refused.
class ConnectionsView extends StatelessWidget {
  /// Constructor taking the connections and what each action does.
  const ConnectionsView({
    required this.connections,
    required this.onAdd,
    required this.onForget,
    required this.onClose,
    this.onStoreInATerminal,
    this.onSendAKey,
    this.keysAt = '',
    this.pick = pickWithTheDesktop,
    super.key,
  });

  final Connections connections;

  /// Asks what to declare, and declares it.
  final VoidCallback onAdd;

  /// Forgets the record for one address.
  final ValueChanged<String> onForget;

  /// Closes the view.
  final VoidCallback onClose;

  /// Stores the last declared value by typing it into a terminal on the machine; null where
  /// nothing here reaches that machine's `sokar`.
  final VoidCallback? onStoreInATerminal;

  /// Sends a key to the machine's store command on its standard input — a file of this computer's,
  /// by path, or what was pasted. Null where nothing here reaches that machine's `sokar`.
  final SendAKey? onSendAKey;

  /// Where this computer keeps its ssh keys, for the file dialog to start in.
  final String keysAt;

  /// Asks for a file of this computer.
  final PickAFile pick;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: connections,
        builder: (context, _) {
          final text = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;
          return Column(
            children: <Widget>[
              PaneHeader(
                title: 'How ${connections.machine} connects out',
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close (Esc)',
                  onPressed: onClose,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Space.normal),
                  children: <Widget>[
                    if (connections.problem != null)
                      _Box(color: scheme.errorContainer, child: Text(connections.problem!, key: const Key('connections-problem'))),
                    if (connections.forgotten != null)
                      _Box(
                        color: scheme.surfaceContainerHighest,
                        child: Text(connections.forgottenWords, key: const Key('connections-forgotten')),
                      ),
                    if (connections.declared case final declared?)
                      _Storing(
                        declared: declared,
                        onStoreInATerminal: onStoreInATerminal,
                        onSendAKey: onSendAKey,
                        keysAt: keysAt,
                        pick: pick,
                      ),
                    Text(
                      'Only the description is kept here; a value is stored on the machine and '
                      'never passes through this program. A key or a token reaches everything its '
                      'owner can — a restricted, read-only token is enough to follow a repository.',
                      key: const Key('connections-explained'),
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: Space.normal),
                    if (connections.all.isEmpty)
                      const Text(
                        'Nothing is declared. A git address still uses a vault entry named after its '
                        'host when there is one.',
                        key: Key('no-connections'),
                      ),
                    for (final each in connections.all)
                      _ConnectionRow(
                        connection: each,
                        vaultOpen: connections.vaultOpen,
                        onForget: () => onForget(each.match),
                      ),
                    const SizedBox(height: Space.normal),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        key: const Key('add-connection'),
                        onPressed: connections.busy ? null : onAdd,
                        icon: const Icon(Icons.add, size: Sizes.rowIcon),
                        label: const Text('Add a connection'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({required this.connection, required this.vaultOpen, required this.onForget});

  final Connection connection;
  final bool vaultOpen;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = connection;
    // Missing is only a fact with the vault open; shut, it says only that the vault is shut.
    final there = c.present
        ? 'its value is there'
        : c.source == 'VAULT' && !vaultOpen
            ? 'the vault is shut, so nothing can say whether its value is there'
            : 'its value is missing';
    return ListTile(
      key: ValueKey<String>('connection ${c.match}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(c.kind == 'SSH_KEY' ? Icons.key_outlined : Icons.password_outlined,
          size: Sizes.rowIcon),
      title: Text(c.match, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${c.kindWords} for ${c.purpose.isEmpty ? 'any use' : c.purpose}, '
              '${c.sourceWords}${c.user.isEmpty ? '' : ', as ${c.user}'} · $there'),
          if (!c.protected)
            Text(
              _notInTheVault,
              key: ValueKey<String>('not-protected ${c.match}'),
              style: text.bodySmall?.copyWith(color: scheme.error),
            ),
          if (c.expires.isNotEmpty)
            Text('Stops working at ${c.expires}. Nothing renews it without a person yet.',
                key: ValueKey<String>('expires ${c.match}'), style: text.bodySmall),
        ],
      ),
      trailing: IconButton(
        key: ValueKey<String>('forget ${c.match}'),
        icon: const Icon(Icons.link_off, size: Sizes.rowIcon),
        tooltip: 'Forget this record — its value stays where it is',
        onPressed: onForget,
      ),
    );
  }
}

/// What declaring wrote, and the storing of its value on the machine.
/// Sends a key to the machine, answering why nothing was stored, or null once it was.
typedef SendAKey = Future<String?> Function({String? file, String? pasted});

class _Storing extends StatefulWidget {
  const _Storing(
      {required this.declared,
      required this.pick,
      this.onStoreInATerminal,
      this.onSendAKey,
      this.keysAt = ''});

  final CredentialDeclared declared;
  final PickAFile pick;
  final VoidCallback? onStoreInATerminal;
  final SendAKey? onSendAKey;
  final String keysAt;

  @override
  State<_Storing> createState() => _StoringState();
}

class _StoringState extends State<_Storing> {
  final _pasted = TextEditingController();

  /// Why the last key sent was not stored; it stays here, beside the way to try again.
  String? _refused;

  @override
  void dispose() {
    _pasted.dispose();
    super.dispose();
  }

  Future<void> _send({String? file, String? pasted}) async {
    setState(() => _refused = null);
    final refused = await widget.onSendAKey?.call(file: file, pasted: pasted);
    if (mounted) setState(() => _refused = refused);
  }

  void _sendPasted() {
    final value = _pasted.text;
    // Out of the field at once: nothing here keeps a value once it has been sent.
    _pasted.clear();
    unawaited(_send(pasted: value));
  }

  @override
  Widget build(BuildContext context) {
    final declared = widget.declared;
    final scheme = Theme.of(context).colorScheme;
    final what = '${declared.replaced ? 'Updated' : 'Added'}: ${declared.connection.match}.';
    if (declared.storeCommand.isEmpty) {
      return _Box(
        color: scheme.surfaceContainerHighest,
        child: Text('$what Its value is already where it says, so there is nothing to store.',
            key: const Key('connection-declared')),
      );
    }
    final send = widget.onSendAKey;
    return _Box(
      color: scheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('$what Its value is stored on the machine, with:', key: const Key('connection-declared')),
          const SizedBox(height: Space.tight),
          SelectableText(declared.storeCommand.join(' '),
              key: const Key('store-command'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          const SizedBox(height: Space.small),
          if (declared.storeStdin.isEmpty)
            OutlinedButton.icon(
              key: const Key('store-in-terminal'),
              onPressed: widget.onStoreInATerminal,
              icon: const Icon(Icons.terminal, size: Sizes.rowIcon),
              label: const Text('Type it into a terminal on the machine'),
            )
          else ...<Widget>[
            Text('It reads ${declared.storeStdin} on its standard input.'),
            const SizedBox(height: Space.small),
            OutlinedButton.icon(
              key: const Key('store-choose-file'),
              onPressed: send == null
                  ? null
                  : () async {
                      final chosen = await widget.pick(
                          initialDirectory: widget.keysAt.isEmpty ? null : widget.keysAt,
                          title: 'Send this key');
                      if (chosen != null) await _send(file: chosen);
                    },
              icon: const Icon(Icons.folder_open, size: Sizes.rowIcon),
              label: const Text('Choose a key file of this computer, and send it'),
            ),
            const SizedBox(height: Space.small),
            TextField(
              key: const Key('store-paste'),
              controller: _pasted,
              minLines: 3,
              maxLines: 6,
              obscureText: false,
              decoration: const InputDecoration(labelText: 'Or paste the private key'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: Space.tight),
            OutlinedButton(
              key: const Key('store-send-pasted'),
              onPressed: send == null ? null : _sendPasted,
              child: const Text('Send what was pasted'),
            ),
            if (_refused != null) ...<Widget>[
              const SizedBox(height: Space.small),
              Text(_refused!, key: const Key('store-refused'), style: TextStyle(color: scheme.error)),
            ],
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.color, required this.child});

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

/// Asks what connection to declare. **The kind is chosen, never read off the address**: `https`
/// may be a token or a user and password.
Future<Declaration?> askForAConnection(BuildContext context, {String match = ''}) =>
    showDialog<Declaration>(context: context, builder: (context) => _AddConnection(match: match));

class _AddConnection extends StatefulWidget {
  const _AddConnection({this.match = ''});

  final String match;

  @override
  State<_AddConnection> createState() => _AddConnectionState();
}

class _AddConnectionState extends State<_AddConnection> {
  String? _kind;
  String _source = 'VAULT';
  late final _match = TextEditingController(text: widget.match);
  final _user = TextEditingController();
  final _purpose = TextEditingController(text: 'git');
  final _id = TextEditingController();

  @override
  void dispose() {
    for (final each in <TextEditingController>[_match, _user, _purpose, _id]) {
      each.dispose();
    }
    super.dispose();
  }

  bool get _ready =>
      _kind != null &&
      _match.text.trim().isNotEmpty &&
      (_source == 'VAULT' || _source == 'AGENT' || _id.text.trim().isNotEmpty) &&
      _wrongFile == null;

  /// A key kept as a file is read by the machine as the private key; the public half there would
  /// be declared cleanly and refused at the first fetch.
  String? get _wrongFile => _source == 'FILE' && _kind == 'SSH_KEY' && _id.text.trim().endsWith('.pub')
      ? 'That is the public half. Name the private key file — usually the same name without .pub.'
      : null;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add a connection'),
        content: SizedBox(
          width: Sizes.dialog,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  key: const Key('connection-match'),
                  controller: _match,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      labelText: 'Where it connects to — ssh://github.com, https://gitlab.example/acme/'),
                ),
                ChoiceField<String>(
                  id: 'connection-kind',
                  label: 'What it is',
                  value: _kind,
                  onChanged: (chosen) => setState(() => _kind = chosen),
                  choices: const <Choice<String>>[
                    Choice('SSH_KEY', 'An ssh key', id: 'kind-SSH_KEY'),
                    Choice('TOKEN', 'A token', id: 'kind-TOKEN',
                        means: 'A restricted, read-only token is enough to follow a repository.'),
                    Choice('BASIC', 'A user and password', id: 'kind-BASIC'),
                    Choice('OAUTH', 'An OAuth token', id: 'kind-OAUTH',
                        means: 'It stops working when it expires, and nothing renews it without a '
                            'person yet.'),
                  ],
                ),
                if (_kind == 'BASIC' || _kind == 'TOKEN')
                  TextField(
                    key: const Key('connection-user'),
                    controller: _user,
                    decoration: const InputDecoration(labelText: 'User, when it needs one'),
                  ),
                TextField(
                  key: const Key('connection-purpose'),
                  controller: _purpose,
                  decoration: const InputDecoration(labelText: 'What it is for — git, registry, or any'),
                ),
                ChoiceField<String>(
                  id: 'connection-source',
                  label: 'Where its value lives',
                  value: _source,
                  onChanged: (chosen) => setState(() => _source = chosen ?? 'VAULT'),
                  choices: const <Choice<String>>[
                    Choice('VAULT', 'In the vault', id: 'source-VAULT',
                        means: 'Encrypted on the machine, and out of reach whenever the vault is shut.'),
                    Choice('FILE', 'A file on the machine', id: 'source-FILE', means: _notInTheVault),
                    Choice('ENVIRONMENT', 'A variable on the machine',
                        id: 'source-ENVIRONMENT', means: _notInTheVault),
                    Choice('AGENT', "The account's own ssh agent", id: 'source-AGENT', means: _notInTheVault),
                  ],
                ),
                if (_source == 'FILE' || _source == 'ENVIRONMENT')
                  TextField(
                    key: const Key('connection-id'),
                    controller: _id,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                        errorText: _wrongFile,
                        errorMaxLines: 3,
                        labelText: _source == 'FILE'
                            ? 'Its path on the machine — a file there, not on this computer'
                            : 'The variable, as it is set on the machine'),
                  ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            key: const Key('connection-leave'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Leave it'),
          ),
          FilledButton(
            key: const Key('connection-add'),
            onPressed: _ready
                ? () => Navigator.of(context).pop<Declaration>((
                      kind: _kind!,
                      match: _match.text.trim(),
                      user: _user.text.trim().isEmpty ? null : _user.text.trim(),
                      purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
                      source: _source,
                      id: _source == 'FILE' || _source == 'ENVIRONMENT' ? _id.text.trim() : null,
                    ))
                : null,
            child: const Text('Add it'),
          ),
        ],
      );
}
