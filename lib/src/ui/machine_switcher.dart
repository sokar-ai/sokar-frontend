import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/fleet_model.dart';
import '../app/machines.dart';
import 'tokens.dart';

/// Which machine everything below is about.
///
/// Above the rail rather than inside it, and pinned rather than scrollable, because *which host
/// an action will act on must never be ambiguous* — and a host that is a collapsible ancestor of
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
                _Reach(fleet: machines.of(current)),
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
              leadingIcon: _Reach(fleet: machines.of(machine)),
              trailingIcon: machine == current ? const Icon(Icons.check, size: 16) : null,
              onPressed: () => machines.select(machine),
              child: Text(machine.name),
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
class _Reach extends StatelessWidget {
  const _Reach({required this.fleet});

  final FleetModel fleet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color colour, String words) = switch (fleet.reachability) {
      Reachability.connecting => (Icons.cloud_queue, scheme.outline, 'Connecting'),
      Reachability.connected => (Icons.cloud_done, scheme.primary, 'Answering'),
      Reachability.unreachable => (Icons.cloud_off, scheme.error, 'Not answering'),
      Reachability.incompatible => (Icons.report, scheme.error, 'Speaks nothing this build knows'),
    };
    return Tooltip(
      message: '${fleet.backend.label}: $words',
      child: Icon(icon, size: Sizes.mark, color: colour),
    );
  }
}

/// Asks for another machine to watch.
///
/// A name and a socket path, because that is the whole of what a machine is here. Raising the
/// forward is somebody else's job today —
/// [F27](../../../requirements/F27-Managed-Tunnels.md) is the interface doing it.
Future<Machine?> askForAMachine(BuildContext context) =>
    showDialog<Machine>(
      context: context,
      builder: (context) => const _AskForAMachine(),
    );

class _AskForAMachine extends StatefulWidget {
  const _AskForAMachine();

  @override
  State<_AskForAMachine> createState() => _AskForAMachineState();
}

class _AskForAMachineState extends State<_AskForAMachine> {
  final _name = TextEditingController();
  final _socket = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The recipe names the socket being asked for, so it follows what is typed rather than
    // showing an example that has to be edited twice — once here and once in the shell.
    _socket.addListener(() => setState(() {}));
  }

  /// The line that forwards the socket, with the local end filled in.
  String get _recipe {
    final local = _socket.text.trim().isEmpty
        ? '/tmp/sokard-remote.sock'
        : _socket.text.trim();
    return 'ssh -L $local:/run/user/1001/sokar/sokard.sock user@host -N';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Watch another machine'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What to call it',
                  hintText: 'the build machine',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Space.normal),
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
                'code. Raising the tunnel is not this interface’s job yet.',
                key: const Key('how-to-forward'),
                style: Theme.of(context).textTheme.bodySmall,
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
            onPressed: () {
              final name = _name.text.trim();
              final socket = _socket.text.trim();
              if (name.isEmpty || socket.isEmpty) return;
              Navigator.of(context)
                  .pop(Machine(name: name, socketPath: socket));
            },
            child: const Text('Watch it'),
          ),
        ],
      );

  @override
  void dispose() {
    _name.dispose();
    _socket.dispose();
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
            icon: const Icon(Icons.copy, size: Sizes.rowIcon),
            tooltip: 'Copy the command',
            onPressed: () => Clipboard.setData(ClipboardData(text: command)),
          ),
        ],
      ),
    );
  }
}
