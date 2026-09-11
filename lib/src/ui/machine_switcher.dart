import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/fleet_model.dart';
import '../app/machines.dart';
import '../app/tunnel.dart';
import 'tokens.dart';

/// Which machine everything below is about.
///
/// Above the rail rather than inside it, and pinned rather than scrollable, because *which
/// machine an action will act on must never be ambiguous* — and a machine that is a collapsible
/// ancestor of
/// a tree scrolls out of view, leaving a row that does not say which machine it is on. That is
/// how somebody stops a task on the wrong one.
///
/// It is also a different axis from the rail. The rail is *where in the product*; this is *on
/// which machine*, and every section below is about the one named here.
class MachineSwitcher extends StatelessWidget {
  /// Constructor taking the machines and the ways to change them.
  const MachineSwitcher({
    required this.machines,
    required this.onAdd,
    required this.extended,
    super.key,
  });

  /// Every machine being watched, and which is being acted on.
  final Machines machines;

  /// Asks for another machine to watch.
  final VoidCallback onAdd;

  /// Whether there is room to say the name in full.
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final current = machines.current;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.small,
        vertical: Space.small,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: MenuAnchor(
        builder: (context, controller, _) => InkWell(
          key: const Key('machine-switcher'),
          borderRadius: BorderRadius.circular(Radii.medium),
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: Padding(
            padding: const EdgeInsets.all(Space.small),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Reach(
                  name: current.name,
                  fleet: machines.of(current),
                  tunnel: machines.tunnels.of(current),
                ),
                if (extended) ...<Widget>[
                  const SizedBox(width: Space.small),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      current.name,
                      key: const Key('current-machine'),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: Sizes.rowIcon),
                ],
              ],
            ),
          ),
        ),
        menuChildren: <Widget>[
          for (final machine in machines.all)
            MenuItemButton(
              leadingIcon: _Reach(
                name: machine.name,
                fleet: machines.of(machine),
                tunnel: machines.tunnels.of(machine),
              ),
              trailingIcon:
                  machine == current ? const Icon(Icons.check, size: Sizes.mark) : null,
              onPressed: () => machines.select(machine),
              // Which of the two kinds it is, said rather than left to be inferred: it decides
              // what happens when it stops answering, and what happens when the window closes.
              //
              // And whether it is a second way in to a node already listed. **That is asked, not
              // worked out**: a hostname has many spellings and a forwarded socket looks nothing
              // like a tunnel raised here. Left unsaid, every clearance question on that node
              // arrives twice and answering one leaves the other expiring.
              child: Text(_describe(machines, machine)),
            ),
          const Divider(height: 1),
          MenuItemButton(
            leadingIcon: const Icon(Icons.add, size: Sizes.rowIcon),
            onPressed: onAdd,
            child: const Text('Watch another machine…'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.delete_outline, size: Sizes.rowIcon),
            // Never the last one: a frame with no machine behind it has nothing to say and no way
            // to say why.
            onPressed:
                machines.all.length > 1 ? () => machines.forget(current) : null,
            child: Text('Forget ${current.name}'),
          ),
        ],
      ),
    );
  }
}

/// Whether one machine is answering, in the space of an icon.
/// What one entry says about itself in the list.
String _describe(Machines machines, Machine machine) {
  final also = machines.sameNodeAs(machine);
  final same = also.isEmpty
      ? ''
      : '  ·  the same node as ${also.map((each) => each.name).join(', ')}';
  return machine.needsATunnel
      ? '${machine.name}  ·  forward raised here$same'
      : '${machine.name}$same';
}

class _Reach extends StatelessWidget {
  const _Reach({required this.name, required this.fleet, this.tunnel});

  /// The machine, by the name on screen beside it — not the backend's own label, which is what
  /// the transport calls it and need not be what a person does.
  final String name;

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
        {Iterable<String> taken = const <String>[]}) =>
    showDialog<Machine>(
      context: context,
      builder: (context) => _AskForAMachine(taken: taken.toList()),
    );

class _AskForAMachine extends StatefulWidget {
  const _AskForAMachine({required this.taken});

  /// The names already watched. A second with the same name would never be added.
  final List<String> taken;

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

  bool get _ready {
    if (_name.text.trim().isEmpty || _raiseIt == null || _takenBy != null) return false;
    return _raiseIt!
        ? _host.text.trim().isNotEmpty && _remote.text.trim().isNotEmpty
        : _socket.text.trim().isNotEmpty;
  }

  void _watchIt() {
    final name = _name.text.trim();
    Navigator.of(context).pop(
      _raiseIt!
          // The local end is ours to choose, and it goes where the runtime directory already
          // makes it owner-only. Asking somebody for a path they do not care about would be one
          // more thing to get almost right.
          ? Machine(
              name: name,
              socketPath: Machine.endpointFor(name),
              host: _host.text.trim(),
              remoteSocket: _remote.text.trim(),
            )
          : Machine(name: name, socketPath: _socket.text.trim()),
    );
  }

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
