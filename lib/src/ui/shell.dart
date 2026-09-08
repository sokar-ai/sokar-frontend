import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/commands.dart';
import '../app/fleet_backend.dart';
import '../app/fleet_model.dart';
import '../app/egress.dart';
import '../app/agent_inventory.dart';
import '../app/authentication.dart';
import '../app/backups.dart';
import '../app/emergency_stop.dart';
import '../app/start_work.dart';
import '../app/templates.dart';
import '../app/vault.dart';
import '../app/widening.dart';
import '../app/gate.dart';
import '../app/host_readiness.dart';
import '../app/logs.dart';
import '../app/notifications.dart';
import '../app/machines.dart';
import '../app/narrowing.dart';
import '../app/newer_version.dart';
import '../app/operations.dart';
import '../app/project_creation.dart';
import '../app/project_deletion.dart';
import '../app/session.dart';
import '../app/settings.dart';
import '../app/shell_model.dart';
import 'package:sokar_frontend/client.dart';

import 'command_finder.dart';
import 'clearance_view.dart';
import 'command_menu_bar.dart';
import 'egress_view.dart';
import 'agents_view.dart';
import 'authentication_view.dart';
import 'backups_view.dart';
import 'emergency_stop_view.dart';
import 'project_creation_view.dart';
import 'project_deletion_view.dart';
import 'session_view.dart';
import 'vault_view.dart';
import 'start_work_view.dart';
import 'widening_view.dart';
import 'gate_view.dart';
import 'host_readiness_view.dart';
import 'leaving.dart';
import 'log_view.dart';
import 'machine_switcher.dart';
import 'narrowing_view.dart';
import 'operations.dart';
import 'panes.dart';
import 'prepare_view.dart';
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
    required this.widening,
    required this.starting,
    required this.inventory,
    required this.templates,
    required this.stopping,
    required this.vault,
    required this.newerVersion,
    required this.sessions,
    required this.deleting,
    required this.readiness,
    required this.authentication,
    required this.creating,
    required this.backups,
    required this.narrowing,
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

  /// Letting work that is already running reach something new.
  final Widening widening;

  /// Starting work, and continuing a finished run.
  final StartWork starting;

  /// What agents are installed on the machine being watched.
  final AgentInventory inventory;

  /// The recurring jobs somebody named.
  final Templates templates;

  /// Cutting every form of access at once.
  final EmergencyStop stopping;

  /// What the protected store holds.
  final Vault vault;

  /// Whether a newer build has been installed underneath this one.
  final NewerVersion newerVersion;

  /// The shells somebody has open inside running work.
  final Sessions sessions;

  /// Removing what Sokar built for a project.
  final ProjectDeletion deleting;

  /// Whether the machine being acted on can run anything.
  final HostReadiness readiness;

  /// What the machine being acted on can authenticate against.
  final Authentication authentication;

  /// Describing and creating a project.
  final ProjectCreation creating;

  /// What has been backed up of the project being looked at.
  final Backups backups;

  /// Taking a name back from work that is already running.
  final Narrowing narrowing;

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
        templates: widget.templates,
        openFinder: _openFinder,
        checkWorkCanStart: _checkWorkCanStart,
        askToStop: _askToStop,
        askWhichLog: _askWhichLog,
        openSession: _openSession,
        openTheGate: _openTheGate,
        openEgress: _openEgress,
        removeWhatWasBuilt: _removeWhatWasBuilt,
        checkTheMachine: _checkTheMachine,
        showTheProviders: _showTheProviders,
        prepareTheProject: _prepareTheProject,
        describeAProject: _describeAProject,
        showTheBackups: _showTheBackups,
        widenTheWork: _widenTheWork,
        narrowTheWork: _narrowTheWork,
        startWork: _startWork,
        showAgents: _showAgents,
        showTheVault: _showTheVault,
        startFromTemplate: _startFromTemplate,
        stopEverything: _stopEverything,
        nameTheWork: _nameTheWork,
        recreate: _recreate,
        continueTheWork: _continueTheWork,
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
    if (!agreed) return;
    // Before the window goes: a forward this interface raised is taken down and its socket
    // removed. Nothing somebody else raised is touched — none of it is in here to touch.
    await widget.machines.letGoOfTheTunnels();
    await SystemNavigator.pop();
  }

  /// Asks what removing what Sokar built for this project would take, then offers to do it.
  ///
  /// **Nothing is removed by opening this.** The preview is a call with `dryRun`, and what it
  /// lists is what somebody agrees to — the sentence above the button is not.
  Future<void> _removeWhatWasBuilt() async {
    final project = _fleet.selectedProject;
    if (project == null) return;
    widget.deleting.letItBe();
    unawaited(widget.deleting.consider(_fleet.backend, project.name));
    await openProjectDeletion(
      context,
      deleting: widget.deleting,
      onRemove: ({required force}) => _remove(force: force),
    );
    widget.deleting.letItBe();
  }

  /// Removes it, and refreshes the list so what is on screen is what is there.
  Future<void> _remove({required bool force}) async {
    await widget.deleting.remove(_fleet.backend, force: force);
    final said = widget.deleting.words;
    if (said.isNotEmpty) _fleet.say(said);
    if (widget.deleting.removed) await _fleet.refresh();
  }

  /// Asks whether this machine can run anything, and shows what it said.
  ///
  /// **Asked, never polled.** It runs external programs on the machine, so it is a thing somebody
  /// does rather than something that happens in the background.
  Future<void> _checkTheMachine() async {
    widget.shell.openReadiness();
    await widget.readiness.look(_fleet.backend);
  }

  /// Shows what has been backed up of the selected project.
  Future<void> _showTheBackups() async {
    final project = _fleet.selectedProject;
    if (project == null) return;
    widget.shell.openBackups();
    await widget.backups.look(_fleet.backend, project.name);
  }

  /// Removes the backup being considered, and says what that did.
  Future<void> _removeTheBackup() async {
    await widget.backups.remove(_fleet.backend);
    final said = widget.backups.words;
    if (said.isNotEmpty) _fleet.say(said);
  }

  /// Describes a project, checks every answer against the machine, and creates it.
  ///
  /// **Nothing is written until the last press**: every check runs with `dryRun`, so a flow
  /// somebody walks away from leaves nothing on that machine.
  Future<void> _describeAProject() async {
    widget.creating.startOn(_fleet.backend);
    // The sets this machine really has, rather than a list typed from memory: one that is not
    // installed there is a refusal waiting at the first task start.
    final (sets, _) = await _fleet.backend.egressSets();
    if (!mounted) return;
    final made = await createAProject(
      context,
      creation: widget.creating,
      setsHere: sets.map((set) => set.name).toList(),
      onCheck: () => widget.creating.check(_fleet.backend),
      onCreate: () async {
        await widget.creating.create(_fleet.backend);
        final said = widget.creating.words;
        if (said.isNotEmpty) _fleet.say(said);
      },
    );
    if (made) await _fleet.refresh();
    widget.creating.letItBe();
  }

  /// Builds a project's environment without starting anything, at a depth somebody chooses.
  ///
  /// **The depth is asked before the build, because it is what the build costs.** It runs as an
  /// operation, so the rest of the interface stays usable while it goes and the output is still
  /// readable afterwards — including the step a failure names.
  Future<void> _prepareTheProject() async {
    final project = _fleet.selectedProject;
    if (project == null || !project.canBeActedOn) return;
    final depth = await askHowMuchToBuild(context, project: project.name);
    if (depth == null || !mounted) return;

    final operation = widget.operations.run(
      title: 'Build the environment for ${project.name}',
      output: _fleet.backend
          .buildEnvironment(project.project.file, rebuild: depth.name),
    );
    widget.shell.openOperation(operation.id);
    // What is on screen has to be what is true: a built image changes `preparedState`, which the
    // project row draws.
    await _fleet.refresh();
  }

  /// Shows what this machine can authenticate against, and where each credential belongs.
  Future<void> _showTheProviders() async {
    widget.authentication.letItBe();
    widget.shell.openProviders();
    await widget.authentication.look(_fleet.backend);
  }

  /// Imports a credential an agent already holds on the machine. **No secret crosses doing it.**
  Future<void> _import(String? agent) async {
    await widget.authentication.importFor(_fleet.backend, agent: agent);
  }

  /// Opens what the selected project's work may reach.
  Future<void> _openEgress() async {
    final project = _fleet.selectedProject?.project;
    if (project == null) return;
    widget.shell.openEgress();
    await widget.egress.lookAt(_fleet.backend, project);
  }

  /// Gives a piece of work something to read by, or takes it away.
  ///
  /// **Nothing about its identity moves.** The container name is what every other call takes and
  /// what somebody types into `sokar` on the machine; a caption stands in front of it on a row and
  /// never in place of it.
  Future<void> _nameTheWork(Task task) async {
    final caption = await askWhatItReadsAs(context, task: task);
    if (caption == null || !mounted) return;
    final answer = await _fleet.backend.labelTask(task.name, label: caption);
    if (!mounted) return;
    _fleet.say(answer.words);
    await _fleet.refresh();
  }

  /// Opens the emergency stop, having first asked what it would stop.
  ///
  /// Never stops anything by itself: what would be stopped is shown, and agreeing to it is a
  /// second, separate act. One press away from stopping a machine is an accident waiting for a
  /// stray click.
  Future<void> _stopEverything() async {
    widget.stopping.letItBe();
    unawaited(widget.stopping.consider(_fleet.backend));
    await openEmergencyStop(
      context,
      stopping: widget.stopping,
      onStopEverything: () => widget.stopping.stopEverything(_fleet.backend),
    );
    widget.stopping.letItBe();
  }

  /// Shows what the protected store holds.
  ///
  /// Asked every time rather than held: what it holds changes with `vault put` at the machine,
  /// and nothing tells this interface when that happened.
  Future<void> _showTheVault() async {
    widget.shell.openVault();
    await widget.vault.look(_fleet.backend);
  }

  /// Shows what agents this machine has.
  ///
  /// Asked every time it is opened rather than held: an agent installed while the window was open
  /// would otherwise be missing from the one list somebody opened to find out.
  Future<void> _showAgents() async {
    widget.shell.openAgents();
    await widget.inventory.load(_fleet.backend);
  }

  /// Starts work from a recurring job somebody named.
  Future<void> _startFromTemplate(Template job) async {
    final project = _fleet.selectedProject?.project;
    if (project == null) return;
    await widget.starting.openFrom(_fleet.backend, project, job);
    if (!mounted) return;
    await _offerToStart();
  }

  /// Starts work in the selected project.
  Future<void> _startWork() async {
    final project = _fleet.selectedProject?.project;
    if (project == null) return;
    await widget.starting.open(_fleet.backend, project);
    if (!mounted) return;
    await _offerToStart();
  }

  /// Continues a finished unattended run, with what it was asked to do last time in the box.
  Future<void> _continueTheWork() async {
    final task = _fleet.selectedTask;
    final project = _fleet.selectedProject?.project;
    if (task == null || project == null) return;
    await widget.starting.continueFrom(_fleet.backend, project, task);
    if (!mounted) return;
    await _offerToStart();
  }

  Future<void> _offerToStart() async {
    final started = await openStartWork(
      context,
      starting: widget.starting,
      onStart: _beginTheRun,
      onKeep: _keepAsTemplate,
    );
    widget.starting.close();
    if (!started) return;
    // Nothing else to do: starting already opened the operation, and `goTo` would close it again.
  }

  /// Keeps what is on screen as a recurring job.
  void _keepAsTemplate() {
    final job = widget.starting.asTemplate;
    if (job == null) return;
    unawaited(widget.templates.keep(job));
  }

  /// Runs it, and hands the stream to the session rather than to this view.
  ///
  /// An unattended run lasts as long as the agent does — minutes, sometimes tens of them — and
  /// nothing about closing a dialog should stop watching it.
  void _beginTheRun() {
    final operation = widget.operations.run(
      title: widget.starting.title,
      output: widget.starting.begin(_fleet.backend),
    );
    widget.shell.openOperation(operation.id);
  }

  /// Lets the selected work reach something it could not reach before.
  ///
  /// A dialog over where the work is listed, because F17 asks for it *from* there: a person
  /// answering a refusal is looking at the task, not at a project file.
  /// Takes a name back from work that is already running.
  ///
  /// **Previewed every time, like widening**, and for the same reason: it lands on work in front
  /// of somebody. What it says afterwards is that new connections stop — never that the host is
  /// unreachable, because a transfer in flight runs to its end.
  Future<void> _narrowTheWork() async {
    final task = _fleet.selectedTask;
    if (task == null) return;
    widget.narrowing.open(task);
    await openNarrowing(
      context,
      narrowing: widget.narrowing,
      onConsider: () => widget.narrowing.consider(_fleet.backend),
      onApply: () => widget.narrowing.apply(_fleet.backend),
    );
    final said = widget.narrowing.words;
    if (said.isNotEmpty) _fleet.say(said);
    widget.narrowing.close();
  }

  Future<void> _widenTheWork() async {
    final task = _fleet.selectedTask;
    if (task == null) return;
    widget.widening.open(task);
    await openWidening(
      context,
      widening: widget.widening,
      onConsider: () => widget.widening.consider(_fleet.backend),
      onApply: () => widget.widening.apply(_fleet.backend),
    );
    widget.widening.close();
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

  /// Stops a piece of work and starts it again from scratch.
  ///
  /// Two calls, and the first can refuse: `Stop` answers `HOLDS_WORK` for work holding commits
  /// that never reached the gate. **Nothing is started after a refused stop** — that would leave
  /// two containers and lose the reason.
  Future<void> _recreate(Task task) async {
    final agreed = await confirmRecreate(
      context,
      task: task.label.isEmpty ? task.name : task.label,
      helpers: task.helpers,
    );
    if (!agreed) return;
    final clear = await _fleet.clearTheWayToRecreate(task.name);
    if (!clear || !mounted) return;

    final project = _fleet.projects
        .where((each) => each.name == task.project)
        .map((each) => each.project.file)
        .firstOrNull;
    final operation = widget.operations.run(
      title: 'Recreate ${task.name}',
      // The same name, so what comes back is the same piece of work rather than a second one
      // beside it — and the same agent, mode and prompt, because recreating is meant to change
      // the environment and nothing else.
      output: _fleet.backend.startTask(
        task: task.name,
        project: project,
        agent: task.agent.isEmpty ? null : task.agent,
        mode: task.mode.recognized ? task.mode : null,
        prompt: task.prompt.isEmpty ? null : task.prompt,
      ),
    );
    widget.shell.openOperation(operation.id);
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
    final project = _fleet.selectedProject?.project;
    if (project == null) return;
    final operation = widget.operations.run(
      title: 'Show what ${project.name} would open',
      output: _fleet.backend.startTask(project: project.file, dryRun: true),
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
                  onStopEverything: _stopEverything,
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
      case VaultOpened():
        return VaultView(
          vault: widget.vault,
          onLock: () => widget.vault.lock(_fleet.backend),
          onClose: widget.shell.close,
        );
      case BackupsOpened():
        return BackupsView(
          backups: widget.backups,
          onConsider: (backup) => widget.backups.consider(_fleet.backend, backup),
          onRemove: _removeTheBackup,
          onLetItBe: widget.backups.letItBe,
          onClose: widget.shell.close,
        );
      case ProvidersOpened():
        return AuthenticationView(
          authentication: widget.authentication,
          onImport: _import,
          onClose: widget.shell.close,
        );
      case ReadinessOpened():
        return HostReadinessView(
          readiness: widget.readiness,
          machine: widget.machines.current.name,
          onCheckAgain: () => widget.readiness.look(_fleet.backend),
          onClose: widget.shell.close,
        );
      case AgentsOpened():
        return AgentsView(
          inventory: widget.inventory,
          onClose: widget.shell.close,
        );
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
      case SessionOpened(:final task):
        final session = widget.sessions.find(task, widget.machines.current);
        // Gone because the machine was switched, or because it was left. Falling through to
        // nothing puts the frame back rather than drawing a session against nothing.
        if (session == null) return null;
        return SessionView(
          session: session,
          others: widget.sessions.all,
          focusNode: _openedFocus,
          onGoTo: (other) => widget.shell.openSession(other.task),
          onLeave: () async {
            await widget.sessions.leave(session);
            widget.shell.close();
          },
          onClose: widget.shell.close,
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
        openSession: _openSession,
      );

  /// Opens a shell inside running work, or goes back to the one that is already open.
  ///
  /// **Opening is not starting.** A session against this task may already be running from
  /// earlier in this window; `openOn` hands that one back rather than making a second way in to
  /// one container.
  void _openSession(Task task) {
    widget.sessions.openOn(task.name, widget.machines.current);
    widget.shell.openSession(task.name);
  }

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
