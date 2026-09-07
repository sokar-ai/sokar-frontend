import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/commands.dart';
import '../app/fleet_model.dart';
import '../app/egress.dart';
import '../app/gate.dart';
import '../app/logs.dart';
import '../app/notifications.dart';
import '../app/machines.dart';
import '../app/newer_version.dart';
import '../app/operations.dart';
import '../app/settings.dart';
import '../app/shell_model.dart';
import 'package:sokar_frontend/client.dart';

import 'command_finder.dart';
import 'clearance_view.dart';
import 'command_menu_bar.dart';
import 'egress_view.dart';
import 'gate_view.dart';
import 'leaving.dart';
import 'log_view.dart';
import 'machine_switcher.dart';
import 'operations.dart';
import 'panes.dart';
import 'refusal.dart';
import 'status_line.dart';
import 'tokens.dart';
import 'window_size.dart';

/// The one window: a rail saying where you are, a menu saying what you can do, and the section
/// you are in between them.
///
/// Everything else opens over this frame rather than navigating away from it. If moving between
/// the overview and a detail were expensive people would stop looking, and the state of the
/// machine would stop being known.
class Shell extends StatefulWidget {
  /// Constructor taking everything the frame renders and acts on.
  const Shell({
    required this.machines,
    required this.shell,
    required this.settings,
    required this.operations,
    required this.logs,
    required this.gate,
    required this.notifications,
    required this.egress,
    required this.newerVersion,
    super.key,
  });

  /// Every machine being watched, and which one is being acted on.
  final Machines machines;

  /// Where you are, what is open and where the keyboard is.
  final ShellModel shell;

  /// How the interface looks.
  final Settings settings;

  /// What this session has run.
  final Operations operations;

  /// What this session is reading.
  final Logs logs;

  /// What is waiting at the gate of the project being looked at.
  final Gate gate;

  /// What gets told to somebody who is not looking at the window.
  final Notifications notifications;

  /// What the project being looked at may reach.
  final Egress egress;

  /// Whether a newer build has been installed underneath this one.
  final NewerVersion newerVersion;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  /// What is on the machine being acted on. Everything the frame draws comes from here, so
  /// switching machine changes the whole frame and nothing has to know it happened.
  FleetModel get _fleet => widget.machines.fleet;

  final _projectsFocus = FocusNode(debugLabel: 'projects');
  final _workFocus = FocusNode(debugLabel: 'work');
  final _openedFocus = FocusNode(debugLabel: 'opened');

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
        fleet: _fleet,
        shell: widget.shell,
        settings: widget.settings,
        operations: widget.operations,
        notifications: widget.notifications,
        openFinder: _openFinder,
        checkWorkCanStart: _checkWorkCanStart,
        askToStop: _askToStop,
        askWhichLog: _askWhichLog,
        openTheGate: _openTheGate,
        openEgress: _openEgress,
        quit: _quit,
      );

  /// Opens what is waiting at the selected project's gate.
  Future<void> _openTheGate() async {
    final project = _fleet.selectedProject?.project;
    if (project == null) return;
    widget.shell.openGate();
    await widget.gate.lookAt(_fleet.backend, project);
  }

  /// Asks before leaving, naming what carries on without the window.
  ///
  /// Closing the interface never stops running work — so the confirmation says what will keep
  /// going, because somebody who thinks quitting stops it will not quit, and somebody who thinks
  /// it does not will be surprised the other way.
  Future<void> _quit() async {
    final running = <String>[
      for (final machine in widget.machines.all)
        for (final task in widget.machines.of(machine).tasks)
          if (task.running) '${task.name} on ${machine.name}',
    ];
    final waiting = widget.machines.all
        .map((machine) => widget.machines.of(machine).clearance.count)
        .fold<int>(0, (all, some) => all + some);

    final agreed = await confirmQuit(context, running: running, waiting: waiting);
    if (agreed) await SystemNavigator.pop();
  }

  /// Opens what the selected project's work may reach.
  Future<void> _openEgress() async {
    final project = _fleet.selectedProject?.project;
    if (project == null) return;
    widget.shell.openEgress();
    await widget.egress.lookAt(_fleet.backend, project);
  }

  /// Opens one waiting push, and reads what it contains.
  Future<void> _look(PendingPush push) async {
    widget.shell.openReview();
    await widget.gate.look(_fleet.backend, push);
  }

  /// Forwards the push being judged, onto a branch somebody names.
  Future<void> _approve() async {
    final push = widget.gate.looking;
    if (push == null) return;
    final branch = await askWhichBranch(context, subject: push.subject);
    if (branch == null) return;
    final said = await widget.gate.approve(_fleet.backend, branch);
    if (said.isNotEmpty) _fleet.say(said);
    if (widget.gate.problem == null) widget.shell.openGate();
  }

  /// Drops the request being judged.
  Future<void> _reject() async {
    final said = await widget.gate.reject(_fleet.backend);
    if (said.isNotEmpty) _fleet.say(said);
    if (widget.gate.problem == null) widget.shell.openGate();
  }

  /// Asks for another machine to watch, and starts watching it.
  Future<void> _addAMachine() async {
    final machine = await askForAMachine(context);
    if (machine == null) return;
    await widget.machines.add(machine);
  }

  /// Asks which log, then opens it. Reading starts whether or not it stays on screen.
  Future<void> _askWhichLog(Task task) async {
    final log = await askWhichLog(
      context,
      task: task.name,
      logs: _fleet.backend.logsOf(task.name),
    );
    if (log == null) return;
    widget.logs.open(_fleet.backend, task.name, log);
    widget.shell.openLog(task.name, log);
  }

  /// Asks before stopping, then stops. The refusal, if there is one, arrives on its own.
  Future<void> _askToStop(Task task) async {
    final agreed = await confirmStop(
      context,
      task: task.name,
      helpers: task.helpers,
    );
    if (!agreed) return;
    await _fleet.stopWork(task.name);
  }

  Future<void> _openFinder() async {
    final chosen = await showCommandFinder(context, _commands());
    chosen?.run();
  }

  void _openWork() {
    if (_fleet.selectedTask == null) return;
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
      output: _fleet.backend.startTask(dryRun: true),
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
    final size = WindowSize.fromContext(context);

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
                if (size.showsMenuBar)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CommandMenuBar(commands: commands),
                  ),
                if (widget.newerVersion.arrived)
                  NewerVersionBanner(onRestart: () => SystemNavigator.pop()),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          MachineSwitcher(
                            machines: widget.machines,
                            onAdd: _addAMachine,
                            extended: size.railShowsLabels,
                          ),
                          Expanded(child: _rail(size)),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: LayoutBuilder(builder: _section)),
                    ],
                  ),
                ),
                StatusLine(
                  fleet: _fleet,
                  operations: widget.operations,
                  cannotNotify: widget.notifications.problem,
                  onShowOperations: () => widget.shell.goTo(Section.operations),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The rail, with a count on anything that is waiting for a person.
  ///
  /// A question has a deadline and is never asked twice, so "somebody must do something" cannot
  /// be a thing you find by looking in the right place.
  Widget _rail(WindowSize size) => NavigationRail(
        extended: size.railShowsLabels,
        labelType:
            size.railShowsLabels ? null : NavigationRailLabelType.selected,
        selectedIndex: Section.values.indexOf(widget.shell.section),
        onDestinationSelected: (chosen) =>
            widget.shell.goTo(Section.values[chosen]),
        destinations: <NavigationRailDestination>[
          const NavigationRailDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: Text('Work'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: Text('This session'),
          ),
          NavigationRailDestination(
            icon: Badge(
              key: const Key('waiting-count'),
              isLabelVisible: _fleet.clearance.count > 0,
              label: Text('${_fleet.clearance.count}'),
              child: const Icon(Icons.pan_tool_outlined),
            ),
            selectedIcon: const Icon(Icons.pan_tool),
            label: const Text('Blocked'),
          ),
        ],
      );

  Widget _section(BuildContext context, BoxConstraints constraints) =>
      switch (widget.shell.section) {
        Section.work => _work(WindowSize.of(constraints.maxWidth)),
        Section.operations => _thisSession(),
        Section.clearance => ClearanceView(
            clearance: _fleet.clearance,
            onDecide: (prompt, {required allow}) =>
                _fleet.clearance.decide(_fleet.backend, prompt, allow: allow),
          ),
      };

  Widget _thisSession() {
    final opened = _opened();
    if (opened != null) return opened;
    return OperationsList(
      operations: widget.operations,
      focusNode: _openedFocus,
      onOpen: widget.shell.openOperation,
    );
  }

  /// What is open over the work, or null when nothing is.
  ///
  /// Resolved rather than read straight off the model, because what a view points at can go away
  /// underneath it: work that stopped existing, an operation this session never had.
  Widget? _opened() {
    switch (widget.shell.opened) {
      case NothingOpened():
        return null;
      case WorkOpened():
        final task = _fleet.selectedTask;
        if (task == null) return null;
        return WorkDetail(task: task, onClose: widget.shell.close);
      case EgressOpened():
        return EgressView(
          egress: widget.egress,
          onConsider: ({addSets, removeSets}) => widget.egress.consider(
            _fleet.backend,
            addSets: addSets,
            removeSets: removeSets,
          ),
          onApply: _applyEgress,
          onLetItBe: widget.egress.letItBe,
          onClose: widget.shell.close,
        );
      case GateOpened():
        return GateView(
          gate: widget.gate,
          focusNode: _openedFocus,
          onOpen: _look,
          onClose: widget.shell.close,
        );
      case ReviewOpened():
        return ReviewView(
          gate: widget.gate,
          onBack: widget.shell.openGate,
          onClose: widget.shell.close,
          onApprove: _approve,
          onReject: _reject,
        );
      case LogOpened(:final task, :final log):
        final tail = widget.logs.find(task, log);
        if (tail == null) return null;
        return LogView(
          tail: tail,
          logs: widget.logs,
          onClose: widget.shell.close,
        );
      case OperationOpened(:final id):
        final operation = widget.operations.byId(id);
        if (operation == null) return null;
        return OperationOutputView(
          operation: operation,
          onBack: () => widget.shell.goTo(Section.operations),
          onClose: widget.shell.close,
        );
    }
  }

  Widget _work(WindowSize size) {
    // A refusal takes the place of whatever was open. It is the most important thing on the
    // screen until somebody has decided about it, and it is not dismissible by accident.
    final refusal = _fleet.refusal;
    final opened = refusal != null
        ? RefusalView(refusal: refusal, fleet: _fleet)
        : _opened();
    if (!size.showsTwoPanes) return _onePane(opened);

    final projects = SizedBox(
      width: Sizes.projectsPane,
      child: ProjectsPane(
        fleet: _fleet,
        focusNode: _projectsFocus,
        onFocused: () => widget.shell.focus(Pane.projects),
        onActivate: () => widget.shell.focus(Pane.work),
        mutedProjects: widget.notifications.muted,
      ),
    );
    final work = WorkPane(
      fleet: _fleet,
      focusNode: _workFocus,
      onFocused: () => widget.shell.focus(Pane.work),
      onActivate: _openWork,
      actionsFor: _workActions,
    );

    // Wide enough keeps the work list beside what is open; otherwise the open thing takes the
    // space the work list had, which is still opening over the frame rather than navigating away.
    if (opened != null && size.showsOpenedBeside) {
      return Row(
        children: <Widget>[
          projects,
          const VerticalDivider(width: 1),
          Expanded(child: work),
          const VerticalDivider(width: 1),
          SizedBox(width: Sizes.openedPane, child: opened),
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

  /// Makes the change that was previewed, with the same words it was previewed with.
  Future<void> _applyEgress() async {
    final asked = widget.egress.preview;
    if (asked == null) return;
    await widget.egress.apply(
      _fleet.backend,
      addSets: _setsIn(asked.opens),
      removeSets: _setsIn(asked.closes),
    );
    final done = widget.egress.applied;
    if (done != null) _fleet.say('${done.outcome.label}. ${done.detail}'.trim());
  }

  /// Which sets a preview's hosts came from, so the change can be asked for again in the same
  /// words rather than remembered as a promise.
  static List<String> _setsIn(List<EgressHost> hosts) => <String>{
        for (final host in hosts)
          if (host.origin.startsWith('set ')) host.origin.substring(4),
      }.toList();

  List<Command> _workActions(Task task) => workCommands(
        task: task,
        fleet: _fleet,
        askToStop: _askToStop,
        askWhichLog: _askWhichLog,
      );

  Widget _onePane(Widget? opened) {
    if (opened != null) return opened;
    if (widget.shell.pane == Pane.work && _fleet.selectedProject != null) {
      return WorkPane(
        fleet: _fleet,
        focusNode: _workFocus,
        onFocused: () => widget.shell.focus(Pane.work),
        onActivate: _openWork,
        actionsFor: _workActions,
        leading: BackButton(onPressed: () => widget.shell.focus(Pane.projects)),
      );
    }
    return ProjectsPane(
      fleet: _fleet,
      focusNode: _projectsFocus,
      onFocused: () => widget.shell.focus(Pane.projects),
      onActivate: () => widget.shell.focus(Pane.work),
      mutedProjects: widget.notifications.muted,
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

/// Runs the command with this id, whatever key, menu or finder asked for it.
///
/// One path from a keystroke to an action, shared with the menu bar and the finder, so a shortcut
/// cannot come to mean something other than the entry that names it.
class _RunCommand extends Intent {
  const _RunCommand(this.id);

  final String id;
}
