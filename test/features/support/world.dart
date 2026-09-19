import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/fleet_backend.dart';
import 'package:sokar_frontend/src/app/fleet_model.dart';
import 'package:sokar_frontend/src/app/host_keys.dart';
import 'package:sokar_frontend/src/app/machine_setup.dart';
import 'package:sokar_frontend/src/app/egress.dart';
import 'package:sokar_frontend/src/app/agent_inventory.dart';
import 'package:sokar_frontend/src/app/emergency_stop.dart';
import 'package:sokar_frontend/src/app/start_work.dart';
import 'package:sokar_frontend/src/app/templates.dart';
import 'package:sokar_frontend/src/app/project_deletion.dart';
import 'package:sokar_frontend/src/app/pty.dart';
import 'package:sokar_frontend/src/app/session.dart';
import 'package:sokar_frontend/src/app/vault.dart';
import 'package:sokar_frontend/src/app/device_key.dart';
import 'package:sokar_frontend/src/app/tunnel.dart';
import 'package:sokar_frontend/src/app/widening.dart';
import 'package:sokar_frontend/src/app/work_held.dart';
import 'package:sokar_frontend/src/app/gate.dart';
import 'package:sokar_frontend/src/app/authentication.dart';
import 'package:sokar_frontend/src/app/backups.dart';
import 'package:sokar_frontend/src/app/host_readiness.dart';
import 'package:sokar_frontend/src/app/logs.dart';
import 'package:sokar_frontend/src/app/machines.dart';
import 'package:sokar_frontend/src/app/narrowing.dart';
import 'package:sokar_frontend/src/app/project_following.dart';
import 'package:sokar_frontend/src/app/newer_version.dart';
import 'package:sokar_frontend/src/app/where_you_were.dart';
import 'package:sokar_frontend/src/app/notifications.dart';
import 'package:sokar_frontend/src/app/operations.dart';
import 'package:sokar_frontend/src/app/settings.dart';
import 'package:sokar_frontend/src/app/shell_model.dart';
import 'package:sokar_frontend/src/app/sokar_app.dart';

/// A backend that answers whatever a scenario needs it to.
///
/// Not the mock daemon, and the difference is the point: the mock daemon proves the *client*
/// over a real socket, and it lives in `test/client` where the wire is what is being judged.
/// This proves the *frame*, which is judged on what a person sees — including when the backend
/// refuses, has no `Watch`, or goes away. A widget test runs on a fake clock and real socket
/// input never completes under it, so the frame has to be reachable without one.
class FakeBackend implements FleetBackend {
  /// Constructor taking what the machine has on it.
  FakeBackend(this._tasks);

  List<Task> _tasks;
  final _changes = StreamController<List<Task>>.broadcast();

  /// What `GetInfo` answers.
  ServiceInfo whatItIs = const ServiceInfo(
    product: 'Sokar',
    version: '0.1.0-mock',
    vendor: 'fuin.org',
    interfaces: <String>['org.varlink.service', 'org.fuin.sokar.Tasks1'],
  );

  /// Set to refuse [open], the way a machine with no daemon on it does.
  VarlinkDisconnected? absent;

  /// Set to refuse [watch], the way a backend older than `Watch` does.
  bool withoutWatch = false;

  /// What the most recent [startTask] is printing into.
  ///
  /// The scenario drives it: a line at a time, ended when the scenario says so. Nothing here is
  /// on a clock, or a test of a long operation becomes a test of how fast the machine is.
  late StreamController<String> launch;

  /// How many launches have been asked for, and with what.
  final List<bool> launched = <bool>[];

  /// Every launch, as it was asked for. What mode and prompt went down the socket is the whole
  /// of it — a screen that offered one and sent another would be wrong invisibly.
  final List<({String? task, String? project, String? agent, Mode? mode, String? prompt, String? repository})>
      starts =
      <({String? task, String? project, String? agent, Mode? mode, String? prompt, String? repository})>[];

  /// What `Agents` answers, and what could not be read.
  List<Agent> theAgentsItHas = <Agent>[
    Agent.from(const <String, dynamic>{
      'name': 'an-agent',
      'label': 'An Agent',
      'binary': '/usr/bin/an-agent',
      'version': '2.4.0',
      'from': '/usr/share/sokar/agents/an-agent.yml',
      'allowedDomains': <String>['api.anthropic.com'],
      'refusedDomains': <String>['telemetry.example.test'],
      // What its commits are attributed to. The second agent has none, which is what an agent
      // installed by a Sokar older than the field answers — a state to render, not a blank.
      'commitsAs': <String, dynamic>{
        'name': 'An Agent',
        'email': 'an-agent@sokar.invalid',
      },
      'artifacts': <Map<String, dynamic>>[
        <String, dynamic>{
          'url': 'https://example.test/an-agent-2.4.0.tar.gz',
          'sha256': '3b1f8e2a9c4d5067a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718',
          'target': '/opt/an-agent',
          'unverified': false,
          'reason': '',
        },
      ],
    }),
    Agent.from(const <String, dynamic>{
      'name': 'other-agent',
      'label': 'Another Agent',
      'binary': '/usr/bin/other-agent',
      'version': '',
      'from': '/etc/sokar/agents/other-agent.yml',
      'allowedDomains': <String>['api.example.test'],
      'artifacts': <Map<String, dynamic>>[
        <String, dynamic>{
          'url': 'https://example.test/other-agent-latest.tar.gz',
          'sha256': '',
          'target': '/opt/other-agent',
          'unverified': true,
          'reason': 'upstream publishes no digest for the rolling build',
        },
      ],
    }),
  ];

  /// Binaries installed and never started, because another copy wins.
  List<ShadowedAgent> theAgentsItNeverUses = const <ShadowedAgent>[];

  /// Agents that could not be read, and why.
  Map<String, String> theAgentsItCannotRead = const <String, String>{};

  @override
  Future<AgentsOnTheMachine> agentsOn() async => (
        agents: theAgentsItHas,
        failures: theAgentsItCannotRead,
        shadowed: theAgentsItNeverUses,
      );

  @override
  String get label => 'mock';

  @override
  Future<ServiceInfo> open() async {
    final refusal = absent;
    if (refusal != null) throw refusal;
    return whatItIs;
  }

  @override
  Future<List<Task>> tasks() async => _tasks;

  /// What `Projects` answers. Assembled by the daemon, so a scenario sets it rather than the
  /// interface deriving it.
  List<Project> theProjectsItHas = <Project>[
    Project.from(<String, dynamic>{
      'name': 'checkout',
      'securityClass': 'guarded',
      'file': '/srv/checkout/project.yml',
      'mirror': '/srv/checkout/.sokar/mirror',
      'prepared': true,
      'preparedState': 'READY',
      'behind': 3,
      'behindMeasured': DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 20))
          .toIso8601String(),
      'behindReason': 'MEASURED',
      'pending': 2,
      'tasks': 2,
      'running': 1,
    }),
    // Listed and not actionable: no task start has recorded a file, or the recorded one moved.
    Project.from(const <String, dynamic>{
      'name': 'unrecorded',
      'securityClass': 'guarded',
      'file': '',
      'mirror': '/srv/unrecorded/.sokar/mirror',
      // Nothing has run here, so no image was built and nothing was ever checked.
      'prepared': false,
      'preparedState': 'ABSENT',
      'behindReason': 'NEVER_CHECKED',
      'pending': 1,
      'tasks': 0,
      'running': 0,
    }),
    Project.from(const <String, dynamic>{
      'name': 'billing',
      'securityClass': 'offline',
      'file': '/srv/billing/project.yml',
      'mirror': '',
      // **Prepared and up to date are different questions**, and this is the pair that shows it:
      // an image is there, and it was built before the project file changed under it.
      'prepared': true,
      'preparedState': 'STALE',
      // Reaches nothing, so nothing was tried. Distinct from zero, which would read as up to date.
      'behindReason': 'OFFLINE',
      'pending': 0,
      'tasks': 2,
      'running': 2,
    }),
  ];

  @override
  Future<List<Project>> projects() async => theProjectsItHas;

  @override
  Stream<List<Task>> watch() async* {
    if (withoutWatch) throw const FeatureNotSupported('Watch');
    yield _tasks;
    yield* _changes.stream;
  }

  @override
  Stream<String> startTask({
    String? task,
    String? project,
    String? agent,
    bool dryRun = false,
    Mode? mode,
    String? prompt,
    String? model,
    int? maxTurns,
    int? minutes,
    String? repository,
  }) {
    if (project != null) mustBeAProject(project);
    launched.add(dryRun);
    starts.add((task: task, project: project, agent: agent, mode: mode, prompt: prompt, repository: repository));
    launch = StreamController<String>();
    return launch.stream;
  }

  /// Every stop asked for, by task.
  final List<String> stops = <String>[];

  /// Keeps the task listed, stopped: a stop keeps the workspace.
  @override
  Future<Stopped> stopTask(String task) async {
    stops.add(task);
    _tasks = <Task>[
      for (final each in _tasks)
        each.name == task ? _with(each, running: false, startAction: 'RESUME') : each,
    ];
    _changes.add(_tasks);
    return Stopped.from(const <String, dynamic>{
      'outcome': 'STOPPED',
      'helpers': 2,
      'surviving': <String>[],
    });
  }

  /// What the next [removeTask] answers. Set by the scenario, so a refusal can be produced without
  /// contriving a task that genuinely holds commits.
  Removed nextRemove = Removed.from(const <String, dynamic>{
    'outcome': 'REMOVED',
    'work': '',
    'rescuedRef': '',
    'removed': true,
    'discarded': 3 * 1024 * 1024,
  });

  /// Every removal asked for, and how it was asked.
  final List<({String task, bool? rescue, bool? force})> removals =
      <({String task, bool? rescue, bool? force})>[];

  /// Acts on the machine, rather than only answering about it.
  ///
  /// A stand-in that says a task was removed and goes on listing it makes a working interface
  /// look like one where nothing happens. That was found by hand, against the other stand-in,
  /// with every test green — so both of them act now, and a scenario holds this one to it.
  @override
  Future<Removed> removeTask(String task, {bool? rescue, bool? force}) async {
    removals.add((task: task, rescue: rescue, force: force));
    // Held work is said first; a running task that holds nothing is refused as still running.
    final running = _tasks.any((each) => each.name == task && each.running);
    if (running && nextRemove.removed && rescue != true && force != true) {
      return Removed.from(const <String, dynamic>{
        'outcome': 'STILL_RUNNING',
        'work': '',
        'rescuedRef': '',
        'removed': false,
        'discarded': 0,
      });
    }
    if (nextRemove.removed) {
      _tasks = _tasks.where((each) => each.name != task).toList();
      _changes.add(_tasks);
    }
    return nextRemove;
  }

  /// What the next [startAgain] answers.
  StartProgress nextStart = const StartProgress(
    action: StartAction.resume,
    exitCode: 0,
    helpersStarted: 2,
    helpersRecorded: 2,
  );

  /// Every start of a listed task, by the project file and the name within it that were sent.
  final List<({String project, String task, String? repository})> startedAgain =
      <({String project, String task, String? repository})>[];

  /// Acts like [removeTask]: a task started again goes on listed as running, or a screen that
  /// ignored the answer would pass.
  @override
  Future<StartProgress> startAgain({required String project, required String task, String? repository}) async {
    mustBeAProject(project);
    startedAgain.add((project: project, task: task, repository: repository));
    if (nextStart.action == StartAction.resume) {
      _tasks = <Task>[
        for (final each in _tasks)
          each.task == task ? _with(each, running: true, startAction: 'RUNNING') : each,
      ];
      _changes.add(_tasks);
    }
    return nextStart;
  }

  /// [task] with its running state, and what Start would do to it, changed.
  static Task _with(Task task, {required bool running, required String startAction}) =>
      Task.from(<String, dynamic>{
        ...wire(task),
        'state': running ? 'Up 1 second' : 'Exited (143) 0 seconds ago',
        'running': running,
        'helpers': running ? 2 : 0,
        'activity': running ? 'WORKING' : 'DEAD',
        'startAction': startAction,
      });

  /// What the next [tailLog] prints into, so the scenario decides when a line arrives.
  late StreamController<List<String>> tailing;

  /// Logs this machine has. What `Logs` answers, and what `Tail` accepts.
  Set<String> theLogsItHas = <String>{'agent.log'};

  /// What each of them holds, for the ones whose names do not say. The daemon's sentence: nothing
  /// at this end composes one, so a log the scenario says nothing about is described by nothing.
  final Map<String, String> whatTheLogsHold = <String, String>{};

  /// Blocked connections, driven by the scenario. Nothing here is on a clock: a question with a
  /// deadline tested against wall time is a flaky test of the one thing that must not be flaky.
  final asking = StreamController<Prompt>.broadcast();

  /// Every answer that was sent, and what it said.
  final List<({String key, bool allow})> decisions =
      <({String key, bool allow})>[];

  /// Set to refuse the next answer, the way a task that has stopped running does.
  VarlinkException? refuseTheAnswer;

  /// What the next [panic] answers. A scenario sets it to produce a surviving helper, which no
  /// contrived task list can produce on demand.
  Panicked? nextPanic;


  /// Every panic asked for, and whether it was only a preview.
  final List<bool> panics = <bool>[];

  /// Every caption asked for, and what it was.
  final List<({String task, String? label})> labels =
      <({String task, String? label})>[];

  /// What the next [labelTask] answers. A scenario sets it for a task older than the field.
  Labelled? nextLabel;

  @override
  Future<Labelled> labelTask(String task, {String? label}) async {
    labels.add((task: task, label: label));
    final answer = nextLabel;
    if (answer != null) return answer;
    final caption = label?.trim() ?? '';
    // The caption goes onto the task, so a screen that said it worked and went on showing the old
    // one would be caught here rather than by hand.
    _tasks = <Task>[
      for (final each in _tasks)
        if (each.name == task)
          Task.from(<String, dynamic>{
            'name': each.name,
            'task': each.task,
            'label': caption,
            'project': each.project,
            'securityClass': each.securityClass,
            'state': each.state,
            'running': each.running,
            'helpers': each.helpers,
            'clearance': each.clearance,
            'mode': each.mode.name,
            'prompt': each.prompt,
            'agent': each.agent,
          })
        else
          each,
    ];
    _changes.add(_tasks);
    return Labelled(
      outcome: caption.isEmpty ? 'CLEARED' : 'LABELLED',
      label: caption,
    );
  }

  /// What `Credentials` answers. A scenario sets it to produce a shut store, which is a state no
  /// contrived list of names can express.
  VaultState theStoreIs = VaultState.from(const <String, dynamic>{
    'vault': '/home/somebody/.local/share/sokar/vault.bin',
    'exists': true,
    'credentials': <Map<String, dynamic>>[
      <String, dynamic>{'name': 'a-provider', 'type': 'api-key', 'characters': 108},
    ],
    'readable': true,
  });

  /// What the next [lock] answers.
  Locked nextLock = const Locked(keyring: true, wasCached: true, holding: 0);

  /// How long `Credentials` takes to answer, so a slow one can be overtaken by a fast one.
  Duration credentialsTake = Duration.zero;

  /// Every question asked of the store, in the order it was asked.
  final List<String> storeAsked = <String>[];

  @override
  Future<VaultState> credentials() async {
    storeAsked.add('credentials');
    if (credentialsTake > Duration.zero) await Future<void>.delayed(credentialsTake);
    return theStoreIs;
  }

  @override
  Future<Locked> lock() async {
    storeAsked.add('lock');
    // Shutting really shuts it, so the button beside the stop turns into the one that opens it.
    if (theStoreIs.readable) {
      _whileOpen = theStoreIs;
      theStoreIs = VaultState.from(<String, dynamic>{
        'vault': theStoreIs.vault,
        'exists': true,
        'credentials': <Map<String, dynamic>>[],
        'readable': false,
      });
    }
    return nextLock;
  }

  /// What the store held before it was shut, for a device to open it onto again.
  VaultState? _whileOpen;

  /// What the next [canStart] answers. A scenario sets it to produce a locked vault or a missing
  /// credential, neither of which a contrived agent list can produce.
  Readiness? nextReadiness;

  /// The vault's keyslots, as Sokar B60 proposes them: the recovery passphrase, and every device
  /// enrolled here. Behaves like the node — a share it has seen opens its slot, nothing else does —
  /// so a screen that ignored an answer would fail a scenario rather than pass one.
  final List<({Keyslot slot, String share})> keyslotsHeld = <({Keyslot slot, String share})>[
    (
      slot: const Keyslot(
        id: 'slot-0',
        name: 'recovery passphrase',
        storage: KeyslotStorage(''),
        enrolled: '2026-09-01T10:00:00Z',
        lastUsed: '',
        self: false,
        recovery: true,
      ),
      share: '',
    ),
  ];

  /// Every share that was sent here, to check nothing was sent twice or kept.
  final List<String> sharesSent = <String>[];

  /// How long each unlock asked for, null where it asked for no bound.
  final List<int?> unlocksFor = <int?>[];

  /// Set for a Sokar from before B60, which does not know the four methods.
  bool keyslotsUnknown = false;

  void _b60(String method) {
    if (keyslotsUnknown) throw FeatureNotSupported(method);
  }

  @override
  Future<Enrolled> enrollDevice({
    required String name,
    required String share,
    required KeyslotStorage storage,
  }) async {
    _b60('EnrollDevice');
    sharesSent.add(share);
    if (!storage.recognized) {
      return const Enrolled(outcome: KeyslotOutcome.unknownStorage, slot: null, detail: '');
    }
    final known = keyslotsHeld.where((held) => held.share == share).firstOrNull;
    if (known != null) {
      return Enrolled(outcome: KeyslotOutcome.alreadyEnrolled, slot: known.slot, detail: '');
    }
    final slot = Keyslot(
      id: 'slot-${keyslotsHeld.length}',
      name: name,
      storage: storage,
      enrolled: '2026-09-18T08:00:00Z',
      lastUsed: '',
      self: false,
      recovery: false,
    );
    keyslotsHeld.add((slot: slot, share: share));
    return Enrolled(outcome: KeyslotOutcome.enrolled, slot: slot, detail: '');
  }

  @override
  Future<List<Keyslot>> keyslots() async {
    _b60('Keyslots');
    return <Keyslot>[for (final held in keyslotsHeld) held.slot];
  }

  @override
  Future<Revoked> revokeKeyslot(String id) async {
    _b60('RevokeKeyslot');
    final before = keyslotsHeld.length;
    keyslotsHeld.removeWhere((held) => held.slot.id == id);
    return Revoked(
      outcome: keyslotsHeld.length == before ? KeyslotOutcome.noSuchSlot : KeyslotOutcome.revoked,
      remaining: <Keyslot>[for (final held in keyslotsHeld) held.slot],
      detail: '',
    );
  }

  @override
  Future<UnlockedWithShare> unlockWithShare({required String share, int? minutes}) async {
    _b60('UnlockWithShare');
    sharesSent.add(share);
    unlocksFor.add(minutes);
    final opens = keyslotsHeld.where((held) => held.share.isNotEmpty && held.share == share).firstOrNull;
    if (opens == null) {
      return const UnlockedWithShare(outcome: KeyslotOutcome.shareRejected, until: '', slot: null, detail: '');
    }
    theStoreIs = _whileOpen ?? theStoreIs;
    return UnlockedWithShare(outcome: KeyslotOutcome.unlocked, until: '2026-09-18T08:30:00Z', slot: opens.slot, detail: '');
  }

  /// A name this machine refuses, and its words, the way a daemon with a rule of its own would.
  ({String name, String words})? refusedName;

  /// Refuses anything but the name of a project this machine has, as Sokar does since projects are
  /// named rather than pointed at. Loud rather than a refusal a screen could render: a path sent
  /// here is this interface being wrong, never the machine answering.
  void mustBeAProject(String project) {
    if (!theProjectsItHas.any((each) => each.name == project)) {
      throw StateError('"$project" is not the name of a project this machine has');
    }
  }

  /// Every name `CanStart` was asked about, null where none was sent.
  final List<String?> askedAboutNames = <String?>[];

  /// What each repository adds to what the project may reach, by repository name.
  final Map<String, List<EgressHost>> theRepositoryAdds = <String, List<EgressHost>>{};

  /// Every repository `Egress` was asked about, null where none was sent.
  final List<String?> egressAskedIn = <String?>[];

  /// Every repository `SetEgress` was asked to write into, null where none was sent.
  final List<String?> egressChangedIn = <String?>[];

  /// Every repository `CanStart` was asked about, null where none was sent.
  final List<String?> askedAboutRepositories = <String?>[];

  @override
  Future<Readiness> canStart({String? project, String? agent, String? task, String? repository}) async {
    if (project != null) mustBeAProject(project);
    askedAboutNames.add(task);
    askedAboutRepositories.add(repository);
    // As a Sokar with B67 answers: a project that names repositories needs one chosen.
    final named = theProjectsItHas.where((each) => each.name == project).firstOrNull?.repositories;
    if (repository == null && named != null && named.isNotEmpty) {
      return Readiness(
        ready: false,
        outcome: StartOutcome.noRepositoryChosen,
        agent: agent ?? '',
        provider: '',
        credential: '',
        detail: 'choose one of: ${named.join(', ')}',
      );
    }
    final refused = refusedName;
    if (refused != null && task == refused.name) {
      return Readiness(
        ready: false,
        outcome: StartOutcome.badTaskName,
        agent: agent ?? '',
        provider: '',
        credential: '',
        detail: refused.words,
      );
    }
    return nextReadiness ??
        const Readiness(
          ready: true,
          outcome: StartOutcome.ready,
          agent: 'an-agent',
          provider: 'a-provider',
          credential: 'a-provider',
          detail: '',
        );
  }

  /// Set to lose the machine part way through stopping it.
  bool refusePanic = false;

  /// What backups a project has. Set by the scenario.
  ///
  /// **One that was moved is in here on purpose**: a record is not the bundle, and an absent file
  /// is shown rather than dropped — dropping it would say the backup was never taken.
  List<Backup> theBackupsItHas = <Backup>[
    const Backup(
      taken: '2026-09-08T09:15:00Z',
      bundle: '/srv/checkout/backups/before-sync.bundle',
      refs: 2,
      present: true,
      bytes: 4 * 1024 * 1024,
    ),
    const Backup(
      taken: '2026-09-07T18:02:00Z',
      bundle: '/srv/checkout/backups/moved-away.bundle',
      refs: 5,
      present: false,
      bytes: 0,
    ),
  ];

  @override
  Future<List<Backup>> backups(String project, {String? repository}) async {
    backupsAskedIn.add(repository);
    return theBackupsItHas;
  }

  /// Every repository the backups were asked for, null where none was sent.
  final List<String?> backupsAskedIn = <String?>[];

  /// Every repository a sync was asked for, null where none was sent.
  final List<String?> syncedIn = <String?>[];

  /// Every repository a restore was asked to write into, null where none was sent.
  final List<String?> restoredIn = <String?>[];

  /// What a task holds. Set by the scenario.
  ///
  /// **Readable with two zeros by default**, which is *holds nothing* — a scenario that wants
  /// *nobody could look* says so, because those are the two the screen must not merge.
  HeldWork theWorkItHolds =
      const HeldWork(readable: true, changedFiles: 0, unpushedCommits: 0);

  /// Whether the next ask is for a name that is no task at all.
  bool workHeldIsNoSuchTask = false;

  /// Every task asked about.
  final List<String> held = <String>[];

  @override
  Future<HeldWork> workHeld(String task) async {
    held.add(task);
    // A wrong name is a refusal, never an unreadable answer: collapsing them would make a
    // client's mistake arrive as a legitimate reading.
    if (workHeldIsNoSuchTask) {
      throw const VarlinkException('org.fuin.sokar.Tasks1.NoSuchTask');
    }
    return theWorkItHolds;
  }

  /// What the next sync answers. Set by the scenario.
  Synced theSyncAnswers = const Synced(
      outcome: 'MEASURED', behind: 3, measured: true, reason: 'MEASURED', detail: '');

  /// Every project a sync was asked for.
  final List<String> syncs = <String>[];

  @override
  Future<Synced> syncUpstream(String project, {String? repository}) async {
    syncs.add(project);
    syncedIn.add(repository);
    return theSyncAnswers;
  }

  /// Refs a restore would destroy, or empty when it would destroy none. Set by the scenario.
  List<String> theRestoreWouldDestroy = const <String>[];

  /// Every restore asked for.
  final List<({String bundle, bool preview, bool force})> restores =
      <({String bundle, bool preview, bool force})>[];

  @override
  Future<Restored> restoreBackup(String project, String bundle,
      {bool? dryRun, bool? force, String? repository}) async {
    restoredIn.add(repository);
    restores.add((
      bundle: bundle,
      preview: dryRun == true,
      force: force == true,
    ));
    final refused = theRestoreWouldDestroy.isNotEmpty && force != true;
    return Restored(
      outcome: dryRun == true
          ? 'PREVIEWED'
          : refused
              ? 'HOLDS_WORK'
              : 'RESTORED',
      mirror: '/srv/$project/.sokar/mirror',
      // Filled under force too: it is what force destroyed, and somebody who forced needs it
      // afterwards rather than only in the warning they clicked past.
      unreviewed: theRestoreWouldDestroy,
      detail: '',
    );
  }

  /// Whether the next deletion finds the file there. Set by the scenario.
  bool theBundleIsThere = true;

  /// Every backup deletion asked for.
  final List<({String bundle, bool preview})> backupDeletions =
      <({String bundle, bool preview})>[];

  @override
  Future<BackupDeleted> deleteBackup(String project, String bundle,
      {bool? dryRun}) async {
    backupDeletions.add((bundle: bundle, preview: dryRun == true));
    final known = theBackupsItHas.where((each) => each.bundle == bundle);
    if (known.isEmpty) {
      return const BackupDeleted(
          outcome: 'NO_SUCH_BACKUP',
          fileRemoved: false,
          refs: 0,
          detail: 'no record names that path');
    }
    return BackupDeleted(
      outcome: dryRun == true ? 'PREVIEWED' : 'DELETED',
      fileRemoved: theBundleIsThere,
      refs: known.first.refs,
      detail: '',
    );
  }

  /// What the next creation answers. Set by the scenario.
  ///
  /// **The rendered file is filled even on a refusal**, because seeing what was rejected is most
  /// of understanding why.
  String theCreationAnswers = 'CREATED';

  /// What the machine says is wrong with the answers. Set by the scenario.
  List<Problem> theCreationProblems = const <Problem>[];

  /// Set for a Sokar from before QF22, which does not choose where a project file goes.
  bool choosesNoPlace = false;

  /// Every creation asked for.
  final List<({String file, String name, String securityClass, bool preview})> creations =
      <({String file, String name, String securityClass, bool preview})>[];

  /// What a build prints before it ends. Set by the scenario.
  List<String> theBuildPrints = <String>[
    'STEP 1/6: FROM ubuntu:24.04',
    'STEP 4/6: RUN apt-get install -y git',
    'COMMIT sokar/checkout:latest',
  ];

  /// How the next build ends.
  String theBuildEndsWith = 'PREPARED';

  /// Every build asked for: the project, the depth, and whether it was a preview.
  final List<({String project, String? rebuild, bool preview})> builds =
      <({String project, String? rebuild, bool preview})>[];

  @override
  Stream<PrepareProgress> prepare(String project,
      {String? agent, String? rebuild, bool? dryRun}) async* {
    mustBeAProject(project);
    builds.add((project: project, rebuild: rebuild, preview: dryRun == true));
    for (final line in theBuildPrints) {
      yield PrepareProgress(line: line);
    }
    yield PrepareProgress(
      outcome: theBuildEndsWith,
      image: theBuildEndsWith == 'PREPARED' ? 'sokar/checkout:latest' : '',
      // Read back rather than echoed: a depth the daemon did not recognise has to be visible.
      rebuild: rebuild ?? 'CACHED',
      detail: theBuildEndsWith == 'FAILED'
          ? 'STEP 4/6: RUN apt-get install -y git returned 100'
          : '',
    );
  }

  /// What the machine answers about itself. Set by the scenario.
  ///
  /// **Ready with nothing wrong by default**, because that is the ordinary machine — a scenario
  /// that wants a broken one says which probe broke.
  Health theHealthItReports = const Health(
    probes: <Probe>[
      Probe(name: 'podman', state: 'OK', detail: '5.2.1', action: ''),
      Probe(name: 'nft', state: 'OK', detail: 'v1.0.9', action: ''),
    ],
    ready: true,
  );

  /// Every time the machine was asked whether it can run anything.
  int healthAsked = 0;

  /// Set for a daemon older than `Doctor`.
  bool doctorIsUnsupported = false;

  @override
  Future<Health> doctor() async {
    healthAsked++;
    if (doctorIsUnsupported) {
      throw const FeatureNotSupported('Doctor');
    }
    return theHealthItReports;
  }

  /// What providers the machine has. Set by the scenario.
  Providers theProvidersItHas = const Providers(
    providers: <Provider>[
      Provider(
        name: 'a-provider',
        label: 'A Provider',
        upstream: 'api.example.test',
        dialects: <String>['api-key'],
        authenticated: true,
        credentialType: 'api-key',
        credentialName: 'a-provider',
        storeCommand: 'sokar vault put a-provider',
      ),
      // Not authenticated, and stored under the *agent's* name rather than its own — the fallback
      // key a client could never have worked out.
      Provider(
        name: 'other-provider',
        label: 'Another Provider',
        upstream: 'api.other.test',
        dialects: <String>['api-key', 'oauth'],
        authenticated: false,
        credentialType: '',
        credentialName: 'an-agent',
        storeCommand: 'sokar vault put an-agent --type oauth',
      ),
    ],
    readable: true,
  );

  @override
  Future<Providers> providers() async => theProvidersItHas;

  /// What the next import answers. Set by the scenario.
  Imported theImportAnswers = const Imported(
    outcome: 'IMPORTED',
    name: 'an-agent',
    type: 'api-key',
    length: 51,
    source: '/home/somebody/.config/an-agent/credentials.json',
    detail: '',
  );

  /// Which agents were asked to be imported.
  final List<String?> imports = <String?>[];

  @override
  Future<Imported> importCredential({String? agent, String? configDirectory}) async {
    imports.add(agent);
    return theImportAnswers;
  }

  /// Which node this backend is. Set by the scenario; empty means a daemon that cannot say.
  ///
  /// **Two different ones by default**, because that is the ordinary case — one machine per node.
  /// A scenario that wants the same node says so, and one that wants a daemon too old to answer
  /// clears it.
  String nodeId = 'node-a';

  @override
  Future<String> node() async => nodeId;

  /// What the next deletion answers. Set by the scenario.
  DeleteOutcome deletionAnswers = DeleteOutcome.deleted;

  /// Every deletion asked for: the project, and whether it was a preview and whether it was
  /// forced. **Read off the socket** — a screen that shows a preview while having removed a
  /// project is exactly the failure this guards.
  final List<({String project, bool preview, bool force})> deletions =
      <({String project, bool preview, bool force})>[];

  /// What the next [follow] answers, or null for a project taken at once.
  Followed? nextFollow;

  /// Every follow asked for, and how its commits were to be checked.
  final List<({String name, String url, String? signedBy, bool unverified, bool acceptRewrite})>
      follows = <({String name, String url, String? signedBy, bool unverified, bool acceptRewrite})>[];

  /// Acts like Sokar: a follow that is taken makes the project, listed with its follow state.
  @override
  Future<Followed> follow(String name, String url,
      {String? signedBy, bool? unverified, bool? acceptRewrite}) async {
    follows.add((
      name: name,
      url: url,
      signedBy: signedBy,
      unverified: unverified == true,
      acceptRewrite: acceptRewrite == true,
    ));
    final answer = acceptRewrite == true || nextFollow == null
        ? Followed(name: name, url: url, commit: 'c0ffee1d2e3f', outcome: 'APPLIED')
        : nextFollow!;
    if (answer.inForce && !theProjectsItHas.any((each) => each.name == name)) {
      theProjectsItHas = <Project>[
        ...theProjectsItHas,
        Project(
          name: name,
          securityClass: 'guarded',
          file: '/srv/$name/project.yml',
          mirror: '/srv/$name/.sokar/mirror',
          pending: 0,
          tasks: 0,
          running: 0,
          following: answer,
        ),
      ];
    }
    return answer;
  }

  /// Set to refuse the next [unfollow] the way the daemon refuses one.
  VarlinkException? refuseToUnfollow;

  @override
  Future<Deletion> unfollow(String project, {bool? dryRun, bool? force}) async {
    final refusal = refuseToUnfollow;
    if (refusal != null) throw refusal;
    deletions.add((project: project, preview: dryRun == true, force: force == true));
    final refused = deletionAnswers.canBeForced && force != true;
    return Deletion(
      outcome: dryRun == true
          ? DeleteOutcome.previewed
          : refused
              ? deletionAnswers
              : DeleteOutcome.deleted,
      // Filled for a refusal too, so the cost can be shown beside the reason it was stopped.
      removes: const <Removal>[
        Removal(kind: 'MIRROR', what: '/srv/checkout/.sokar/mirror'),
        Removal(kind: 'IMAGE', what: 'sokar/checkout:latest'),
        Removal(kind: 'TASK', what: 'sokar-checkout-shell'),
        Removal(kind: 'TASK', what: 'sokar-checkout-migrate'),
      ],
      keeps: const <String>['/srv/checkout/project.yml'],
      unreviewed: deletionAnswers == DeleteOutcome.holdsWork
          ? const <String>['migrate']
          : const <String>[],
      running: deletionAnswers == DeleteOutcome.tasksRunning
          ? const <String>['sokar-checkout-shell']
          : const <String>[],
      detail: refused ? 'nothing was removed' : '',
    );
  }

  @override
  Future<Panicked> panic({bool? dryRun}) async {
    panics.add(dryRun == true);
    if (refusePanic && dryRun != true) {
      throw const VarlinkDisconnected('the tunnel went away');
    }
    return Panicked.from(<String, dynamic>{
      'tasks': <Map<String, dynamic>>[
        for (final task in _tasks)
          if (task.running)
            <String, dynamic>{
              'name': task.name,
              'helpers': task.helpers,
              'surviving': dryRun == true || nextPanic == null
                  ? const <String>[]
                  : nextPanic!.surviving,
            },
      ],
      'surviving': dryRun == true
          ? const <String>[]
          : nextPanic?.surviving ?? const <String>[],
      'previewed': dryRun == true,
    });
  }

  @override
  Stream<Prompt> prompts() => asking.stream;

  @override
  Future<void> decide(Prompt prompt, {required bool allow}) async {
    final refusal = refuseTheAnswer;
    if (refusal != null) throw refusal;
    decisions.add((key: prompt.key, allow: allow));
  }

  /// What is waiting at the gate. Set by the scenario.
  GateState theGate = GateState.from(const <String, dynamic>{
    'mirror': '/srv/checkout/.sokar/mirror',
    'mode': 'gatekeeping',
    'seededFrom': '',
    'pending': <Map<String, dynamic>>[
      <String, dynamic>{
        // The ref *under* `refs/sokar/incoming/`, which is what the contract answers and what
        // `Review`, `Approve` and `Reject` take. It was the whole ref here until 2026-09-08 —
        // a fixture describing something the daemon cannot produce.
        'name': 'migrate',
        'commit': '9a3c1f2',
        'subject': 'Round to the nearest penny, not away from zero',
        'waiting': '4 minutes',
        'at': '2026-09-07T14:12:00Z',
      },
    ],
  });

  /// What `Review` answers.
  String theDiff = '''
diff --git a/lib/money.dart b/lib/money.dart
--- a/lib/money.dart
+++ b/lib/money.dart
@@ -1,3 +1,3 @@
 class Money {
-  int get pennies => (value * 100).ceil();
+  int get pennies => (value * 100).round();
 }
''';

  /// What was approved, onto which branch, and from which repository — null where none was named.
  final List<({String name, String branch, String? repository})> approvals =
      <({String name, String branch, String? repository})>[];

  /// What each repository's gate holds, where the project names repositories. One that is not here
  /// answers [theGate] for the project's own and nothing for any other.
  final Map<String, GateState> theGatesIn = <String, GateState>{};

  /// Repositories whose gate refuses to be read.
  final Map<String, VarlinkException> refuseTheGateIn = <String, VarlinkException>{};

  /// Every repository the gate was asked about, null where none was sent.
  final List<String?> gateAskedIn = <String?>[];

  /// Every repository `Review` was asked about, null where none was sent.
  final List<String?> reviewedIn = <String?>[];

  /// What was rejected.
  final List<String> rejections = <String>[];

  /// Set to refuse the next gate call the way the daemon refuses one.
  VarlinkException? refuseTheGate;

  /// What `Egress` answers, in the order the sources granted them.
  List<EgressHost> theHostsItMayReach = <EgressHost>[
    EgressHost.from(const <String, dynamic>{
      'host': 'api.anthropic.com',
      'origin': 'agent an-agent',
    }),
    EgressHost.from(const <String, dynamic>{
      'host': 'github.com',
      'origin': 'upstream',
    }),
    EgressHost.from(const <String, dynamic>{
      'host': 'pub.dev',
      'origin': 'set dart-packages',
    }),
  ];

  /// What an agent asks for and is deliberately not given.
  List<String> theHostsItIsRefused = <String>['telemetry.example.test'];

  /// The sets installed on this machine.
  List<EgressSet> theSetsItHas = <EgressSet>[
    EgressSet.from(const <String, dynamic>{
      'name': 'dart-packages',
      'label': 'Dart packages',
      'domains': <String>['pub.dev', 'storage.googleapis.com'],
    }),
    EgressSet.from(const <String, dynamic>{
      'name': 'containers',
      'label': 'Container registries',
      'domains': <String>['registry.fedoraproject.org', 'quay.io', 'docker.io'],
    }),
  ];

  /// What the next change answers. The scenario sets it, including every refusal.
  EgressChange? nextChange;

  /// Every change asked for, and whether it was only a preview.
  final List<({List<String> addSets, bool preview})> changes =
      <({List<String> addSets, bool preview})>[];

  @override
  Future<(List<EgressHost>, List<String>)> egressOf(String projectFile, {String? repository}) async {
    mustBeAProject(projectFile);
    egressAskedIn.add(repository);
    final adds = theRepositoryAdds[repository];
    if (adds != null) {
      return (<EgressHost>[...theHostsItMayReach, ...adds], theHostsItIsRefused);
    }
    return (theHostsItMayReach, theHostsItIsRefused);
  }

  @override
  Future<(List<EgressSet>, List<String>)> egressSets() async =>
      (theSetsItHas, <String>['/etc/sokar/egress.d', '/usr/share/sokar/egress.d']);

  @override
  Future<EgressChange> changeEgress(
    String projectFile, {
    List<String>? addSets,
    List<String>? removeSets,
    List<String>? addDomains,
    List<String>? removeDomains,
    bool? dryRun,
    String? repository,
  }) async {
    mustBeAProject(projectFile);
    egressChangedIn.add(repository);
    changes.add((addSets: addSets ?? <String>[], preview: dryRun == true));
    return nextChange ??
        EgressChange.from(<String, dynamic>{
          'outcome': dryRun == true ? 'PREVIEWED' : 'CHANGED',
          'opens': <Map<String, dynamic>>[
            for (final name in addSets ?? <String>[])
              for (final host in theSetsItHas
                  .firstWhere((set) => set.name == name)
                  .domains)
                <String, dynamic>{'host': host, 'origin': 'set $name'},
          ],
          'closes': <Map<String, dynamic>>[],
          'cost': '',
          'detail': '',
        });
  }

  /// What the next [widenTask] answers, preview or not. A scenario sets it, including every
  /// refusal, so `NOT_RUNNING` and `NO_PROJECT_FILE` can be produced without contriving a
  /// container.
  Widened? nextWidening;

  /// Every widening asked for, and how it was asked.
  final List<({String task, List<String> domains, Scope scope, bool preview})> widenings =
      <({String task, List<String> domains, Scope scope, bool preview})>[];

  @override
  Future<Widened> widenTask(
    String task,
    List<String> domains, {
    required Scope scope,
    bool? dryRun,
  }) async {
    widenings.add((
      task: task,
      domains: domains,
      scope: scope,
      preview: dryRun == true,
    ));
    return nextWidening ??
        Widened.from(<String, dynamic>{
          'outcome': dryRun == true ? 'PREVIEWED' : 'WIDENED',
          'opens': domains,
          'persisted': dryRun != true && scope == Scope.runAndProject,
          'detail': '',
        });
  }

  /// What the next [setClearance] answers. Set by the scenario.
  ClearanceSet? nextClearance;

  /// Every enforcement change asked for.
  final List<({String task, String mode, bool preview})> clearances =
      <({String task, String mode, bool preview})>[];

  @override
  Future<ClearanceSet> setClearance(String task, String mode, {bool? dryRun}) async {
    clearances.add((task: task, mode: mode, preview: dryRun == true));
    final was = _tasks
        .where((each) => each.name == task)
        .map((each) => each.clearance)
        .firstOrNull ??
        '';
    if (nextClearance != null) return nextClearance!;
    return ClearanceSet(
      outcome: dryRun == true
          ? 'PREVIEWED'
          : was == mode
              ? 'UNCHANGED'
              : 'CHANGED',
      was: was,
      // Empty when nothing changed, exactly as the contract says.
      now: dryRun == true || was == mode ? '' : mode,
      detail: '',
    );
  }

  /// What the next [narrowTask] answers, preview or not. Set by the scenario.
  Narrowed? nextNarrowing;

  /// Every narrowing asked for, and how it was asked.
  final List<({String task, List<String> domains, Scope scope, bool preview})> narrowings =
      <({String task, List<String> domains, Scope scope, bool preview})>[];

  @override
  Future<Narrowed> narrowTask(
    String task,
    List<String> domains, {
    required Scope scope,
    bool? dryRun,
  }) async {
    narrowings.add((
      task: task,
      domains: domains,
      scope: scope,
      preview: dryRun == true,
    ));
    return nextNarrowing ??
        Narrowed.from(<String, dynamic>{
          'outcome': dryRun == true ? 'PREVIEWED' : 'NARROWED',
          'closes': domains,
          // Two addresses per name, which is what a resolved host usually has. A scenario that
          // wants the zero case says so.
          'addresses': domains.length * 2,
          'persisted': dryRun != true && scope == Scope.runAndProject,
          'detail': '',
        });
  }

  @override
  Future<GateState> gateOf(String projectFile, {String? repository}) async {
    mustBeAProject(projectFile);
    gateAskedIn.add(repository);
    final refusal = refuseTheGate ?? refuseTheGateIn[repository];
    if (refusal != null) throw refusal;
    final own = theProjectsItHas.where((each) => each.name == projectFile).firstOrNull?.repositories;
    if (repository == null || own == null || own.isEmpty || repository == own.first) {
      return theGatesIn[repository] ?? theGate;
    }
    return theGatesIn[repository] ??
        GateState.from(const <String, dynamic>{'mode': 'gatekeeping', 'pending': <Object>[]});
  }

  @override
  Future<({String diff, String log})> reviewOf(
    String projectFile,
    String name, {
    String? against,
    String? repository,
  }) async {
    mustBeAProject(projectFile);
    reviewedIn.add(repository);
    return (diff: theDiff, log: 'commit 9a3c1f2\n\n    Round to the nearest penny');
  }

  @override
  Future<void> approve(String projectFile, String name, String branch, {String? repository}) async {
    mustBeAProject(projectFile);
    final refusal = refuseTheGate;
    if (refusal != null) throw refusal;
    approvals.add((name: name, branch: branch, repository: repository));
    theGate = GateState.from(const <String, dynamic>{
      'mirror': '/srv/checkout/.sokar/mirror',
      'mode': 'gatekeeping',
      'seededFrom': '',
      'pending': <Map<String, dynamic>>[],
    });
  }

  @override
  Future<void> reject(String projectFile, String name, {String? repository}) async {
    mustBeAProject(projectFile);
    rejections.add(repository == null ? name : '$repository:$name');
    theGate = GateState.from(const <String, dynamic>{
      'mirror': '/srv/checkout/.sokar/mirror',
      'mode': 'gatekeeping',
      'seededFrom': '',
      'pending': <Map<String, dynamic>>[],
    });
  }

  @override
  Future<List<Log>> logsOf(String task) async => <Log>[
        for (final name in theLogsItHas)
          Log.from(<String, dynamic>{
            'name': name,
            'bytes': 2048,
            'at': '2026-09-07T14:12:00Z',
            if (whatTheLogsHold[name] != null) 'what': whatTheLogsHold[name],
          }),
      ];

  @override
  Stream<List<String>> tailLog(String task, String log) {
    tailing = StreamController<List<String>>();
    if (!theLogsItHas.contains(log)) {
      tailing.addError(
          const VarlinkException('org.fuin.sokar.Tasks1.NoSuchLog', <String, dynamic>{}));
      tailing.close();
    }
    return tailing.stream;
  }

  /// What the machine has on it right now.
  List<Task> get tasksNow => _tasks;

  /// Changes what is on the machine, as a backend does when something elsewhere moves.
  void publish(List<Task> tasks) {
    _tasks = tasks;
    _changes.add(tasks);
  }

  /// Stops answering, as a tunnel does.
  void lose() => _changes.addError(const VarlinkDisconnected('the tunnel went away'));

  /// Closes the change stream.
  Future<void> stop() async {
    await _changes.close();
    await asking.close();
  }
}

/// Records what would have been raised, so the rules can be judged without a notification daemon.
///
/// What is being tested is *when* something is said, what it says and what it stays quiet about.
/// The desktop's own machinery is not the requirement.
class RecordingNotifier implements Notifier {
  /// Everything raised, in order.
  final List<Announcement> raised = <Announcement>[];

  /// What acting on each one would do.
  final Map<String, VoidCallback> opening = <String, VoidCallback>{};

  @override
  String? problem;

  @override
  Future<void> raise(Announcement note, {required VoidCallback onOpened}) async {
    raised.add(note);
    opening[note.id] = onOpened;
  }

  /// Acts on the last one, as somebody clicking it would.
  void act() => opening[raised.last.id]?.call();
}

/// What one scenario's steps share.
class World {
  /// The backend under test.
  static late FakeBackend backend;

  /// What the window answered when it was asked to close, once it has.
  static Future<Object?>? closing;

  /// Where the appearance is remembered. It survives a restart within a scenario, which is what
  /// makes "still dark after a restart" a real check rather than a re-read of a field.
  static late MemorySettingsStore store;

  /// The interface's own preferences.
  static late Settings settings;

  /// Every machine being watched, and which one is being acted on.
  static late Machines machines;

  /// What is on the machine being acted on.
  static FleetModel get fleet => machines.fleet;

  /// Another machine, for the scenarios about reaching several.
  static late FakeBackend elsewhere;

  /// What is open and where the keyboard is.
  static late ShellModel shell;

  /// What this session has run.
  static late Operations operations;

  /// Where what was run is kept, so it survives a restart within a scenario.
  static late MemoryOperationsStore operationsStore;

  /// Every file the window asked the desktop to open.
  static final List<String> filesOpened = <String>[];

  /// What this session is reading.
  static late Logs logs;

  /// What is waiting at the gate.
  static late Gate gate;

  /// What the project being looked at may reach.
  static late Egress egress;

  /// What is being let through to work that is already running.
  static late Widening widening;

  /// What is being started.
  static late StartWork starting;

  /// Every forward the interface asked for, as it asked for it.
  ///
  /// Recorded rather than run. A widget test's clock does not carry process input and output —
  /// the same reason [FleetBackend] exists as a seam — so what the *frame* does is proven here
  /// and what `ssh` does is proven in `test/app/tunnel_test.dart`, against real sockets.
  static final List<List<String>> forwardsAsked = <List<String>>[];

  /// Forwards this interface still owns, by machine name.
  static final Set<String> forwardsHeld = <String>{};

  /// What the next forward does. A scenario sets it to make one fail the way `ssh` fails.
  static String? forwardsFailWith;

  /// Forwards raised for a trial and not yet taken down, by machine name.
  static final Set<String> trialForwards = <String>{};

  /// Every line the interface asked a machine to run, in order. Recorded, never run.
  static final List<List<String>> startsAsked = <List<String>>[];

  /// What a start does. A scenario sets it to make one come back the way a failure comes back.
  static String? startFailsWith;

  /// The uid a machine reports for the account logged in as, or null when it says nothing.
  static int? loginUid;

  /// What agents the machine has.
  static late AgentInventory inventory;

  /// The recurring jobs somebody named.
  static late Templates templates;

  /// Cutting every form of access at once.
  static late EmergencyStop stopping;

  /// What the protected store holds.
  static late Vault vault;

  /// Where this device keeps the keys that open a vault.
  static late MemoryDeviceKeyStore keys;

  /// What `known_hosts` holds, as the machine dialog sees it.
  static late FakeHostKeys hostKeys;

  /// Where a new machine's key goes, and what logging in to it as root answers.
  static late FakeMachineSetup setup;

  /// Whether a newer build has been installed underneath.
  static late NewerVersion newerVersion;

  /// The shells somebody has open inside running work.
  static late Sessions sessions;

  /// Removing what Sokar built for a project.
  static late ProjectDeletion deleting;

  /// Whether the machine being acted on can run anything.
  static late HostReadiness readiness;

  /// What the machine being acted on can authenticate against.
  static late Authentication authentication;

  /// Following a repository.
  static late ProjectFollowing following;

  /// What has been backed up of the project being looked at.
  static late Backups backups;

  /// Taking a name back from work that is already running.
  static late Narrowing narrowing;

  /// What the work being looked at holds that never reached the gate.
  static late WorkHeld held;

  /// Every terminal a scenario opened, in the order they were opened.
  ///
  /// **The command is what these hold on to.** A widget test cannot prove that a pty is really a
  /// terminal — `test/app/pty_test.dart` does that against the kernel — so what is proven here is
  /// everything above it: which command was run against which machine, that what comes back
  /// reaches the screen, and what an ending is said to mean.
  static final List<FakeTerminal> terminals = <FakeTerminal>[];

  /// Where somebody was, so a restart can put them back.
  static late WhereYouWere whereYouWere;

  /// What would have been said to somebody not looking at the window.
  static late RecordingNotifier notifier;

  /// The rules about when to say it.
  static late Notifications notifications;

  /// One machine with two projects on it, one of them with work stopped.
  static List<Task> get work => <Task>[
        // Running, unattended, and carrying its prompt: continuing it is refused because it is
        // still going, which is a different refusal from "it was never an unattended run".
        _task('sokar-checkout-shell', 'checkout',
            mode: 'UNATTENDED', prompt: 'Bring the schema up to date'),
        // A finished unattended run that kept what it was asked to do, which is what continuing
        // it with a new prompt reads back.
        // Its own ref is the one waiting at the gate, which `waiting` says on the task itself.
        // Nothing joins the two: this container's name is not that ref, and never was.
        _task('sokar-checkout-migrate', 'checkout',
            running: false,
            helpers: 0,
            mode: 'UNATTENDED',
            waiting: 1,
            prompt: 'Fix the rounding in Money.pennies and add a test for it'),
        _task('sokar-billing-shell', 'billing', securityClass: 'offline', helpers: 1),
        // Started with enforcement off: nothing will ever be asked about what it reaches.
        _task('sokar-billing-audit', 'billing', helpers: 0, clearance: 'off'),
      ];

  // Built from a wire-shaped map on purpose, so a fixture cannot describe a task the contract
  // could not actually deliver.
  static Task _task(
    String name,
    String project, {
    bool running = true,
    int helpers = 2,
    String securityClass = 'guarded',
    String clearance = 'prompt',
    String mode = '',
    String prompt = '',
    String agent = 'an-agent',
    int waiting = 0,
  }) =>
      Task.from(<String, dynamic>{
        'name': name,
        // The stand-in's own naming rule; the interface never derives this.
        'task': name.replaceFirst('sokar-$project-', ''),
        'project': project,
        'securityClass': securityClass,
        'state': running ? 'Up 4 minutes' : 'Exited (0) 12 minutes ago',
        'running': running,
        'helpers': helpers,
        'clearance': clearance,
        'mode': mode,
        'prompt': prompt,
        'waiting': waiting,
        'agent': agent,
      });

  /// One blocked connection, as the daemon raises it.
  ///
  /// Wire-shaped, and driven by the scenario rather than by a clock: this is the one event with a
  /// deadline, and a flaky test of it is a flaky test of the thing that matters most.
  static Prompt blocked(String destination,
      {String task = 'sokar-checkout-shell', String? deadline}) {
    final parts = destination.split(':');
    return Prompt.from(<String, dynamic>{
      'task': task,
      'key': 'tcp/$destination',
      'destination': parts.first,
      'protocol': 'tcp',
      'port': int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      'at': '2026-09-07T15:00:00Z',
      'prefix': 'egress/deny',
      'deadline': ?deadline,
    });
  }

  /// The same question a second time, carrying its answer.
  static Prompt settled(Prompt asked, String verdict) => Prompt.from(<String, dynamic>{
        'task': asked.task,
        'key': asked.key,
        'destination': asked.destination,
        'protocol': asked.protocol,
        'port': asked.port,
        // Two things this field means: the block time on the question, the decision time here.
        'at': '2026-09-07T15:04:00Z',
        // Empty on an answer: nothing decided it a second time.
        'prefix': '',
        'verdict': verdict,
      });

  /// Replaces one task with the same task in a different activity.
  ///
  /// Wire-shaped, so a fixture cannot describe a task the contract could not deliver.
  static void theWorkIs(
    String name, {
    required String activity,
    String waitingFor = '',
    String since = '',
    bool running = true,
  }) {
    final was = backend.tasksNow.firstWhere((task) => task.name == name);
    backend.publish(<Task>[
      for (final task in backend.tasksNow)
        if (task.name != name)
          task
        else
          Task.from(<String, dynamic>{
            'name': was.name,
            'task': was.task,
            'project': was.project,
            'securityClass': was.securityClass,
            'state': running ? 'Up 4 minutes' : 'Exited (0) 12 minutes ago',
            'running': running,
            'startAction': running ? 'RUNNING' : 'RESUME',
            'helpers': was.helpers,
            'agent': 'an-agent',
            'mode': 'UNATTENDED',
            'branch': 'refs/sokar/incoming/shell',
            'since': since,
            'activity': activity,
            'waitingFor': waitingFor,
            'repository': was.repository,
          }),
    ]);
  }

  /// Makes the machine say [action] is what Start would do to [name], and why.
  static void theStartWouldBe(String name, String action, {String detail = ''}) {
    backend.publish(<Task>[
      for (final task in backend.tasksNow)
        if (task.name != name)
          task
        else
          Task.from(<String, dynamic>{
            ...wire(task),
            'startAction': action,
            'startDetail': detail,
          }),
    ]);
  }

  /// Puts a backend behind the interface, and closes it when the scenario ends.
  static Future<void> startBackend(List<Task> tasks) async {
    backend = FakeBackend(tasks);
    addTearDown(backend.stop);
  }

  /// Builds the interface against that backend and connects it.
  ///
  /// At a desktop size, because that is what this is: the default 800x600 test surface is a
  /// narrow window, and every scenario would have been judging the fallback layout by accident.
  static Future<void> startApp(WidgetTester tester) async {
    // The view rather than the surface, at a pixel ratio of one: the surface is set in *physical*
    // pixels, so a default ratio quietly turns a desktop window into a narrow one and every
    // scenario judges the fallback layout without saying so.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    store = MemorySettingsStore();
    settings = Settings(store);
    shell = ShellModel();
    operationsStore = MemoryOperationsStore(file: File('/home/somebody/.local/state/sokar/operations.json'));
    filesOpened.clear();
    operations = _operationsFrom(operationsStore);
    logs = Logs();
    gate = Gate();
    egress = Egress();
    widening = Widening();
    starting = StartWork();
    inventory = AgentInventory();
    forwardsAsked.clear();
    forwardsHeld.clear();
    forwardsFailWith = null;
    trialForwards.clear();
    startsAsked.clear();
    startFailsWith = null;
    loginUid = null;
    templates = Templates(settings);
    await templates.load();
    stopping = EmergencyStop();
    vault = Vault(keys: keys = MemoryDeviceKeyStore());
    newerVersion = NewerVersion(what: File('/tmp/sokar-not-a-build'));
    terminals.clear();
    deleting = ProjectDeletion();
    addTearDown(deleting.dispose);
    readiness = HostReadiness();
    addTearDown(readiness.dispose);
    authentication = Authentication();
    addTearDown(authentication.dispose);
    following = ProjectFollowing();
    addTearDown(following.dispose);
    backups = Backups();
    addTearDown(backups.dispose);
    narrowing = Narrowing();
    addTearDown(narrowing.dispose);
    held = WorkHeld();
    addTearDown(held.dispose);
    sessions = Sessions(openTerminal: (executable, arguments, {int columns = 80, int rows = 24}) {
      final terminal = FakeTerminal(<String>[executable, ...arguments]);
      terminals.add(terminal);
      return terminal;
    });
    addTearDown(sessions.dispose);
    notifier = RecordingNotifier();
    notifications = Notifications(notifier, settings)
      ..watchOperations(operations, open: (operation) => shell.openOperation(operation.id));
    addTearDown(notifications.dispose);
    await notifications.load();
    elsewhere = FakeBackend(<Task>[_task('sokar-shared-shell', 'shared')])
      ..nodeId = 'node-b';
    addTearDown(elsewhere.stop);

    // One machine to begin with, and a second only when a scenario asks. Reaching several is
    // only the machine scenarios, and every scenario that does not care must not pay for it.
    hostKeys = FakeHostKeys();
    final setupHome = Directory.systemTemp.createTempSync('world-setup-');
    addTearDown(() => setupHome.deleteSync(recursive: true));
    setup = FakeMachineSetup(setupHome);
    machines = Machines(
      settings,
      reach: (machine) => machine.name == 'elsewhere' ? elsewhere : backend,
      tunnels: FakeTunnels(),
      hostKeys: hostKeys,
      setup: setup,
    );
    await machines.load();
    addTearDown(() => machines.dispose());
    // After the machines exist: it is about where somebody is, and nobody is anywhere yet.
    whereYouWere = WhereYouWere(settings, machines, shell);
    addTearDown(whereYouWere.dispose);
    addTearDown(operations.dispose);
    addTearDown(logs.dispose);

    // Clearance is per machine, so the hook goes on the one being acted on — a question knows its
    // task and the switch is per project, which only the fleet can resolve.
    notifications.watchClearance(
      fleet.clearance,
      projectOf: (task) => fleet.tasks
          .firstWhere((each) => each.name == task,
              orElse: () => Task.from(const <String, dynamic>{}))
          .project,
      open: (_) => shell.goTo(Section.attention),
    );

    await tester.pumpWidget(SokarApp(
      machines: machines,
      shell: shell,
      settings: settings,
      operations: operations,
      logs: logs,
      gate: gate,
      notifications: notifications,
      egress: egress,
      widening: widening,
      starting: starting,
      inventory: inventory,
      templates: templates,
      stopping: stopping,
      vault: vault,
      newerVersion: newerVersion,
      sessions: sessions,
      deleting: deleting,
      readiness: readiness,
      authentication: authentication,
      following: following,
      backups: backups,
      narrowing: narrowing,
      held: held,
    ));
    await tester.pumpAndSettle();
  }

  static Operations _operationsFrom(OperationsStore store) => Operations(
        store: store,
        open: (path) async => filesOpened.add(path),
        // Written at once: a timer still pending when a scenario ends fails it.
        saveDelay: Duration.zero,
      );

  /// Closes the window and opens it again, keeping what was stored.
  static Future<void> restartApp(WidgetTester tester) async {
    await operations.flush();
    operations = _operationsFrom(operationsStore);
    await operations.load();
    notifications.watchOperations(operations, open: (operation) => shell.openOperation(operation.id));
    final reopened = Settings(store);
    await reopened.load();
    settings = reopened;
    shell = ShellModel();

    // A real restart builds everything again, so a test that kept the models would be asserting
    // that nothing was lost rather than that anything was restored. Everything that survives
    // survives because it was written down.
    whereYouWere.dispose();
    machines.dispose();
    machines = Machines(
      settings,
      reach: (machine) => machine.name == 'elsewhere' ? elsewhere : backend,
      tunnels: FakeTunnels(),
      hostKeys: hostKeys,
    );
    await machines.load();
    whereYouWere = WhereYouWere(settings, machines, shell);
    await whereYouWere.restore();

    await tester.pumpWidget(const SizedBox.shrink());
    // Clearance is per machine, so the hook goes on the one being acted on — a question knows its
    // task and the switch is per project, which only the fleet can resolve.
    notifications.watchClearance(
      fleet.clearance,
      projectOf: (task) => fleet.tasks
          .firstWhere((each) => each.name == task,
              orElse: () => Task.from(const <String, dynamic>{}))
          .project,
      open: (_) => shell.goTo(Section.attention),
    );

    await tester.pumpWidget(SokarApp(
      machines: machines,
      shell: shell,
      settings: settings,
      operations: operations,
      logs: logs,
      gate: gate,
      notifications: notifications,
      egress: egress,
      widening: widening,
      starting: starting,
      inventory: inventory,
      templates: templates,
      stopping: stopping,
      vault: vault,
      newerVersion: newerVersion,
      sessions: sessions,
      deleting: deleting,
      readiness: readiness,
      authentication: authentication,
      following: following,
      backups: backups,
      narrowing: narrowing,
      held: held,
    ));
    await tester.pumpAndSettle();
  }

  /// Builds the interface again with whatever the scenario has just replaced.
  static Future<void> rebuild(WidgetTester tester) async {
    await tester.pumpWidget(SokarApp(
      machines: machines,
      shell: shell,
      settings: settings,
      operations: operations,
      logs: logs,
      gate: gate,
      notifications: notifications,
      egress: egress,
      widening: widening,
      starting: starting,
      inventory: inventory,
      templates: templates,
      stopping: stopping,
      vault: vault,
      newerVersion: newerVersion,
      sessions: sessions,
      deleting: deleting,
      readiness: readiness,
      authentication: authentication,
      following: following,
      backups: backups,
      narrowing: narrowing,
      held: held,
    ));
    await settle(tester);
  }

  /// Taps what [key] names in a dialog, scrolled into view first: a long answer pushes the
  /// buttons below the fold, and a tap there lands on nothing.
  static Future<void> tapInView(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pump();
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  /// Goes on to the machine wizard's second page when its first is still showing, so a step that
  /// fills in where a machine is works whichever page a scenario left open.
  static Future<void> onTheWizardsSecondPage(WidgetTester tester) async {
    final next = find.byKey(const Key('wizard-next'));
    if (next.evaluate().isEmpty) return;
    await tester.tap(next);
    await settle(tester);
  }

  /// Scrolls the last pane from its top until [target] is on screen. A pane's list builds only
  /// what is near the view, so a control scrolled away is not there to be found, let alone tapped.
  static Future<void> reach(WidgetTester tester, Finder target) async {
    final list = find.byType(Scrollable).last;
    final position = tester.state<ScrollableState>(list).position;
    position.jumpTo(position.minScrollExtent);
    await tester.pump();
    await tester.scrollUntilVisible(target, 100, scrollable: list);
    // Into the middle: at the very edge it can sit under the status line and a tap lands there.
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pump();
  }

  /// Redraws until things have stopped moving.
  ///
  /// Not [WidgetTester.pumpAndSettle]: an operation that is still running shows a spinner, and an
  /// animation with no end means pumpAndSettle never returns. Two frames, the second long enough
  /// to carry a dialog transition, is all any of this needs.
  static Future<void> settle(WidgetTester tester) async {
    // Three frames, not two: a theme change animates, and the frame that ends the animation is
    // not the frame that draws its result.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// Whatever has been put on the clipboard since [watchTheClipboard].
  static final List<String> copied = <String>[];

  /// Listens for anything copied, which crosses a platform channel rather than staying in Dart.
  static void watchTheClipboard(WidgetTester tester) {
    copied.clear();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map<Object?, Object?>)['text']! as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
  }

  /// The theme the interface is actually drawn with.
  static ThemeData themeInUse(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).first));
}

/// Forwards, recorded rather than raised.
///
/// The frame is judged on what it asks for, what it says, and what it lets go of. Starting a real
/// `ssh` here would make every scenario a test of somebody's network; the process itself has its
/// own tests against real sockets.
/// A terminal that never starts anything.
///
/// It is the seam [SessionChannel] exists for: what is above it — which command, against which
/// machine, what reaches the screen, and what an ending says — is the requirement, and none of it
/// needs a process.
class FakeTerminal implements SessionChannel {
  /// Constructor taking the command it stands in for.
  FakeTerminal(this.command);

  /// What would have been run.
  final List<String> command;

  /// What was typed into it, in order.
  final List<String> typed = <String>[];

  /// The sizes it was told about, most recent last.
  final List<String> sizes = <String>[];

  /// Whether this side closed it.
  bool closed = false;

  final StreamController<List<int>> _output = StreamController<List<int>>.broadcast();
  final Completer<int> _ended = Completer<int>();

  @override
  Stream<List<int>> get output => _output.stream;

  @override
  Future<int> get ended => _ended.future;

  @override
  void send(String input) => typed.add(input);

  @override
  void resize({required int columns, required int rows}) =>
      sizes.add('${columns}x$rows');

  @override
  Future<void> close() async {
    closed = true;
    if (!_ended.isCompleted) _ended.complete(129);
  }

  /// Makes the far end print something.
  void prints(String words) => _output.add(utf8.encode(words));

  /// Makes the far end go away with [code].
  void endsWith(int code) {
    if (!_ended.isCompleted) _ended.complete(code);
  }
}

/// A forward raised for a trial, which says when it is taken down.
class _TrialTunnel extends Tunnel {
  _TrialTunnel(super.machine);

  @override
  Future<void> drop() async {
    World.trialForwards.remove(machine.name);
    state = TunnelState.idle;
  }
}

/// Host keys as a person's `known_hosts` would have them: every host known, unless a scenario says
/// one is not.
class FakeHostKeys implements HostKeys {
  /// Destinations whose host key is not known yet.
  final Set<String> unknown = <String>{};

  /// What was written to `known_hosts`, by host.
  final List<String> written = <String>[];

  /// Every destination asked about.
  final List<String> asked = <String>[];

  /// Destinations for which another key than the one shown is known.
  final Set<String> changed = <String>{};

  /// The fingerprint every unknown host shows.
  static const fingerprint = '256 SHA256:uNiQuEfInGeRpRiNtOfThEbUiLdMaChInE0123456789 (ED25519)';

  @override
  Future<HostKeyCheck> check(String destination) async {
    asked.add(destination);
    final host = destination.split('@').last;
    if (!unknown.contains(destination)) {
      return HostKeyCheck(destination: destination, host: host, known: true);
    }
    return HostKeyCheck(
      destination: destination,
      host: host,
      known: false,
      changed: changed.contains(destination),
      knownIn: changed.contains(destination) ? const <String>['~/.ssh/known_hosts'] : const <String>[],
      scanned: const <String>['|1|hashed ssh-ed25519 AAAA'],
      fingerprints: const <String>[fingerprint],
    );
  }

  @override
  Future<void> accept(HostKeyCheck check) async {
    written.add(check.host);
    unknown.remove(check.destination);
  }
}

/// Preparing a new machine with the real `ssh-keygen`, into a home of its own, and a root login
/// that does what the scenario says.
class FakeMachineSetup extends MachineSetup {
  FakeMachineSetup(this.home) : super(home: home.path, run: _atOnce);

  /// The real programs, run synchronously: a widget test's clock never lets an asynchronous process
  /// come back, and a synchronous one needs no clock at all.
  static Future<ProcessResult> _atOnce(List<String> command, {String? input}) async =>
      Process.runSync(command.first, command.sublist(1));

  /// The home whose `~/.ssh` the keys go to.
  final Directory home;

  /// What logging in as root answers, or null for a login that works.
  String? rootLoginFails;

  /// Every root login tried: the host, and the key it used.
  final List<({String host, String key})> rootLogins = <({String host, String key})>[];

  @override
  Future<String?> loginAsRoot(String host, String keyFile) async {
    rootLogins.add((host: host, key: keyFile));
    return rootLoginFails;
  }

  /// Every script run as root, in order.
  final List<String> asRootRan = <String>[];

  /// What allowing the key for the work user says when it fails, or null when it works.
  String? allowFails;

  /// How the setup script's `--show` ends, and how running it ends.
  int showEnds = 0;
  int prepareEnds = 0;

  /// What the setup script's `--list --json` prints.
  String lists = '{"packages": ['
      '{"name": "sokar-agent-claude", "kind": "agent", "description": "Claude Code", '
      '"installed": false, "version": "1.0.0~snapshot.12"}, '
      '{"name": "sokar-agent-omp", "kind": "agent", "description": "oh-my-pi", '
      '"installed": false, "version": ""}, '
      '{"name": "sokar-message-transport-local", "kind": "transport", '
      '"description": "Local transport", "installed": true, "version": "1.0.0"}]}';

  /// What the setup script's `--show` prints.
  String shows = "useradd --create-home agent\napt-get install -y sokar\nloginctl enable-linger agent";

  @override
  Future<ProcessResult> asRoot(String host, String keyFile, String script) async {
    asRootRan.add(script);
    if (script.contains('--list --json')) {
      if (showEnds == 3) {
        return ProcessResult(0, 3, '', 'This is Arch Linux, which this script does not know.');
      }
      return ProcessResult(0, 0, lists, lists.contains('[]') ? 'nothing yet - no package declares it' : '');
    }
    if (script.contains('--show')) {
      return ProcessResult(0, showEnds, showEnds == 3 ? '' : shows,
          showEnds == 3 ? 'This is Arch Linux, which this script does not know.' : '');
    }
    if (script.startsWith('bash /root/sokar-setup.sh --user')) {
      return ProcessResult(0, prepareEnds, 'agents exists\nsokar installed', '');
    }
    if (script.contains('authorized_keys') && allowFails != null) {
      return ProcessResult(0, 1, '', allowFails!);
    }
    return ProcessResult(0, 0, '', '');
  }

  @override
  Future<ProcessResult> asRootLive(
    String host,
    String keyFile,
    String script,
    void Function(String line) onLine,
  ) async {
    final hold = holdRoot;
    if (hold != null) {
      onLine('Reading package lists...');
      await hold.future;
    }
    final result = await asRoot(host, keyFile, script);
    for (final line in '${result.stdout}'.split('\n')) {
      if (line.isNotEmpty) onLine(line);
    }
    return result;
  }

  /// Set to keep a root script running until it is completed.
  Completer<void>? holdRoot;

  /// What `sokar setup` says when it fails, or null when it works.
  String? registeringFails;

  /// Every command run as the work user.
  final List<String> asUserRan = <String>[];

  @override
  Future<ProcessResult> asUser(String alias, String command) async {
    asUserRan.add(command);
    return switch (command) {
      'sokar setup' when registeringFails != null => ProcessResult(0, 1, '', registeringFails!),
      'id -u' => ProcessResult(0, 0, '1001\n', ''),
      'sokar doctor' => ProcessResult(0, 0, 'ready', ''),
      _ => ProcessResult(0, 0, '', ''),
    };
  }
}

class FakeTunnels extends Tunnels {
  final Map<String, Tunnel> _mine = <String, Tunnel>{};

  @override
  Tunnel? of(Machine machine) => _mine[machine.name];

  @override
  bool manages(Machine machine) => _mine.containsKey(machine.name);

  @override
  Future<bool> raiseFor(Machine machine) async {
    // A machine somebody else forwarded is left alone: nothing started, nothing owned.
    if (!machine.needsATunnel) return true;
    final tunnel = _mine.putIfAbsent(machine.name, () => Tunnel(machine));
    World.forwardsAsked.add(tunnel.command);
    World.forwardsHeld.add(machine.name);
    final failing = World.forwardsFailWith;
    if (failing != null) {
      tunnel
        ..state = TunnelState.down
        ..problem = failing;
      notifyListeners();
      return false;
    }
    tunnel
      ..state = TunnelState.up
      ..problem = null;
    notifyListeners();
    return true;
  }

  @override
  Future<int?> loginUidOn(Machine machine) async =>
      machine.needsATunnel ? World.loginUid : null;

  @override
  Future<Started> startSokarOn(Machine machine) async {
    // A machine with no host behind it is refused before anything is run, by the real thing.
    if (!machine.needsATunnel) return super.startSokarOn(machine);
    World.startsAsked.add(Tunnels.startCommandFor(machine));
    final failing = World.startFailsWith;
    if (failing != null) return Started(went: false, words: failing);
    // The daemon that was missing is there now, so the try that follows finds it.
    World.backend.absent = null;
    return const Started(went: true, words: 'started sokard itself');
  }

  @override
  Future<Tunnel> trial(Machine machine) async {
    final tunnel = _TrialTunnel(machine);
    World.forwardsAsked.add(tunnel.command);
    World.trialForwards.add(machine.name);
    final failing = World.forwardsFailWith;
    tunnel
      ..state = failing == null ? TunnelState.up : TunnelState.down
      ..problem = failing;
    return tunnel;
  }

  @override
  Future<void> raiseAgainIfItDropped(Machine machine) async {
    if (_mine[machine.name]?.state != TunnelState.down) return;
    await raiseFor(machine);
  }

  @override
  Future<void> dropFor(Machine machine) async {
    if (_mine.remove(machine.name) != null) World.forwardsHeld.remove(machine.name);
    notifyListeners();
  }

  @override
  Future<void> dropEverything() async {
    for (final name in _mine.keys) {
      World.forwardsHeld.remove(name);
    }
    _mine.clear();
    notifyListeners();
  }
}

/// [task] as the machine would send it.
Map<String, dynamic> wire(Task task) => <String, dynamic>{
      'name': task.name,
      'task': task.task,
      'label': task.label,
      'project': task.project,
      'securityClass': task.securityClass,
      'state': task.state,
      'running': task.running,
      'helpers': task.helpers,
      'agent': task.agent,
      'mode': task.mode.name,
      'prompt': task.prompt,
      'branch': task.branch,
      'since': task.since,
      'activity': task.activity.name,
      'waitingFor': task.waitingFor,
      'clearance': task.clearance,
      'waiting': task.waiting,
      'startAction': task.startAction.name,
      'startDetail': task.startDetail,
      'phase': task.phase,
      'repository': task.repository,
    };
