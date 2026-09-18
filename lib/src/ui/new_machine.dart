import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/machine_setup.dart';
import '../app/setup_run.dart';
import 'host_key_dialog.dart';
import 'tokens.dart';

/// The steps of a new machine, or of a new user on a machine prepared before, drawn from a
/// [SetupRun]. **The run holds everything**, so this can be rebuilt, left and come back to without
/// losing a word; going back, on and finishing are the dialog's buttons.
class NewMachineSteps extends StatefulWidget {
  /// Constructor taking the run and what to do when something new is printed.
  const NewMachineSteps({required this.run, this.onGrew, super.key});

  /// What was said and done, and what is being done.
  final SetupRun run;

  /// Called when output grew, so the dialog can scroll to it.
  final VoidCallback? onGrew;

  @override
  State<NewMachineSteps> createState() => _NewMachineStepsState();
}

class _NewMachineStepsState extends State<NewMachineSteps> {
  late final _private = TextEditingController(text: widget.run.privateKey);
  late final _public = TextEditingController(text: widget.run.publicKey);
  late final _host = TextEditingController(text: widget.run.host);
  int _grown = 0;

  /// The private keys in `~/.ssh`, read once when the steps are drawn.
  late final List<String> _keys = widget.run.setup.sshKeys();

  SetupRun get run => widget.run;

  @override
  void initState() {
    super.initState();
    // Typing redraws: whether a key can be kept depends on both fields being filled.
    _private.addListener(() => setState(() => run.privateKey = _private.text));
    _public.addListener(() => setState(() => run.publicKey = _public.text));
    _host.addListener(() {
      if (run.host == _host.text) return;
      run.host = _host.text;
      run.changed();
    });
    run.addListener(_follow);
  }

  /// Keeps the fields in step with the run, and scrolls when something new was printed.
  void _follow() {
    if (!mounted) return;
    if (_private.text != run.privateKey) _private.text = run.privateKey;
    if (_public.text != run.publicKey) _public.text = run.publicKey;
    final grown = run.output.length + run.log.length + (run.said == null ? 0 : 1);
    if (grown != _grown) {
      _grown = grown;
      widget.onGrew?.call();
    }
    setState(() {});
  }

  @override
  void dispose() {
    run.removeListener(_follow);
    _private.dispose();
    _public.dispose();
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...switch (run.step) {
            SetupStep.key => run.addingAUser ? _knownKeyStep(context) : _keyStep(context),
            SetupStep.where => _whereStep(context),
            SetupStep.prepare => _prepareStep(context),
            SetupStep.reach => _reachStep(context),
            SetupStep.harden => _hardenStep(context),
          },
          if (run.busy) ...<Widget>[
            const SizedBox(height: Space.normal),
            Row(
              children: <Widget>[
                const SizedBox.square(
                  dimension: Sizes.mark,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Space.small),
                Expanded(child: Text(run.doing!, key: const Key('setup-doing'))),
              ],
            ),
          ],
          if (run.said != null) ...<Widget>[
            const SizedBox(height: Space.normal),
            SelectableText(
              run.said!,
              key: const Key('setup-said'),
              style: TextStyle(color: run.saidIsBad ? Theme.of(context).colorScheme.error : null),
            ),
          ],
        ],
      );

  Widget _title(BuildContext context, String words) =>
      Text(words, style: Theme.of(context).textTheme.labelLarge);

  List<Widget> _knownKeyStep(BuildContext context) => <Widget>[
        _title(context, '1. The key root logs in with'),
        const SizedBox(height: Space.small),
        Text(
          'The key the machine already knows — for one this wizard prepared, ~/.ssh/sokar-<its '
          'name>. It also becomes the key ${run.workUser} logs in with.',
        ),
        const SizedBox(height: Space.normal),
        _keyPicker(context, use: 'use-key'),
      ];

  /// The keys in `~/.ssh` to choose from, by name, and the button that uses the chosen one.
  Widget _keyPicker(BuildContext context, {required String use}) {
    if (_keys.isEmpty) {
      return const Text('There is no key in ~/.ssh yet.', key: Key('no-existing-key'));
    }
    final chosen = _keys.contains(run.keyFile) ? run.keyFile : null;
    return Wrap(
      spacing: Space.small,
      runSpacing: Space.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        DropdownButton<String>(
          key: const Key('existing-key'),
          value: chosen,
          hint: const Text('Choose a key'),
          onChanged: run.kept != null || run.busy
              ? null
              : (file) => setState(() => run.keyFile = file ?? ''),
          items: <DropdownMenuItem<String>>[
            for (final file in _keys)
              DropdownMenuItem<String>(value: file, child: Text(file.split('/').last)),
          ],
        ),
        if (run.kept == null)
          FilledButton.tonal(
            key: Key(use),
            onPressed: run.busy || chosen == null ? null : run.useKey,
            child: const Text('Use this key'),
          ),
      ],
    );
  }

  List<Widget> _keyStep(BuildContext context) => <Widget>[
        _title(context, '1. The key it will be reached with'),
        const SizedBox(height: Space.small),
        const Text(
          'Generate a key pair, paste one, or use a key that is already in ~/.ssh. A generated or '
          'pasted one is kept in ~/.ssh, owner-only. None may have a passphrase: this interface '
          'never asks for one.',
        ),
        const SizedBox(height: Space.normal),
        TextField(
          key: const Key('new-private-key'),
          controller: _private,
          enabled: run.kept == null,
          maxLines: 3,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          decoration: const InputDecoration(
            labelText: 'Private key',
            hintText: '-----BEGIN OPENSSH PRIVATE KEY-----',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: Space.normal),
        TextField(
          key: const Key('new-public-key'),
          controller: _public,
          enabled: run.kept == null,
          maxLines: 2,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          decoration: InputDecoration(
            labelText: 'Public key',
            hintText: 'ssh-ed25519 AAAA…',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              key: const Key('copy-public-key'),
              icon: const Icon(Icons.copy_outlined, size: Sizes.rowIcon),
              tooltip: 'Copy the public key',
              onPressed: _public.text.trim().isEmpty
                  ? null
                  : () => Clipboard.setData(ClipboardData(text: _public.text.trim())),
            ),
          ),
        ),
        const SizedBox(height: Space.normal),
        if (run.kept == null)
          Wrap(
            spacing: Space.small,
            children: <Widget>[
              OutlinedButton.icon(
                key: const Key('generate-key'),
                onPressed: run.busy ? null : run.generate,
                icon: const Icon(Icons.key_outlined, size: Sizes.rowIcon),
                label: const Text('Generate a key pair'),
              ),
              FilledButton.tonal(
                key: const Key('keep-key'),
                onPressed: run.busy || _private.text.trim().isEmpty || _public.text.trim().isEmpty
                    ? null
                    : run.keep,
                child: Text('Keep it as ~/.ssh/${run.keyName}'),
              ),
            ],
          ),
        if (run.kept == null) ...<Widget>[
          const SizedBox(height: Space.normal),
          Text('Or use a key you already have', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: Space.tight),
          _keyPicker(context, use: 'use-existing-key'),
        ] else ...<Widget>[
          const Text(
            'Give this public key to the provider when the server is created — for Hetzner, under '
            "SSH keys. A key added afterwards cannot reach a machine that only knows root's.",
            key: Key('give-the-public-key'),
          ),
          const SizedBox(height: Space.small),
          SelectableText(
            _public.text.trim(),
            key: const Key('public-key-to-copy'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ];

  List<Widget> _whereStep(BuildContext context) => <Widget>[
        _title(context, '2. Where it is'),
        const SizedBox(height: Space.small),
        const Text(
          'Once the server exists, its name or address. The wizard logs in as root with the key '
          'above; nothing is changed on the machine yet.',
        ),
        const SizedBox(height: Space.normal),
        TextField(
          key: const Key('new-host'),
          controller: _host,
          decoration: const InputDecoration(
            labelText: 'Server name or IP address',
            hintText: '203.0.113.10',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: Space.normal),
        OutlinedButton.icon(
          key: const Key('try-root-login'),
          onPressed: run.busy || _host.text.trim().isEmpty
              ? null
              : () => run.tryRoot((check) => confirmHostKey(context, check)),
          icon: const Icon(Icons.login, size: Sizes.rowIcon),
          label: const Text('Try logging in as root'),
        ),
      ];

  List<Widget> _prepareStep(BuildContext context) => <Widget>[
        _title(context, '3. Preparing it'),
        const SizedBox(height: Space.small),
        Text(
          run.addingAUser
              ? "Sokar's setup script runs as root. Sokar is there already, so it creates the user "
                  '${run.workUser} beside the others, with its own daemon and vault. It shows every '
                  'command before it runs; nothing changes until you run it.'
              : "Sokar's setup script runs as root. It creates the user ${run.workUser}, which runs "
                  'work, and installs Sokar, its filter and the local transport, and whatever you '
                  'choose below. It shows every command before it runs; nothing changes until you '
                  'run it.',
        ),
        const SizedBox(height: Space.normal),
        if (!run.addingAUser)
          OutlinedButton.icon(
            key: const Key('list-packages'),
            onPressed: run.busy || run.prepared ? null : run.listPackages,
            icon: const Icon(Icons.checklist, size: Sizes.rowIcon),
            label: const Text('See what it can install'),
          ),
        if (run.offered != null || run.addingAUser) ...<Widget>[
          const SizedBox(height: Space.small),
          for (final package in run.offered ?? const <InstallablePackage>[])
            CheckboxListTile(
              key: Key('package-${package.name}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: package.installed || run.chosen.contains(package.name),
              // Already there is shown, ticked and fixed, rather than hidden: a person should see
              // what the machine has.
              onChanged: package.installed || run.prepared
                  ? null
                  : (on) {
                      on == true ? run.chosen.add(package.name) : run.chosen.remove(package.name);
                      run.changed();
                    },
              title: Text(<String>[
                package.name,
                if (package.version.isNotEmpty) package.version,
                if (package.installed) 'installed',
              ].join(' · ')),
              subtitle: Text(<String>[
                if (package.kind.isNotEmpty) package.kind,
                if (package.description.isNotEmpty) package.description,
              ].join(': ')),
            ),
          const SizedBox(height: Space.normal),
          Terminal(text: MachineSetup.show(run.workUser, run.chosen.toList()..sort()), id: 'fetch-script'),
          const SizedBox(height: Space.small),
          OutlinedButton.icon(
            key: const Key('show-setup'),
            onPressed: run.busy || run.prepared ? null : run.show,
            icon: const Icon(Icons.visibility_outlined, size: Sizes.rowIcon),
            label: const Text('Show what it would do'),
          ),
        ],
        if (run.shown != null) ...<Widget>[
          const SizedBox(height: Space.normal),
          Terminal(text: run.shown!, id: 'setup-shown'),
          const SizedBox(height: Space.small),
          if (run.shownFor != run.choice && !run.prepared)
            const Text(
              'The choice changed since this was shown. Show it again before it runs.',
              key: Key('show-again'),
            )
          else
            FilledButton.icon(
              key: const Key('run-setup'),
              onPressed: run.busy || run.prepared ? null : run.prepare,
              icon: const Icon(Icons.play_arrow_outlined, size: Sizes.rowIcon),
              label: const Text('Run it as root'),
            ),
        ],
        // Lines as they arrive while it is asking; once it has answered, the answer is shown where
        // it belongs — the packages above, the commands in their box — and not a second time.
        if (run.busy && run.output.isNotEmpty &&
            (run.outputOf == RootAction.list || run.outputOf == RootAction.show)) ...<Widget>[
          const SizedBox(height: Space.normal),
          Terminal(text: run.output.join('\n'), id: 'asking-output'),
        ],
        // What running it printed: nothing until it was run, and kept once it has.
        if (run.outputOf == RootAction.prepare && run.output.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.normal),
          Terminal(text: run.output.join('\n'), id: 'setup-output'),
        ],
      ];

  List<Widget> _reachStep(BuildContext context) => <Widget>[
        _title(context, '4. Reaching it as ${run.workUser}'),
        const SizedBox(height: Space.small),
        Text(
          'Lets the key log in as ${run.workUser} (as root, below), adds Host ${run.alias} to '
          "~/.ssh/config — as ${run.workUser}, never root — starts Sokar in ${run.workUser}'s own "
          'session, asks sokar doctor, and connects the way watching it will.',
        ),
        const SizedBox(height: Space.normal),
        Terminal(text: MachineSetup.authorize(run.workUser, _public.text.trim()), id: 'authorize-script'),
        const SizedBox(height: Space.small),
        FilledButton.icon(
          key: const Key('finish-setup'),
          onPressed: run.busy || run.ready != null ? null : run.reach,
          icon: const Icon(Icons.link, size: Sizes.rowIcon),
          label: const Text('Set it up and connect'),
        ),
        if (run.log.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.normal),
          Terminal(text: run.log.join('\n'), id: 'setup-log'),
        ],
      ];

  List<Widget> _hardenStep(BuildContext context) => <Widget>[
        _title(context, '5. Closing the way root came in (optional)'),
        const SizedBox(height: Space.small),
        Text(
          'This writes two lines into the ssh server\'s configuration there and reloads it: root can '
          'no longer log in over ssh at all, with any key, and nobody can log in with a password. '
          'No user and no key is deleted; ${run.workUser} keeps logging in with its key.\n\n'
          'Afterwards the wizard cannot add another user to this machine, because that needs root: '
          "it would take the provider's console. Leave it for later if more users are to come.",
          key: const Key('harden-explained'),
        ),
        const SizedBox(height: Space.normal),
        Terminal(text: MachineSetup.harden, id: 'harden-script'),
        const SizedBox(height: Space.small),
        OutlinedButton.icon(
          key: const Key('harden'),
          onPressed: run.busy || run.hardened ? null : run.harden,
          icon: const Icon(Icons.shield_outlined, size: Sizes.rowIcon),
          label: const Text('Turn off root and password login'),
        ),
        if (run.outputOf == RootAction.harden && run.output.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.normal),
          Terminal(text: run.output.join('\n'), id: 'harden-output'),
        ],
      ];
}

/// A script, or what one printed, shown the way a terminal shows it: light on dark, whatever the
/// theme — it is the far machine's shell, not a part of this window.
class Terminal extends StatelessWidget {
  /// Constructor taking the text and a key for it.
  const Terminal({required this.text, required this.id, super.key});

  /// What is shown.
  final String text;

  /// The key the text is found by.
  final String id;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        padding: const EdgeInsets.all(Space.small),
        child: SingleChildScrollView(
          reverse: true,
          child: SelectableText(
            text.trim(),
            key: Key(id),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFD4D4D4)),
          ),
        ),
      );
}
