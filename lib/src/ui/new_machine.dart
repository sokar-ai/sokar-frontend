import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/connection_trial.dart';
import '../app/host_keys.dart';
import '../app/machine_setup.dart';
import '../app/machines.dart';
import 'host_key_dialog.dart';
import 'tokens.dart';

/// The steps of a new machine, after its name: the key, where it is, and preparing it.
///
/// **The key comes before the machine exists**: a key made afterwards cannot reach a machine that
/// only knows the one given when it was rented. So the public half is shown to be copied into the
/// provider's form, and only then is there anything to log into.
class NewMachineSteps extends StatefulWidget {
  /// Constructor taking the machine's name and what does the work.
  const NewMachineSteps({
    required this.name,
    required this.setup,
    required this.workUser,
    required this.onWatch,
    this.addingAUser = false,
    this.hostKeys,
    this.trying,
    super.key,
  });

  /// What the machine is called, which names its key.
  final String name;

  /// Makes, checks and keeps the key, and logs in as root.
  final MachineSetup setup;

  /// Confirms the host key before the first login, or null where nothing can.
  final HostKeys? hostKeys;

  /// The user the machine runs work as, from the base settings.
  final String workUser;

  /// Tries the prepared machine the way watching it will, or null where nothing can.
  final Future<Trial> Function(Machine machine)? trying;

  /// Watches the prepared machine, which ends the wizard.
  final ValueChanged<Machine> onWatch;

  /// Whether this only adds a user to a machine prepared before: **the same steps**, with the key
  /// the machine already knows instead of a new one, and no packages to choose.
  final bool addingAUser;

  @override
  State<NewMachineSteps> createState() => _NewMachineStepsState();
}

enum _Step { key, where, prepare, reach }

class _NewMachineStepsState extends State<NewMachineSteps> {
  final _private = TextEditingController();
  final _public = TextEditingController();
  final _host = TextEditingController();

  /// The key root logs in with, when adding a user to a machine prepared before.
  late final _keyFile = TextEditingController(
      text: widget.addingAUser ? (widget.setup.existingKeys().firstOrNull ?? '') : '');

  _Step _step = _Step.key;
  bool _busy = false;

  /// Where the key was kept, once it was.
  String? _kept;

  /// What the last action on this step said: a refusal, or what worked.
  String? _said;
  bool _saidIsBad = false;

  /// Whether root logged in with the kept key, for the host as it is now typed.
  String? _loggedInTo;

  /// What the machine could install, as its setup script listed it; null before it was asked.
  List<InstallablePackage>? _offered;

  /// The packages chosen besides what is always installed.
  final Set<String> _chosen = <String>{};

  /// What the setup script's `--show` printed: the commands it would run.
  String? _shown;

  /// Which choice [_shown] was printed for: a run only ever runs what was shown.
  String? _shownFor;

  String get _choice => (_chosen.toList()..sort()).join(' ');

  /// What running the setup script printed, and whether it prepared the machine.
  String? _ran;
  bool _prepared = false;

  /// What reaching it as the work user did, line by line.
  final List<String> _log = <String>[];

  /// The machine as it will be watched, once it answered.
  Machine? _ready;

  /// Whether root and password logins were turned off.
  bool _hardened = false;

  String get _alias => 'sokar-${Machine.slug(widget.name)}';

  String get _keyName => 'sokar-${Machine.slug(widget.name)}';

  @override
  void initState() {
    super.initState();
    for (final field in <TextEditingController>[_private, _public, _host, _keyFile]) {
      field.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _private.dispose();
    _public.dispose();
    _host.dispose();
    _keyFile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...switch (_step) {
            _Step.key => widget.addingAUser ? _knownKeyStep(context) : _keyStep(context),
            _Step.where => _whereStep(context),
            _Step.prepare => _prepareStep(context),
            _Step.reach => _reachStep(context),
          },
          if (_said != null) ...<Widget>[
            const SizedBox(height: Space.normal),
            SelectableText(
              _said!,
              key: const Key('setup-said'),
              style: TextStyle(
                color: _saidIsBad ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ],
          const SizedBox(height: Space.normal),
          Row(
            children: <Widget>[
              if (_step != _Step.key)
                TextButton(
                  key: const Key('setup-back'),
                  onPressed: _busy ? null : () => _goTo(_Step.values[_step.index - 1]),
                  child: const Text('Previous step'),
                ),
              const Spacer(),
              if (_step != _Step.reach)
                FilledButton(
                  key: const Key('setup-next'),
                  onPressed: _canGoOn && !_busy ? () => _goTo(_Step.values[_step.index + 1]) : null,
                  child: const Text('Next step'),
                ),
            ],
          ),
        ],
      );

  bool get _canGoOn => switch (_step) {
        _Step.key => _kept != null,
        _Step.where => _loggedInTo != null && _loggedInTo == _host.text.trim(),
        _Step.prepare => _prepared,
        _Step.reach => false,
      };

  void _goTo(_Step step) => setState(() {
        _step = step;
        _said = null;
      });

  List<Widget> _knownKeyStep(BuildContext context) => <Widget>[
        Text('1. The key root logs in with', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Space.small),
        Text(
          'The key the machine already knows — for one this wizard prepared, ~/.ssh/sokar-<its '
          'name>. It also becomes the key ${widget.workUser} logs in with.',
        ),
        const SizedBox(height: Space.normal),
        TextField(
          key: const Key('root-key-file'),
          controller: _keyFile,
          enabled: _kept == null,
          decoration: const InputDecoration(
            labelText: 'Private key file',
            hintText: '~/.ssh/sokar-the-build-machine',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: Space.normal),
        if (_kept == null)
          FilledButton.tonal(
            key: const Key('use-key'),
            onPressed: _busy || _keyFile.text.trim().isEmpty ? null : _useKey,
            child: const Text('Use this key'),
          ),
      ];

  Future<void> _useKey() => _doing(() async {
        final file = _keyFile.text.trim();
        _public.text = await widget.setup.publicKeyOf(file);
        _kept = file;
        return 'Root logs in with $file, and ${widget.workUser} will too.';
      });

  List<Widget> _keyStep(BuildContext context) => <Widget>[
        Text('1. The key it will be reached with', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Space.small),
        const Text(
          'Paste a key pair you have, or generate one. Either way it is kept in ~/.ssh, owner-only. '
          'It has no passphrase: this interface never asks for one.',
        ),
        const SizedBox(height: Space.normal),
        TextField(
          key: const Key('new-private-key'),
          controller: _private,
          enabled: _kept == null,
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
          enabled: _kept == null,
          maxLines: 2,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          decoration: const InputDecoration(
            labelText: 'Public key',
            hintText: 'ssh-ed25519 AAAA…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: Space.normal),
        if (_kept == null)
          Wrap(
            spacing: Space.small,
            children: <Widget>[
              OutlinedButton.icon(
                key: const Key('generate-key'),
                onPressed: _busy ? null : _generate,
                icon: const Icon(Icons.key_outlined, size: Sizes.rowIcon),
                label: const Text('Generate a key pair'),
              ),
              FilledButton.tonal(
                key: const Key('keep-key'),
                onPressed: _busy || _private.text.trim().isEmpty || _public.text.trim().isEmpty
                    ? null
                    : _keep,
                child: Text('Keep it as ~/.ssh/$_keyName'),
              ),
            ],
          )
        else ...<Widget>[
          Text(
            'Give this public key to the provider when the server is created — for Hetzner, under '
            'SSH keys. A key added afterwards cannot reach a machine that only knows root\'s.',
            key: const Key('give-the-public-key'),
          ),
          const SizedBox(height: Space.small),
          Row(
            children: <Widget>[
              Expanded(
                child: SelectableText(
                  _public.text.trim(),
                  key: const Key('public-key-to-copy'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
              IconButton(
                key: const Key('copy-public-key'),
                icon: const Icon(Icons.copy_outlined, size: Sizes.rowIcon),
                tooltip: 'Copy the public key',
                onPressed: () => Clipboard.setData(ClipboardData(text: _public.text.trim())),
              ),
            ],
          ),
        ],
      ];

  Future<void> _generate() => _doing(() async {
        final pair = await widget.setup.generate('sokar ${widget.name}');
        _private.text = pair.privateKey;
        _public.text = pair.publicKey;
        return null;
      });

  Future<void> _keep() => _doing(() async {
        final pair = KeyPair(privateKey: _private.text, publicKey: _public.text.trim());
        final wrong = await widget.setup.mismatch(pair);
        if (wrong != null) throw MachineSetupFailed(wrong);
        _kept = await widget.setup.save(pair, _keyName);
        return 'Kept as $_kept.';
      });

  List<Widget> _whereStep(BuildContext context) => <Widget>[
        Text('2. Where it is', style: Theme.of(context).textTheme.labelLarge),
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
          onPressed: _busy || _host.text.trim().isEmpty ? null : _tryRoot,
          icon: const Icon(Icons.login, size: Sizes.rowIcon),
          label: const Text('Try logging in as root'),
        ),
      ];

  Future<void> _tryRoot() => _doing(() async {
        final host = _host.text.trim();
        _loggedInTo = null;
        final keys = widget.hostKeys;
        if (keys != null) {
          final check = await keys.check('root@$host');
          if (!mounted) return null;
          if (check.problem != null) throw MachineSetupFailed(check.problem!);
          if (!check.known) {
            if (!await confirmHostKey(context, check)) {
              throw MachineSetupFailed(
                  'The host key of ${check.host} was not trusted, so nothing logged in.');
            }
            await keys.accept(check);
          }
        }
        final failed = await widget.setup.loginAsRoot(host, _kept!);
        if (failed != null) throw MachineSetupFailed(failed);
        _loggedInTo = host;
        return 'Logged in as root on $host with $_kept.';
      });

  List<Widget> _prepareStep(BuildContext context) => <Widget>[
        Text('3. Preparing it', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Space.small),
        Text(
          widget.addingAUser
              ? "Sokar's setup script runs as root. Sokar is there already, so it creates the user "
                  '${widget.workUser} beside the others, with its own daemon and vault. It shows '
                  'every command before it runs; nothing changes until you run it.'
              : "Sokar's setup script runs as root. It creates the user ${widget.workUser}, which "
                  'runs work, and installs Sokar, its filter and the local transport, and whatever '
                  'you choose below. It shows every command before it runs; nothing changes until '
                  'you run it.',
        ),
        const SizedBox(height: Space.normal),
        if (!widget.addingAUser)
          OutlinedButton.icon(
            key: const Key('list-packages'),
            onPressed: _busy || _prepared ? null : _list,
            icon: const Icon(Icons.checklist, size: Sizes.rowIcon),
            label: const Text('See what it can install'),
          ),
        if (_offered != null || widget.addingAUser) ...<Widget>[
          const SizedBox(height: Space.small),
          for (final package in _offered ?? const <InstallablePackage>[])
            CheckboxListTile(
              key: Key('package-${package.name}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: package.installed || _chosen.contains(package.name),
              // Already there is shown, ticked and fixed, rather than hidden: a person should see
              // what the machine has.
              onChanged: package.installed || _prepared
                  ? null
                  : (on) => setState(() => on == true
                      ? _chosen.add(package.name)
                      : _chosen.remove(package.name)),
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
          _Script(text: MachineSetup.show(widget.workUser, _chosen.toList()..sort()), id: 'fetch-script'),
          const SizedBox(height: Space.small),
          OutlinedButton.icon(
            key: const Key('show-setup'),
            onPressed: _busy || _prepared ? null : _show,
            icon: const Icon(Icons.visibility_outlined, size: Sizes.rowIcon),
            label: const Text('Show what it would do'),
          ),
        ],
        if (_shown != null) ...<Widget>[
          const SizedBox(height: Space.normal),
          _Output(text: _shown!, id: 'setup-shown'),
          const SizedBox(height: Space.small),
          if (_shownFor != _choice && !_prepared)
            const Text(
              'The choice changed since this was shown. Show it again before it runs.',
              key: Key('show-again'),
            )
          else
            FilledButton.icon(
              key: const Key('run-setup'),
              onPressed: _busy || _prepared ? null : _prepare,
              icon: const Icon(Icons.play_arrow_outlined, size: Sizes.rowIcon),
              label: const Text('Run it as root'),
            ),
        ],
        if (_ran != null) ...<Widget>[
          const SizedBox(height: Space.normal),
          _Output(text: _ran!, id: 'setup-output'),
        ],
      ];

  Future<void> _list() => _doing(() async {
        final listed = await widget.setup.asRoot(_loggedInTo!, _kept!, MachineSetup.listInstallable());
        if (listed.exitCode != 0) {
          throw MachineSetupFailed(
              '${MachineSetup.whatTheScriptSaid(listed.exitCode)}\n${_both(listed)}'.trim());
        }
        _offered = MachineSetup.installableIn('${listed.stdout}');
        _chosen.removeWhere((name) => !_offered!.any((each) => each.name == name));
        final why = '${listed.stderr}'.trim();
        return _offered!.isEmpty && why.isNotEmpty ? why : null;
      });

  Future<void> _show() => _doing(() async {
        _shown = null;
        final choice = _choice;
        final shown = await widget.setup.asRoot(
            _loggedInTo!, _kept!, MachineSetup.show(widget.workUser, _chosen.toList()..sort()));
        final said = _both(shown);
        if (shown.exitCode != 0) {
          throw MachineSetupFailed('${MachineSetup.whatTheScriptSaid(shown.exitCode)}\n$said');
        }
        _shown = said;
        _shownFor = choice;
        return null;
      });

  Future<void> _prepare() => _doing(() async {
        final ran = await widget.setup.asRoot(
            _loggedInTo!, _kept!, MachineSetup.prepare(widget.workUser, _chosen.toList()..sort()));
        _ran = _both(ran);
        if (ran.exitCode != 0) throw MachineSetupFailed(MachineSetup.whatTheScriptSaid(ran.exitCode));
        _prepared = true;
        return MachineSetup.whatTheScriptSaid(0);
      });

  List<Widget> _reachStep(BuildContext context) => <Widget>[
        Text('4. Reaching it as ${widget.workUser}', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Space.small),
        Text(
          'Lets the key log in as ${widget.workUser} (as root, below), adds Host $_alias to '
          "~/.ssh/config — as ${widget.workUser}, never root — starts Sokar in ${widget.workUser}'s "
          'own session, asks sokar doctor, and connects the way watching it will.',
        ),
        const SizedBox(height: Space.normal),
        _Script(text: MachineSetup.authorize(widget.workUser, _public.text.trim()), id: 'authorize-script'),
        const SizedBox(height: Space.small),
        FilledButton.icon(
          key: const Key('finish-setup'),
          onPressed: _busy || _ready != null ? null : _reach,
          icon: const Icon(Icons.link, size: Sizes.rowIcon),
          label: const Text('Set it up and connect'),
        ),
        if (_log.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.normal),
          _Output(text: _log.join('\n'), id: 'setup-log'),
        ],
        if (_ready != null) ...<Widget>[
          const SizedBox(height: Space.normal),
          const Text(
            'Optional, and only now that the work user has logged in: turn off logging in as root '
            'and with a password. The key above keeps working for the work user.',
          ),
          const SizedBox(height: Space.small),
          _Script(text: MachineSetup.harden, id: 'harden-script'),
          const SizedBox(height: Space.small),
          Wrap(
            spacing: Space.small,
            children: <Widget>[
              OutlinedButton.icon(
                key: const Key('harden'),
                onPressed: _busy || _hardened ? null : _harden,
                icon: const Icon(Icons.shield_outlined, size: Sizes.rowIcon),
                label: const Text('Turn off root and password login'),
              ),
              FilledButton.icon(
                key: const Key('watch-new'),
                onPressed: _busy ? null : () => widget.onWatch(_ready!),
                icon: const Icon(Icons.visibility_outlined, size: Sizes.rowIcon),
                label: const Text('Watch it'),
              ),
            ],
          ),
        ],
      ];

  Future<void> _reach() => _doing(() async {
        _log.clear();
        final user = widget.workUser;
        final allowed = await widget.setup
            .asRoot(_loggedInTo!, _kept!, MachineSetup.authorize(user, _public.text.trim()));
        if (allowed.exitCode != 0) {
          throw MachineSetupFailed('The key could not be allowed for $user: ${_both(allowed)}');
        }
        _log.add('The key logs in as $user.');
        _log.add(await widget.setup.addHostEntry(
            alias: _alias, host: _loggedInTo!, user: user, keyFile: _kept!));
        final started = await widget.setup.asUser(_alias, 'systemctl --user enable --now sokard');
        if (started.exitCode != 0) {
          throw MachineSetupFailed('Sokar did not start as $user: ${_both(started)}');
        }
        _log.add('Sokar runs as $user.');
        final uid = await widget.setup.asUser(_alias, 'id -u');
        final id = '${uid.stdout}'.trim();
        if (uid.exitCode != 0 || int.tryParse(id) == null) {
          throw MachineSetupFailed('Which uid $user has could not be asked: ${_both(uid)}');
        }
        final doctor = await widget.setup.asUser(_alias, 'sokar doctor');
        _log.add('sokar doctor${doctor.exitCode == 0 ? '' : ' (ended with ${doctor.exitCode})'}:');
        _log.add(_both(doctor));
        final machine = Machine(
          name: widget.name,
          socketPath: Machine.endpointFor(widget.name),
          host: _alias,
          remoteSocket: '/run/user/$id/sokar/sokard.sock',
        );
        final trying = widget.trying;
        if (trying != null) {
          final trial = await trying(machine);
          _log.add(trial.words);
          if (!trial.reached) throw MachineSetupFailed('It does not answer yet: ${trial.words}');
        }
        _ready = machine;
        return 'Ready to watch.';
      });

  Future<void> _harden() => _doing(() async {
        final done = await widget.setup.asRoot(_loggedInTo!, _kept!, MachineSetup.harden);
        if (done.exitCode != 0) {
          throw MachineSetupFailed('Root login is still on: ${_both(done)}');
        }
        _hardened = true;
        return 'Logging in as root and with a password is off.';
      });

  static String _both(ProcessResult result) => <String>[
        '${result.stdout}'.trim(),
        '${result.stderr}'.trim(),
      ].where((each) => each.isNotEmpty).join('\n');

  /// Runs one action of a step, saying what it did or why it could not.
  Future<void> _doing(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _said = null;
    });
    String? said;
    var bad = false;
    try {
      said = await action();
    } on MachineSetupFailed catch (ex) {
      said = ex.message;
      bad = true;
    } on Exception catch (ex) {
      // Anything else still ends the step with words rather than leaving it busy for ever. What a
      // file or process error says names paths and programs, never a key's contents.
      said = 'That did not work: $ex';
      bad = true;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _said = said;
      _saidIsBad = bad;
    });
  }
}

/// A script that is about to run as root, shown exactly as it will run.
class _Script extends StatelessWidget {
  const _Script({required this.text, required this.id});

  final String text;
  final String id;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        padding: const EdgeInsets.all(Space.small),
        child: SelectableText(
          text.trim(),
          key: Key(id),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
      );
}

/// What a program printed, scrollable when it is long.
class _Output extends StatelessWidget {
  const _Output({required this.text, required this.id});

  final String text;
  final String id;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            key: Key(id),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
      );
}
