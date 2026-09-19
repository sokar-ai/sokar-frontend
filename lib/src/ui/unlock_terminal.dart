import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../app/machines.dart';
import '../app/session.dart';
import 'tokens.dart';

/// Opens [machine]'s vault by its passphrase, typed into a terminal running [command] there.
///
/// The only way from here to a vault nothing has opened yet: unlocking with a device needs the
/// device enrolled, and enrolling needs the vault open. Returns once the dialog is put away.
Future<void> unlockInATerminal(
  BuildContext context, {
  required Machine machine,
  required List<String> command,
  OpenTerminal? open,
}) =>
    runInATerminal(
      context,
      title: 'Open the vault on ${machine.name}',
      explanation: "Type the vault's passphrase into the terminal. It goes straight to the machine "
          'and never through this program, and nothing here keeps it.',
      machine: machine,
      command: command,
      open: open,
    );

/// Runs [command] on [machine] in a terminal a person types into, for a value this program must
/// never hold. Returns once the dialog is put away; what came of it is asked of the machine then.
Future<void> runInATerminal(
  BuildContext context, {
  required String title,
  required String explanation,
  required Machine machine,
  required List<String> command,
  OpenTerminal? open,
}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UnlockTerminal(
          title: title, explanation: explanation, machine: machine, command: command, open: open),
    );

class _UnlockTerminal extends StatefulWidget {
  const _UnlockTerminal(
      {required this.title,
      required this.explanation,
      required this.machine,
      required this.command,
      this.open});

  final String title;
  final String explanation;
  final Machine machine;
  final List<String> command;
  final OpenTerminal? open;

  @override
  State<_UnlockTerminal> createState() => _UnlockTerminalState();
}

class _UnlockTerminalState extends State<_UnlockTerminal> {
  late final Session _session = Session(
    task: 'vault',
    machine: widget.machine,
    open: widget.open,
    run: widget.command,
  )..addListener(_changed);

  // Asked for once the dialog is on screen: an autofocus inside a dialog loses to its buttons.
  final _keyboard = FocusNode(debugLabel: 'terminal in a dialog');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboard.requestFocus();
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session
      ..removeListener(_changed)
      ..dispose();
    _keyboard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: Sizes.dialog,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.explanation, key: const Key('unlock-explained')),
              const SizedBox(height: Space.small),
              SelectableText(widget.command.join(' '),
                  key: const Key('unlock-command'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              const SizedBox(height: Space.small),
              SizedBox(
                height: Sizes.terminal,
                child: ColoredBox(
                  color: const Color(0xFF1E1E1E),
                  child: TerminalView(
                    _session.terminal,
                    key: const Key('unlock-terminal'),
                    focusNode: _keyboard,
                    autofocus: true,
                    readOnly: !_session.live,
                    padding: const EdgeInsets.all(Space.small),
                    textStyle: const TerminalStyle(fontSize: 12),
                  ),
                ),
              ),
              if (_session.state == SessionState.over) ...<Widget>[
                const SizedBox(height: Space.small),
                Text(
                  _session.problem ?? 'The terminal has ended. What came of it is asked of the '
                      'machine when this is put away.',
                  key: const Key('unlock-ended'),
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          FilledButton(
            key: const Key('unlock-done'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_session.state == SessionState.over ? 'Done' : 'Put it away'),
          ),
        ],
      );
}
