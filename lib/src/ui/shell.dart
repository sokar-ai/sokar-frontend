import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/commands.dart';
import '../app/fleet_model.dart';
import '../app/settings.dart';
import '../app/shell_model.dart';
import 'command_finder.dart';
import 'panes.dart';
import 'status_line.dart';

/// The one window: projects, the work under the selected project, and a detail over both.
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
    super.key,
  });

  /// What is on the machine.
  final FleetModel fleet;

  /// What is open and where the keyboard is.
  final ShellModel shell;

  /// How the interface looks.
  final Settings settings;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _projectsFocus = FocusNode(debugLabel: 'projects');
  final _workFocus = FocusNode(debugLabel: 'work');

  /// Below this the two panes stop fitting side by side and the frame shows one at a time.
  ///
  /// A dense arrangement that merely shrinks becomes unreachable before it becomes unreadable,
  /// so it falls back to a simpler one instead.
  static const _twoPanes = 640.0;

  /// Above this there is room for the detail beside the work rather than over it.
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
      case Pane.detail:
        break;
    }
  }

  List<Command> _commands() => commandsFor(
        fleet: widget.fleet,
        shell: widget.shell,
        settings: widget.settings,
        openFinder: _openFinder,
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
                StatusLine(fleet: widget.fleet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final task = widget.fleet.selectedTask;
    final detailOpen = widget.shell.detailOpen && task != null;

    if (constraints.maxWidth < _twoPanes) return _onePane(detailOpen: detailOpen);

    final projects = SizedBox(
      width: 260,
      child: ProjectsPane(
        fleet: widget.fleet,
        focusNode: _projectsFocus,
        onActivate: () => widget.shell.focus(Pane.work),
      ),
    );
    final work = WorkPane(
      fleet: widget.fleet,
      focusNode: _workFocus,
      onActivate: _openWork,
    );
    // Built only where it is shown: with nothing selected there is no work to draw.
    // Wide enough keeps the work list beside the detail; otherwise the detail takes the space
    // the work list had, which is still opening over the frame rather than navigating away.
    if (detailOpen && constraints.maxWidth >= _threePanes) {
      return Row(
        children: <Widget>[
          projects,
          const VerticalDivider(width: 1),
          Expanded(child: work),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 420,
            child: WorkDetail(task: task, onClose: widget.shell.closeDetail),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        projects,
        const VerticalDivider(width: 1),
        Expanded(
          child: detailOpen
              ? WorkDetail(task: task, onClose: widget.shell.closeDetail)
              : work,
        ),
      ],
    );
  }

  Widget _onePane({required bool detailOpen}) {
    if (detailOpen) {
      return WorkDetail(
        task: widget.fleet.selectedTask!,
        onClose: widget.shell.closeDetail,
      );
    }
    if (widget.shell.pane == Pane.work && widget.fleet.selectedProject != null) {
      return WorkPane(
        fleet: widget.fleet,
        focusNode: _workFocus,
        onActivate: _openWork,
        leading: BackButton(onPressed: () => widget.shell.focus(Pane.projects)),
      );
    }
    return ProjectsPane(
      fleet: widget.fleet,
      focusNode: _projectsFocus,
      onActivate: () => widget.shell.focus(Pane.work),
    );
  }

  @override
  void dispose() {
    widget.shell.removeListener(_moveKeyboard);
    _projectsFocus.dispose();
    _workFocus.dispose();
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
