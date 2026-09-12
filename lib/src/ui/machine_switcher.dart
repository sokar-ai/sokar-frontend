import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/connection_trial.dart';
import '../app/fleet_model.dart';
import '../app/machines.dart';
import '../app/tunnel.dart';
import 'tokens.dart';

/// What one machine says about itself: the kind of way in, and whether it is a second way in to
/// a node already listed. **That is asked, not worked out**: a hostname has many spellings, and a
/// forwarded socket looks nothing like a tunnel raised here.
String describeMachine(Machines machines, Machine machine) =>
    '${machine.name}${machineKind(machines, machine)}';

/// What [describeMachine] says after the name: empty for a plain socket.
String machineKind(Machines machines, Machine machine) {
  final also = machines.sameNodeAs(machine);
  final same = also.isEmpty
      ? ''
      : '  ·  the same node as ${also.map((each) => each.name).join(', ')}';
  return machine.needsATunnel ? '  ·  forward raised here$same' : same;
}

/// Whether one machine is answering, in the space of an icon.
class ReachIcon extends StatelessWidget {
  /// Constructor taking the machine's name, its model and the forward raised for it.
  const ReachIcon({required this.name, required this.fleet, this.tunnel, super.key});

  /// The machine, by the name on screen beside it — not the backend's own label, which is what
  /// the transport calls it and need not be what a person does.
  final String name;

  /// The machine's model.
  final FleetModel fleet;

  /// The forward this interface raised for it, or null when somebody else did.
  final Tunnel? tunnel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String words) = switch (fleet.reachability) {
      Reachability.connecting => (Icons.cloud_queue, scheme.outline, 'Connecting'),
      Reachability.connected => (Icons.cloud_done, scheme.primary, 'Answering'),
      Reachability.unreachable => (Icons.cloud_off, scheme.error, 'Not answering'),
      Reachability.incompatible =>
        (Icons.warning_amber_outlined, scheme.error, 'Speaks nothing this build knows'),
    };
    // The transport's own sentence wins over ours. "Host key verification failed" is a different
    // problem from a machine that is simply not there, and only one of them can be acted on.
    final said = tunnel?.words;
    return Tooltip(
      message: said == null ? '$name: $words' : '$name: $said',
      child: Icon(icon, size: Sizes.mark, color: color),
    );
  }
}

/// Asks for another machine to watch.
///
/// **Two kinds, and the difference is who raises the forward.** A socket somebody else forwarded
/// is opened exactly as it always was — that path has no credential handling in it at all and
/// must keep working untouched. A machine described by where it *is* has its forward raised here,
/// supervised, and taken down when the window closes.
Future<Machine?> askForAMachine(BuildContext context,
        {Iterable<String> taken = const <String>[],
        Future<Trial> Function(Machine)? trying,
        Future<Started> Function(Machine)? starting}) =>
    showDialog<Machine>(
      context: context,
      builder: (context) =>
          _AskForAMachine(taken: taken.toList(), trying: trying, starting: starting),
    );

class _AskForAMachine extends StatefulWidget {
  const _AskForAMachine({required this.taken, this.trying, this.starting});

  /// The names already watched. A second with the same name would never be added.
  final List<String> taken;

  /// Tries a machine before it is watched, or null where nothing can.
  final Future<Trial> Function(Machine)? trying;

  /// Starts a daemon on it, when the trial found ssh working and nothing serving.
  final Future<Started> Function(Machine)? starting;

  @override
  State<_AskForAMachine> createState() => _AskForAMachineState();
}

class _AskForAMachineState extends State<_AskForAMachine> {
  final _name = TextEditingController();
  final _socket = TextEditingController();
  final _host = TextEditingController();
  // Empty, never prefilled: the uid is the other machine's, and a guess nobody corrects looks like a
  // machine that never answers.
  final _remote = TextEditingController();
  final _nameFocus = FocusNode();
  bool _nameLeft = false;

  Trial? _trial;
  String _triedFor = '';
  bool _trying = false;
  int _attempt = 0;

  /// What a start said, kept after the trial that follows it so the two read together.
  String? _startSaid;
  bool _starting = false;

  /// Whether the offer to start was turned down. Asked once per try, never again unprompted.
  bool _declined = false;

  /// Whether this interface raises the forward. **Nothing is preselected**: the two are different
  /// commitments — one of them starts a process and owns it — and a default would make that
  /// choice for somebody.
  bool? _raiseIt;

  @override
  void initState() {
    super.initState();
    // Every field, not only the socket. The recipe follows what is typed rather than showing an
    // example that has to be edited twice — and *"Watch it"* is enabled by what has been filled
    // in, which without a listener is decided once and never again. It was: the button stayed
    // dead however much was typed.
    for (final field in <TextEditingController>[_name, _socket, _host, _remote]) {
      field.addListener(() => setState(() {}));
    }
    // Marked once somebody moves on from the name, not while they are still typing it.
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && !_nameLeft) setState(() => _nameLeft = true);
    });
  }

  /// Which watched machine already has this name, or one that would share its forward.
  String? get _takenBy {
    final wanted = Machine.slug(_name.text.trim());
    if (wanted.isEmpty) return null;
    for (final each in widget.taken) {
      if (Machine.slug(each) == wanted) return each;
    }
    return null;
  }

  /// The line that forwards the socket, with the local end filled in.
  String get _recipe {
    final local = _socket.text.trim().isEmpty
        ? '/tmp/sokard-remote.sock'
        : _socket.text.trim();
    return 'ssh -L $local:/run/user/<uid>/sokar/sokard.sock user@host -N';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Watch another machine'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Always a tooltip, shown only when it has something to say: toggling the wrapper
                // would rebuild the field and take the cursor out of it mid-word.
                TooltipVisibility(
                  visible: _takenBy != null,
                  child: Tooltip(
                    message: 'A machine called ${_takenBy ?? ''} is already watched',
                    child: TextField(
                      key: const Key('machine-name'),
                      controller: _name,
                      focusNode: _nameFocus,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'What to call it',
                        hintText: 'the build machine',
                        errorText: _nameLeft && _takenBy != null ? 'Already taken' : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.wide),
                Text('How to reach it', style: Theme.of(context).textTheme.labelLarge),
                RadioGroup<bool>(
                  groupValue: _raiseIt,
                  onChanged: (chosen) => setState(() => _raiseIt = chosen),
                  child: const Column(
                    children: <Widget>[
                      RadioListTile<bool>(
                        key: Key('machine-already-forwarded'),
                        value: false,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Its socket is already forwarded'),
                        subtitle: Text(
                          'Nothing is raised and nothing is managed. This is the way in with no '
                          'credential handling anywhere near it.',
                        ),
                      ),
                      RadioListTile<bool>(
                        key: Key('machine-raise-it'),
                        value: true,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Raise the forward for me'),
                        subtitle: Text(
                          'An ssh forward, started here and taken down when this window closes. '
                          'It never asks for a passphrase: use an agent, and accept the host key '
                          'once in a shell.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.normal),
                if (_raiseIt == true) ...<Widget>[
                  TextField(
                    controller: _host,
                    key: const Key('machine-host'),
                    decoration: const InputDecoration(
                      labelText: 'Where it is',
                      hintText: 'user@build.example.test',
                      helperText: 'Given to ssh as it stands, so anything in your ssh config '
                          'works — including a Host alias.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Space.normal),
                  TextField(
                    controller: _remote,
                    key: const Key('machine-remote-socket'),
                    decoration: const InputDecoration(
                      labelText: 'Its socket, on that machine',
                      hintText: '/run/user/<uid>/sokar/sokard.sock',
                      helperText: 'The uid is that of the user you log in as, on that machine.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else if (_raiseIt == false) ...<Widget>[
                  TextField(
                    controller: _socket,
                    key: const Key('machine-socket'),
                    decoration: const InputDecoration(
                      labelText: 'Forwarded socket',
                      hintText: '/tmp/sokard-remote.sock',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Space.normal),
                  Text(
                    'Forward it first, and this opens it:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: Space.tight),
                  _Recipe(command: _recipe),
                  const SizedBox(height: Space.normal),
                  Text(
                    'A remote Sokar is its own socket, forwarded — same calls, same replies, same '
                    'code.',
                    key: const Key('how-to-forward'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_raiseIt != null && widget.trying != null) ..._trialRow(context),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('watch-it'),
            onPressed: _ready ? _watchIt : null,
            child: const Text('Watch it'),
          ),
        ],
      );

  /// The button that tries it, and what the last try found while the fields still say the same.
  List<Widget> _trialRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trial = _triedFor == _signature ? _trial : null;
    return <Widget>[
      const SizedBox(height: Space.normal),
      Row(
        children: <Widget>[
          OutlinedButton.icon(
            key: const Key('try-it'),
            onPressed: _canTry && !_trying ? _tryIt : null,
            icon: const Icon(Icons.network_check, size: Sizes.rowIcon),
            label: const Text('Try the connection'),
          ),
          if (_trying) ...<Widget>[
            const SizedBox(width: Space.normal),
            const SizedBox.square(
              dimension: Sizes.mark,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: Space.small),
            const Text('Trying…'),
          ],
        ],
      ),
      if (trial != null) ...<Widget>[
        const SizedBox(height: Space.small),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              trial.reached ? Icons.check_circle_outline : Icons.error_outline,
              size: Sizes.rowIcon,
              color: trial.reached ? scheme.primary : scheme.error,
            ),
            const SizedBox(width: Space.small),
            Expanded(child: SelectableText(trial.words, key: const Key('trial-result'))),
          ],
        ),
      ],
      // Outside the offer, and deliberately: what a start said is worth reading next to the trial
      // that followed it, including the one that then succeeded and took the offer away.
      if (_startSaid != null) ...<Widget>[
        const SizedBox(height: Space.small),
        SelectableText(_startSaid!, key: const Key('start-result')),
      ],
      if (trial != null &&
          !trial.reached &&
          trial.nothingServing &&
          widget.starting != null &&
          !_declined)
        ..._offerToStart(context),
    ];
  }

  /// The offer to start a daemon at the far end, with the line it would run.
  ///
  /// **A question, never a default.** Running something on somebody else's machine is a step past
  /// forwarding a socket, and the line is shown in full because that is what is being agreed to.
  List<Widget> _offerToStart(BuildContext context) => <Widget>[
        const SizedBox(height: Space.normal),
        Text(
          'Nothing serves there. Start Sokar on ${_host.text.trim()}?',
          key: const Key('offer-to-start'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Space.tight),
        _Recipe(command: Tunnels.startCommandFor(_described).join(' ')),
        const SizedBox(height: Space.small),
        Row(
          children: <Widget>[
            FilledButton(
              key: const Key('start-it'),
              onPressed: _starting ? null : _startIt,
              child: const Text('Start it'),
            ),
            const SizedBox(width: Space.small),
            TextButton(
              key: const Key('not-now'),
              onPressed: _starting ? null : () => setState(() => _declined = true),
              child: const Text('Not now'),
            ),
            if (_starting) ...<Widget>[
              const SizedBox(width: Space.normal),
              const SizedBox.square(
                dimension: Sizes.mark,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: Space.small),
              const Text('Starting…'),
            ],
          ],
        ),
      ];

  /// Starts it, and tries again by itself: a start nobody verified is a claim, not an answer.
  Future<void> _startIt() async {
    setState(() {
      _starting = true;
      _startSaid = null;
    });
    final started = await widget.starting!(_described);
    if (!mounted) return;
    setState(() {
      _starting = false;
      _startSaid = started.words;
    });
    if (started.went) await _tryIt(afterAStart: true);
  }

  /// What the fields describe, so an answer about other fields is never shown against these.
  String get _signature =>
      '$_raiseIt|${_host.text.trim()}|${_remote.text.trim()}|${_socket.text.trim()}';

  bool get _canTry {
    if (_raiseIt == null) return false;
    return _raiseIt!
        ? _host.text.trim().isNotEmpty && _remote.text.trim().isNotEmpty
        : _socket.text.trim().isNotEmpty;
  }

  Future<void> _tryIt({bool afterAStart = false}) async {
    final trying = widget.trying!;
    final attempt = ++_attempt;
    final signature = _signature;
    setState(() {
      _trying = true;
      // A try somebody asked for is a fresh question, so the offer comes back and what an earlier
      // start said goes. The try that follows a start keeps both: they are one answer.
      if (!afterAStart) {
        _declined = false;
        _startSaid = null;
      }
    });
    final trial = await trying(_described);
    if (!mounted || attempt != _attempt) return;
    setState(() {
      _trying = false;
      _trial = trial;
      _triedFor = signature;
    });
  }

  /// The machine the fields describe.
  Machine get _described {
    final name = _name.text.trim().isEmpty ? 'new machine' : _name.text.trim();
    return _raiseIt!
        // The local end is ours to choose, and it goes where the runtime directory already
        // makes it owner-only. Asking somebody for a path they do not care about would be one
        // more thing to get almost right.
        ? Machine(
            name: name,
            socketPath: Machine.endpointFor(name),
            host: _host.text.trim(),
            remoteSocket: _remote.text.trim(),
          )
        : Machine(name: name, socketPath: _socket.text.trim());
  }

  bool get _ready {
    if (_name.text.trim().isEmpty || _raiseIt == null || _takenBy != null) return false;
    return _raiseIt!
        ? _host.text.trim().isNotEmpty && _remote.text.trim().isNotEmpty
        : _socket.text.trim().isNotEmpty;
  }

  void _watchIt() => Navigator.of(context).pop(_described);

  @override
  void dispose() {
    _name.dispose();
    _socket.dispose();
    _host.dispose();
    _remote.dispose();
    _nameFocus.dispose();
    super.dispose();
  }
}

/// The line that raises the forward, ready to be taken to a shell.
///
/// Copyable rather than only readable: it is going to be typed into a terminal, and retyping a
/// socket path from a screen is how a path ends up almost right.
class _Recipe extends StatelessWidget {
  const _Recipe({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.small),
      ),
      padding: const EdgeInsets.fromLTRB(Space.normal, Space.small, Space.tight, Space.small),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SelectableText(
              command,
              key: const Key('forwarding-command'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: Sizes.rowIcon),
            tooltip: 'Copy the command',
            onPressed: () => Clipboard.setData(ClipboardData(text: command)),
          ),
        ],
      ),
    );
  }
}
