import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/attention.dart';
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
import '../app/work_held.dart';
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

import 'attention_view.dart';
import 'command_finder.dart';
import 'clearance_mode_view.dart';
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
import 'machine_tree.dart';
import 'machine_view.dart';
import 'narrowing_view.dart';
import 'operations.dart';
import 'panes.dart';
import 'prepare_view.dart';
import 'refusal.dart';
import 'status_line.dart';
import 'tokens.dart';
import 'window_size.dart';

/// The one window: a rail saying where you are, and that place beside it.
///
/// The rail is what needs a person and then every machine. A machine's place holds everything
/// about it: its title and menu, its projects, its work, and a status line of what it ran. The menu
/// bar keeps only what belongs to no machine. Everything else opens over the frame rather than
/// navigating away from it.
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
    required this.held,
    super.key,
  });

  /// Every machine being watched, and which one is being acted on.
  final Machines machines;

  /// Where you are, what is open and what the finder is showing.
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

  /// What the work being looked at holds that never reached the gate.
  final WorkHeld held;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  /// What is on the machine being acted on. Switching machine changes everything drawn from it.
  FleetModel get _fleet => widget.machines.fleet;

  final _openedFocus = FocusNode(debugLabel: 'opened');
  // The frame's own focus, so the keyboard works the moment the window opens and after anything
  // open over it closes.
  final _frameFocus = FocusNode(debugLabel: 'frame');
  late final Attention _attention;
  late final AppLifecycleListener _leaving;

  /// This build's version, stamped by the package build; a build from source says so.
  static const _version = String.fromEnvironment(
    'SOKAR_VERSION',
    defaultValue: 'built from source',
  );

  @override
  void initState() {
    super.initState();
    _attention = Attention(widget.machines);
    // Closing the window is how the interface ends, so the forwards it raised end with it.
    _leaving = AppLifecycleListener(onExitRequested: _letGo);
    widget.shell.addListener(_moveKeyboard);
  }

  /// Asks before the window closes, naming what carries on without it, then lets go of the
  /// forwards it raised. Closing never stops running work, so the question says what keeps going.
  Future<AppExitResponse> _letGo() async {
    final running = <String>[
      for (final machine in widget.machines.all)
        for (final task in widget.machines.of(machine).tasks)
          if (task.running) '${task.name} on ${machine.name}',
    ];
    final waiting = widget.machines.all
        .map((machine) => widget.machines.of(machine).clearance.count)
        .fold<int>(0, (all, some) => all + some);
    final agreed = await confirmQuit(
      context,
      running: running,
      waiting: waiting,
    );
    if (!agreed) return AppExitResponse.cancel;
    // Only what this interface raised is taken down; nothing somebody else raised is in there.
    await widget.machines.letGoOfTheTunnels();
    return AppExitResponse.exit;
  }

  void _moveKeyboard() {
    if (!mounted) return;
    final open = widget.shell.anythingOpen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (open) {
        _openedFocus.requestFocus();
      } else if (!_frameFocus.hasFocus) {
        _frameFocus.requestFocus();
      }
    });
  }

  List<Command> _commands() => commandsFor(
    fleet: _fleet,
    machine: widget.machines.current,
    canForget: widget.machines.all.length > 1,
    shell: widget.shell,
    settings: widget.settings,
    operations: widget.operations,
    notifications: widget.notifications,
    templates: widget.templates,
    openFinder: _openFinder,
    checkWorkCanStart: _checkWorkCanStart,
    askToRemove: _askToRemove,
    askWhichLog: _askWhichLog,
    openSession: _openSession,
    openDetail: _openWork,
    continueTheWork: (_) => _continueTheWork(),
    recreate: _recreate,
    nameTheWork: _nameTheWork,
    widenTheWork: (_) => _widenTheWork(),
    enforceOnTheWork: (_) => _enforceOnTheWork(),
    narrowTheWork: (_) => _narrowTheWork(),
    openTheGate: _openTheGate,
    openEgress: _openEgress,
    removeWhatWasBuilt: _removeWhatWasBuilt,
    checkTheMachine: _checkTheMachine,
    showTheProviders: _showTheProviders,
    prepareTheProject: _prepareTheProject,
    describeAProject: _describeAProject,
    showTheBackups: _showTheBackups,
    syncTheUpstream: _syncTheUpstream,
    startWork: _startWork,
    showAgents: _showAgents,
    showTheVault: _showTheVault,
    startFromTemplate: _startFromTemplate,
    stopEverything: _stopEverything,
    stopEverywhere: _stopEverywhere,
    watchAnotherMachine: _addAMachine,
    forget: _forget,
    showAbout: _showAbout,
  );

  /// The menu in the machine's title, for the machine being acted on.
  List<Command> _machineMenu() => machineCommands(
    fleet: _fleet,
    canForget: widget.machines.all.length > 1,
    checkTheMachine: _checkTheMachine,
    showTheProviders: _showTheProviders,
    showTheVault: _showTheVault,
    showAgents: _showAgents,
    forget: _forget,
  );

  /// A project card's menu, judged for that project and run with it selected.
  List<Command> _projectMenu(ProjectOnScreen project) => <Command>[
    for (final command in projectCommands(
      project: project,
      fleet: _fleet,
      notifications: widget.notifications,
      openTheGate: _openTheGate,
      openEgress: _openEgress,
      prepareTheProject: _prepareTheProject,
      syncTheUpstream: _syncTheUpstream,
      showTheBackups: _showTheBackups,
      checkWorkCanStart: _checkWorkCanStart,
      removeWhatWasBuilt: _removeWhatWasBuilt,
    ))
      command.after(() => _fleet.selectProject(project.name)),
  ];

  /// A tile's actions, judged on the tile's own machine and run with its work selected there.
  List<Command> _tileActions(Tile tile) => <Command>[
    for (final command in workCommands(
      task: tile.task,
      fleet: tile.fleet,
      machine: tile.machine,
      askToRemove: _askToRemove,
      askWhichLog: _askWhichLog,
      openSession: _openSession,
      continueTheWork: (_) => _continueTheWork(),
      recreate: _recreate,
      nameTheWork: _nameTheWork,
      widenTheWork: (_) => _widenTheWork(),
      enforceOnTheWork: (_) => _enforceOnTheWork(),
      narrowTheWork: (_) => _narrowTheWork(),
    ))
      command.after(() => _select(tile)),
  ];

  /// Makes a tile's machine and work the ones being acted on.
  void _select(Tile tile) {
    widget.machines.select(tile.machine);
    final task = tile.task;
    if (task == null) return;
    if (tile.fleet.selectedTask?.name == task.name) return;
    tile.fleet
      ..selectProject(task.project)
      ..selectTask(task.name);
  }

  /// Goes from what needs a person to where the tile's work lives.
  void _goToWork(Tile tile) {
    _select(tile);
    widget.shell.goTo(Section.machine);
  }

  /// Opens what is waiting at the selected project's gate.
  Future<void> _openTheGate() async {
    final project = _fleet.selectedProject?.project;
    if (project == null) return;
    widget.shell.openGate();
    await widget.gate.lookAt(_fleet.backend, project);
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

  /// Asks whether this machine can run anything, and shows what it said. Asked, never polled.
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

  /// Restores the mirror from the backup being considered, and says what that did.
  Future<void> _restoreTheMirror({required bool force}) async {
    await widget.backups.restore(_fleet.backend, force: force);
    final said = widget.backups.restoreWords;
    if (said.isNotEmpty) _fleet.say(said);
  }

  /// Asks the upstream how far behind this project is, now.
  Future<void> _syncTheUpstream() async {
    final project = _fleet.selectedProject;
    if (project == null) return;
    final said = await widget.backups.syncFor(_fleet.backend, project.name);
    // Refreshed first: a refresh announces itself, and the answer should be said last.
    await _fleet.refresh();
    if (said.isNotEmpty) _fleet.say(said);
  }

  /// Removes the backup being considered, and says what that did.
  Future<void> _removeTheBackup() async {
    await widget.backups.remove(_fleet.backend);
    final said = widget.backups.words;
    if (said.isNotEmpty) _fleet.say(said);
  }

  /// Describes a project in the machine's place, checks every answer against it, and creates it.
  ///
  /// **Nothing is written until the last press**: every check runs with `dryRun`.
  Future<void> _describeAProject() async {
    widget.creating.startOn(_fleet.backend);
    // The sets this machine really has, rather than a list typed from memory.
    final (sets, _) = await _fleet.backend.egressSets();
    if (!mounted) return;
    _setsHere = sets.map((set) => set.name).toList();
    widget.shell
      ..goTo(Section.machine)
      ..openProjectCreation();
  }

  List<String> _setsHere = const <String>[];

  /// Puts the description away; a project that was made is then the one selected.
  Future<void> _doneCreating(bool made) async {
    final name = widget.creating.name;
    widget.shell.close();
    widget.creating.letItBe();
    if (!made) return;
    await _fleet.refresh();
    _fleet.selectProject(name);
  }

  /// Builds a project's environment without starting anything, at a depth somebody chooses.
  Future<void> _prepareTheProject() async {
    final project = _fleet.selectedProject;
    if (project == null || !project.canBeActedOn) return;
    final depth = await askHowMuchToBuild(context, project: project.name);
    if (depth == null || !mounted) return;

    final operation = widget.operations.run(
      title: 'Build the environment for ${project.name}',
      machine: widget.machines.current.name,
      output: _fleet.backend.buildEnvironment(
        project.project.file,
        rebuild: depth.name,
      ),
    );
    widget.shell.openOperation(operation.id);
    // A built image changes `preparedState`, which the project card draws.
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

  /// Gives a piece of work something to read by, or takes it away. Nothing about its identity
  /// moves.
  Future<void> _nameTheWork(Task task) async {
    final caption = await askWhatItReadsAs(context, task: task);
    if (caption == null || !mounted) return;
    final answer = await _fleet.backend.labelTask(task.name, label: caption);
    if (!mounted) return;
    _fleet.say(answer.words);
    await _fleet.refresh();
  }

  /// Opens the emergency stop for the machine being acted on, having first asked what it would
  /// stop. Agreeing is a second, separate act.
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

  /// The same stop, on every machine at once.
  Future<void> _stopEverywhere() => openEmergencyStopEverywhere(
    context,
    machines: <String, FleetBackend>{
      for (final machine in widget.machines.all)
        machine.name: widget.machines.of(machine).backend,
    },
  );

  /// Shows what the protected store holds, asked every time it is opened.
  Future<void> _showTheVault() async {
    widget.shell.openVault();
    await widget.vault.look(_fleet.backend);
  }

  /// Shows what agents this machine has, asked every time it is opened.
  Future<void> _showAgents() async {
    widget.shell.openAgents();
    await widget.inventory.load(_fleet.backend);
  }

  /// Stops watching the machine being acted on, and goes back to what needs a person.
  Future<void> _forget() async {
    if (widget.machines.all.length < 2) return;
    final machine = widget.machines.current;
    widget.shell.goTo(Section.attention);
    await widget.machines.forget(machine);
  }

  /// Says what this is and what every machine it watches runs.
  void _showAbout() => showAboutDialog(
    context: context,
    applicationName: 'Sokar',
    applicationVersion: _version,
    applicationLegalese:
        'The interface to Sokar: agent work in guarded containers, on '
        'machines you watch from here.',
    children: <Widget>[
      const SizedBox(height: Space.normal),
      for (final machine in widget.machines.all)
        Text(
          '${machine.name}: ${switch (widget.machines.of(machine).info) {
            final info? => '${info.product} ${info.version}',
            null => 'not connected',
          }}',
        ),
    ],
  );

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
    await openStartWork(
      context,
      starting: widget.starting,
      onStart: _beginTheRun,
      onKeep: _keepAsTemplate,
    );
    widget.starting.close();
  }

  /// Keeps what is on screen as a recurring job.
  void _keepAsTemplate() {
    final job = widget.starting.asTemplate;
    if (job == null) return;
    unawaited(widget.templates.keep(job));
  }

  /// Runs it, and hands the stream to the session record rather than to this view.
  void _beginTheRun() {
    final operation = widget.operations.run(
      title: widget.starting.title,
      machine: widget.machines.current.name,
      output: widget.starting.begin(_fleet.backend),
    );
    widget.shell.openOperation(operation.id);
  }

  /// Changes what running work does with a blocked connection. **It opens nothing.**
  Future<void> _enforceOnTheWork() async {
    final task = _fleet.selectedTask;
    if (task == null) return;
    final chosen = await askHowToEnforce(
      context,
      task: task.name,
      now: task.clearance,
    );
    if (chosen == null || !mounted) return;
    final said = await _fleet.backend.setClearance(task.name, chosen.name);
    // Refreshed first, then said: a refresh announces itself.
    await _fleet.refresh();
    _fleet.say(whatEnforcementDid(said, task.name));
  }

  /// Takes a name back from work that is already running, previewed every time.
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

  /// Lets the selected work reach something it could not reach before.
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

  /// Asks for another machine to watch, starts watching it, and goes there.
  Future<void> _addAMachine() async {
    final machine = await askForAMachine(
      context,
      taken: widget.machines.all.map((each) => each.name),
      trying: widget.machines.tryMachine,
    );
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

  /// Asks before removing, then removes. The refusal, if there is one, arrives on its own.
  Future<void> _askToRemove(Task task) async {
    final agreed = await confirmRemove(
      context,
      task: task.name,
      running: task.running,
    );
    if (!agreed) return;
    await (task.running
        ? _fleet.stopAndRemove(task.name)
        : _fleet.removeWork(task.name));
  }

  /// Takes a piece of work down and starts it again from scratch. **Nothing is started after a
  /// refused removal** — that would lose the reason.
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
      machine: widget.machines.current.name,
      // The same name and the same agent, mode and prompt: recreating changes the environment.
      output: _fleet.backend.startTask(
        task: task.task,
        project: project,
        agent: task.agent.isEmpty ? null : task.agent,
        mode: task.mode.recognized ? task.mode : null,
        prompt: task.prompt.isEmpty ? null : task.prompt,
      ),
    );
    widget.shell.openOperation(operation.id);
  }

  /// Finds a command, then goes to where it lives and shows it there.
  Future<void> _openFinder() async {
    final chosen = await showCommandFinder(context, _commands());
    if (chosen == null || !mounted) return;
    // Something with no single place on screen runs at once; everything else is shown where it
    // lives, so the next time it is found there.
    if (chosen.home == Home.none || chosen.home == Home.menuBar) {
      chosen.run();
    } else {
      widget.shell.show(chosen.id);
    }
  }

  void _openWork() {
    final task = _fleet.selectedTask;
    if (task == null) return;
    widget.shell.openDetail();
    // Asked when the detail opens, for this one task: it runs git inside the container.
    unawaited(widget.held.look(_fleet.backend, task.name));
  }

  /// Reports what the project file opens, creating nothing.
  void _checkWorkCanStart() {
    final project = _fleet.selectedProject?.project;
    if (project == null) return;
    final operation = widget.operations.run(
      title: 'Show what ${project.name} would open',
      machine: widget.machines.current.name,
      output: _fleet.backend.startTask(project: project.file, dryRun: true),
    );
    widget.shell.openOperation(operation.id);
  }

  @override
  Widget build(BuildContext context) {
    final commands = _commands();
    final shortcuts = <ShortcutActivator, Intent>{
      for (final command in commands)
        if (command.shortcut != null)
          command.shortcut!: _RunCommand(command.id),
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
        child: Focus(
          focusNode: _frameFocus,
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  if (size.showsMenuBar)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CommandMenuBar(
                        commands: <Command>[
                          for (final command in commands)
                            if (command.home == Home.menuBar) command,
                        ],
                      ),
                    ),
                  if (widget.newerVersion.arrived)
                    NewerVersionBanner(onRestart: () => SystemNavigator.pop()),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _tree(size),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: switch (widget.shell.section) {
                            Section.attention => _needsYou(),
                            Section.machine => _machineArea(),
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// What needs a person, then every machine with its projects under it, then the stop for all.
  Widget _tree(WindowSize size) => ListenableBuilder(
    listenable: _attention,
    builder: (context, _) => MachineTree(
      machines: widget.machines,
      shell: widget.shell,
      needing: _attention.needingSomebody,
      muted: widget.notifications.muted,
      width: size.railShowsLabels ? 280 : 220,
      onNeedsYou: () => widget.shell.goTo(Section.attention),
      onMachine: _openMachine,
      onToggle: (machine) => widget.shell.setExpanded(
        machine.name,
        expanded: !widget.shell.isExpanded(machine.name),
      ),
      onRunning: _showRunning,
      onNewProject: (machine) {
        widget.machines.select(machine);
        unawaited(_describeAProject());
      },
      onProject: (machine, project) {
        widget.machines.select(machine);
        widget.machines.of(machine).selectProject(project);
        widget.shell.goTo(Section.machine);
      },
      onStopEverywhere: _stopEverywhere,
    ),
  );

  /// Opens a machine under it and goes there, keeping whichever project was chosen on it.
  void _openMachine(Machine machine) {
    widget.machines.select(machine);
    widget.shell
      ..setExpanded(machine.name, expanded: true)
      ..goTo(Section.machine);
  }

  /// Opens a machine under it and shows what runs there, on every project.
  void _showRunning(Machine machine) {
    widget.machines.select(machine);
    widget.machines.of(machine).selectProject(null);
    widget.shell
      ..setExpanded(machine.name, expanded: true)
      ..goTo(Section.machine);
  }

  /// What needs a person. A tile leads to where its work lives.
  Widget _needsYou() {
    final opened = _opened();
    if (opened != null) return opened;
    return Focus(
      focusNode: _openedFocus,
      child: AttentionView(
        attention: _attention,
        onDecide: (tile, prompt, {required allow}) => tile.fleet.clearance
            .decide(tile.fleet.backend, prompt, allow: allow),
        actionsFor: _tileActions,
        onSelect: _goToWork,
        onReview: (tile) {
          _select(tile);
          unawaited(_openTheGate());
        },
      ),
    );
  }

  /// One machine: its title and menu, then its projects and work, then what it ran.
  Widget _machineArea() {
    final machine = widget.machines.current;
    final fleet = _fleet;
    final highlight = widget.shell.highlight;
    // A refusal takes the place of whatever was open: it is the most important thing on the
    // screen until somebody has decided about it.
    final refusal = fleet.refusal;
    final opened = refusal != null
        ? RefusalView(refusal: refusal, fleet: fleet)
        : _opened();
    return Column(
      children: <Widget>[
        MachineTitle(
          machine: machine,
          fleet: fleet,
          tunnel: widget.machines.tunnels.of(machine),
          kind: machineKind(widget.machines, machine),
          onStop: _stopEverything,
          menu: _machineMenu(),
          highlight: highlight,
          onShown: widget.shell.shown,
        ),
        Expanded(child: opened ?? _machineBody(machine, fleet, highlight)),
        StatusLine(
          fleet: fleet,
          operations: widget.operations,
          machine: machine.name,
          cannotNotify: widget.notifications.problem,
          highlighted: highlight == 'operations.show',
          onShowOperations: widget.shell.openOperations,
        ),
      ],
    );
  }

  /// Running work on every project, or the selected project with its work under its header.
  Widget _machineBody(Machine machine, FleetModel fleet, String? highlight) {
    final projects = fleet.projects;
    final narrowed = fleet.selectedProject;
    final selectedTask = fleet.selectedTask;
    final tiles = <Tile>[
      for (final tile in _attention.tilesOn(machine))
        if (narrowed == null
            ? tile.task == null || tile.task!.running
            : tile.task != null && tile.task!.project == narrowed.name)
          tile,
    ];
    final jobs = narrowed == null
        ? const <Template>[]
        : widget.templates.forProject(narrowed.name);
    return Column(
      children: <Widget>[
        if (narrowed != null)
          ProjectHeader(
            project: narrowed,
            muted: widget.notifications.muted.contains(narrowed.name),
            menu: _projectMenu(narrowed),
            highlight: highlight,
            onShown: widget.shell.shown,
          ),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('machine-area'),
            padding: const EdgeInsets.all(Space.normal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.small),
                    child: Text(
                      _noProjects(fleet),
                      key: const Key('no-projects'),
                    ),
                  ),
                const SizedBox(height: Space.small),
                Wrap(
                  spacing: Space.normal,
                  runSpacing: Space.normal,
                  children: <Widget>[
                    for (final tile in tiles)
                      TaskTile(
                        tile: tile,
                        actions: tile.task == null
                            ? const <Command>[]
                            : _tileActions(tile),
                        onDecide: (tile, prompt, {required allow}) => tile
                            .fleet
                            .clearance
                            .decide(tile.fleet.backend, prompt, allow: allow),
                        onReview: (tile) {
                          _select(tile);
                          unawaited(_openTheGate());
                        },
                        selected:
                            tile.task != null &&
                            selectedTask?.name == tile.task!.name,
                        onSelect: tile.task == null
                            ? null
                            : () => fleet.selectTask(tile.task!.name),
                        onOpen: tile.task == null
                            ? null
                            : () {
                                fleet.selectTask(tile.task!.name);
                                _openWork();
                              },
                        highlight:
                            selectedTask != null &&
                                selectedTask.name == tile.task?.name
                            ? highlight
                            : null,
                        onShown: widget.shell.shown,
                      ),
                    if (narrowed != null)
                      StartTile(
                        project: narrowed.label,
                        unavailable: StartWork.whyNot(narrowed.project),
                        highlighted: highlight == 'work.start',
                        onStart: () => unawaited(_startWork()),
                      ),
                    for (final job in jobs)
                      TemplateTile(
                        job: job,
                        highlighted:
                            highlight ==
                            'template.start/${job.project}/${job.name}',
                        unavailable: job.startable
                            ? null
                            : 'this job is missing something it needs to run',
                        onPressed: () => unawaited(_startFromTemplate(job)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _noProjects(FleetModel fleet) => switch (fleet.reachability) {
    Reachability.connecting => 'Asking the backend what is here.',
    Reachability.unreachable => 'Not connected, so what is here is unknown. This is not an empty machine.',
    Reachability.incompatible =>
      'This backend speaks nothing this build understands.',
    Reachability.connected =>
      'No work has run on this machine, so no project names itself yet.',
  };

  /// What is open over the frame, or null when nothing is.
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
        return WorkDetail(
          task: task,
          held: widget.held,
          onClose: widget.shell.close,
        );
      case VaultOpened():
        return VaultView(
          vault: widget.vault,
          onLock: () => widget.vault.lock(_fleet.backend),
          onClose: widget.shell.close,
        );
      case BackupsOpened():
        return BackupsView(
          backups: widget.backups,
          onConsider: (backup) =>
              widget.backups.consider(_fleet.backend, backup),
          onConsiderRestoring: (backup) =>
              widget.backups.considerRestoring(_fleet.backend, backup),
          onRestore: ({required force}) => _restoreTheMirror(force: force),
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
        // Gone because the machine was switched, or because it was left.
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
      case ProjectCreationOpened():
        return ProjectCreationPanel(
          creation: widget.creating,
          setsHere: _setsHere,
          onCheck: () => widget.creating.check(_fleet.backend),
          onCreate: () async {
            await widget.creating.create(_fleet.backend);
            final said = widget.creating.words;
            if (said.isNotEmpty) _fleet.say(said);
          },
          onDone: (made) => unawaited(_doneCreating(made)),
        );
      case OperationsOpened():
        return OperationsList(
          operations: widget.operations,
          machine: widget.machines.current.name,
          focusNode: _openedFocus,
          onOpen: widget.shell.openOperation,
          onClose: widget.shell.close,
        );
      case OperationOpened(:final id):
        final operation = widget.operations.byId(id);
        if (operation == null) return null;
        return OperationOutputView(
          operation: operation,
          onBack: widget.shell.openOperations,
          onClose: widget.shell.close,
        );
    }
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
    if (done != null) {
      _fleet.say('${done.outcome.label}. ${done.detail}'.trim());
    }
  }

  /// Which sets a preview's hosts came from, so the change can be asked for again in the same
  /// words rather than remembered as a promise.
  static List<String> _setsIn(List<EgressHost> hosts) => <String>{
    for (final host in hosts)
      if (host.origin.startsWith('set ')) host.origin.substring(4),
  }.toList();

  /// Opens a shell inside running work, or goes back to the one that is already open.
  void _openSession(Task task) {
    widget.sessions.openOn(task.name, widget.machines.current);
    widget.shell.openSession(task.name);
  }

  @override
  void dispose() {
    widget.shell.removeListener(_moveKeyboard);
    _leaving.dispose();
    _attention.dispose();
    _openedFocus.dispose();
    _frameFocus.dispose();
    super.dispose();
  }
}

/// Runs the command with this id, whatever key, menu or finder asked for it.
class _RunCommand extends Intent {
  const _RunCommand(this.id);

  final String id;
}
