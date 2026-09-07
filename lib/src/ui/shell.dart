import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/commands.dart';
import '../app/fleet_model.dart';
import '../app/operations.dart';
import '../app/settings.dart';
import '../app/shell_model.dart';
import 'command_finder.dart';
import 'operations.dart';
import 'panes.dart';
import 'status_line.dart';

/// The one window: projects, the work under the selected project, and whatever is open over both.
///
/// Everything else in the product opens over this frame rather than navigating away from it. If
/// moving between the overview and a detail were expensive people would stop looking, and the
/// state of the machine would stop being known.
class Shell extends StatefulWidget {
  /// Constructor taking everything the frame renders and acts on.
  const Shell({
    required this.fleet,
    required this.shell,
    required this.settings,
    required this.operations,
    super.key,
  });

  /// What is on the machine.
  final FleetModel fleet;

  /// What is open and where the keyboard is.
  final ShellModel shell;

  /// How the interface looks.
  final Settings settings;

  /// What this session has run.
  final Operations operations;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _projectsFocus = FocusNode(debugLabel: 'projects');
  final _workFocus = FocusNode(debugLabel: 'work');
  final _openedFocus = FocusNode(debugLabel: 'opened');

  /// Below this the two panes stop fitting side by side and the frame shows one at a time.
  ///
  /// A dense arrangement that merely shrinks becomes unreachable before it becomes unreadable,
  /// so it falls back to a simpler one instead.
  static const _twoPanes = 640.0;

  /// Above this there is room for what is open beside the work rather than over it.
  static const _threePanes = 1000.0;

  @override
  void initState() {
    super.initState();
    widget.shell.addListener(_moveKeyboard);
    WidgetsBinding.instance.addPostFrameCallback((_) => _moveKeyboard());
  }

  void _moveKeyboard() {
    if (!mounted) return;
    switch (widget.shell.pane) {
      case Pane.projects:
        _projectsFocus.requestFocus();
      case Pane.work:
        _workFocus.requestFocus();
      case Pane.opened:
        _openedFocus.requestFocus();
    }
  }

  List<Command> _commands() => commandsFor(
        fleet: widget.fleet,
        shell: widget.shell,
        settings: widget.settings,
        operations: widget.operations,
        openFinder: _openFinder,
        checkWorkCanStart: _checkWorkCanStart,
        quit: () => SystemNavigator.pop(),
      );

  Future<void> _openFinder() async {
    final chosen = await showCommandFinder(context, _commands());
    chosen?.run();
  }

  void _openWork() {
    if (widget.fleet.selectedTask == null) return;
    widget.shell.openDetail();
  }

  /// Runs the one long operation the frame has today, and opens it.
  ///
  /// A dry run on purpose: it does everything up to starting a container and then reports,
  /// creating nothing. Starting work for real is
  /// [F08](../../../requirements/F08-Task-Creation-And-Modes.md), which fills in the choosing
  /// this deliberately does not do.
  void _checkWorkCanStart() {
    final operation = widget.operations.run(
      title: 'Check that work can start',
      output: widget.fleet.backend.startTask(dryRun: true),
    );
    widget.shell.openOperation(operation.id);
  }

  @override
  Widget build(BuildContext context) {
    final commands = _commands();
    final shortcuts = <ShortcutActivator, Intent>{
      for (final command in commands)
        if (command.shortcut != null) command.shortcut!: _RunCommand(command.id),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _RunCommand: CallbackAction<_RunCommand>(
            onInvoke: (intent) {
              for (final command in commands) {
                if (command.id != intent.id) continue;
                if (command.available) command.run();
                return null;
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(child: LayoutBuilder(builder: _layout)),
                StatusLine(
                  fleet: widget.fleet,
                  operations: widget.operations,
                  onShowOperations: widget.shell.openOperations,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What is open over the frame, or null when nothing is.
  ///
  /// Resolved rather than read straight off the model, because what a view points at can go away
  /// underneath it: work that stopped existing, an operation this session never had. Falling back
  /// beats rendering nothing at all.
  Widget? _opened() {
    switch (widget.shell.opened) {
      case NothingOpened():
        return null;
      case WorkOpened():
        final task = widget.fleet.selectedTask;
        if (task == null) return null;
        return WorkDetail(task: task, onClose: widget.shell.close);
      case OperationsOpened():
        return _operationsList();
      case OperationOpened(:final id):
        final operation = widget.operations.byId(id);
        if (operation == null) return _operationsList();
        return OperationOutputView(
          operation: operation,
          onBack: widget.shell.openOperations,
          onClose: widget.shell.close,
        );
    }
  }

  Widget _operationsList() => OperationsList(
        operations: widget.operations,
        focusNode: _openedFocus,
        onOpen: widget.shell.openOperation,
        onClose: widget.shell.close,
      );

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final opened = _opened();

    if (constraints.maxWidth < _twoPanes) return _onePane(opened);

    final projects = SizedBox(
      width: 260,
      child: ProjectsPane(
        fleet: widget.fleet,
        focusNode: _projectsFocus,
        onFocused: () => widget.shell.focus(Pane.projects),
        onActivate: () => widget.shell.focus(Pane.work),
      ),
    );
    final work = WorkPane(
      fleet: widget.fleet,
      focusNode: _workFocus,
      onFocused: () => widget.shell.focus(Pane.work),
      onActivate: _openWork,
    );

    // Wide enough keeps the work list beside what is open; otherwise the open thing takes the
    // space the work list had, which is still opening over the frame rather than navigating away.
    if (opened != null && constraints.maxWidth >= _threePanes) {
      return Row(
        children: <Widget>[
          projects,
          const VerticalDivider(width: 1),
          Expanded(child: work),
          const VerticalDivider(width: 1),
          SizedBox(width: 420, child: opened),
        ],
      );
    }

    return Row(
      children: <Widget>[
        projects,
        const VerticalDivider(width: 1),
        Expanded(child: opened ?? work),
      ],
    );
  }

  Widget _onePane(Widget? opened) {
    if (opened != null) return opened;
    if (widget.shell.pane == Pane.work && widget.fleet.selectedProject != null) {
      return WorkPane(
        fleet: widget.fleet,
        focusNode: _workFocus,
        onFocused: () => widget.shell.focus(Pane.work),
        onActivate: _openWork,
        leading: BackButton(onPressed: () => widget.shell.focus(Pane.projects)),
      );
    }
    return ProjectsPane(
      fleet: widget.fleet,
      focusNode: _projectsFocus,
      onFocused: () => widget.shell.focus(Pane.projects),
      onActivate: () => widget.shell.focus(Pane.work),
    );
  }

  @override
  void dispose() {
    widget.shell.removeListener(_moveKeyboard);
    _projectsFocus.dispose();
    _workFocus.dispose();
    _openedFocus.dispose();
    super.dispose();
  }
}

/// Runs the command with this id, whatever key or menu asked for it.
///
/// One path from a keystroke to an action, shared with the finder, so a shortcut cannot come to
/// mean something other than the entry that names it.
class _RunCommand extends Intent {
  const _RunCommand(this.id);

  final String id;
}
