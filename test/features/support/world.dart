import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/fleet_backend.dart';
import 'package:sokar_frontend/src/app/fleet_model.dart';
import 'package:sokar_frontend/src/app/egress.dart';
import 'package:sokar_frontend/src/app/agent_inventory.dart';
import 'package:sokar_frontend/src/app/emergency_stop.dart';
import 'package:sokar_frontend/src/app/start_work.dart';
import 'package:sokar_frontend/src/app/templates.dart';
import 'package:sokar_frontend/src/app/project_deletion.dart';
import 'package:sokar_frontend/src/app/pty.dart';
import 'package:sokar_frontend/src/app/session.dart';
import 'package:sokar_frontend/src/app/vault.dart';
import 'package:sokar_frontend/src/app/tunnel.dart';
import 'package:sokar_frontend/src/app/widening.dart';
import 'package:sokar_frontend/src/app/gate.dart';
import 'package:sokar_frontend/src/app/authentication.dart';
import 'package:sokar_frontend/src/app/backups.dart';
import 'package:sokar_frontend/src/app/host_readiness.dart';
import 'package:sokar_frontend/src/app/logs.dart';
import 'package:sokar_frontend/src/app/machines.dart';
import 'package:sokar_frontend/src/app/narrowing.dart';
import 'package:sokar_frontend/src/app/project_creation.dart';
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
  /// of F08 — a screen that offered one and sent another would be wrong invisibly.
  final List<({String? task, String? project, String? agent, Mode? mode, String? prompt})>
      starts =
      <({String? task, String? project, String? agent, Mode? mode, String? prompt})>[];

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
  }) {
    launched.add(dryRun);
    starts.add((task: task, project: project, agent: agent, mode: mode, prompt: prompt));
    launch = StreamController<String>();
    return launch.stream;
  }

  /// What the next [stopTask] answers. Set by the scenario, so a refusal can be produced without
  /// contriving a task that genuinely holds commits.
  Stopped nextStop = Stopped.from(const <String, dynamic>{
    'outcome': 'STOPPED',
    'work': '',
    'rescuedRef': '',
    'removed': true,
    'helpers': 0,
    'surviving': 0,
    'detail': '',
    'discarded': 128,
  });

  /// What the next [resumeTask] answers.
  Resumed nextResume = Resumed.from(const <String, dynamic>{
    'outcome': 'RESUMED',
    'started': 2,
    'recorded': 2,
    'imageDrift': '',
    'problems': <String>[],
  });

  /// Every stop asked for, and how it was asked.
  final List<({String task, bool? purge, bool? rescue, bool? force})> stops =
      <({String task, bool? purge, bool? rescue, bool? force})>[];

  /// Acts on the machine, rather than only answering about it.
  ///
  /// A stand-in that says a task was removed and goes on listing it makes a working interface
  /// look like one where nothing happens. That was found by hand, against the other stand-in,
  /// with every test green — so both of them act now, and a scenario holds this one to it.
  @override
  Future<Stopped> stopTask(
    String task, {
    bool? purge,
    bool? rescue,
    bool? force,
  }) async {
    stops.add((task: task, purge: purge, rescue: rescue, force: force));
    if (nextStop.removed) {
      _tasks = _tasks.where((each) => each.name != task).toList();
      _changes.add(_tasks);
    }
    return nextStop;
  }

  @override
  Future<Resumed> resumeTask(String task) async => nextResume;

  /// What the next [tailLog] prints into, so the scenario decides when a line arrives.
  late StreamController<List<String>> tailing;

  /// Logs this machine has. What `Logs` answers, and what `Tail` accepts.
  Set<String> theLogsItHas = <String>{'agent.log'};

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
    return nextLock;
  }

  /// What the next [canStart] answers. A scenario sets it to produce a locked vault or a missing
  /// credential, neither of which a contrived agent list can produce.
  Readiness? nextReadiness;

  @override
  Future<Readiness> canStart({String? project, String? agent}) async =>
      nextReadiness ??
      const Readiness(
        ready: true,
        outcome: StartOutcome.ready,
        agent: 'an-agent',
        provider: 'a-provider',
        credential: 'a-provider',
        detail: '',
      );

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
  Future<List<Backup>> backups(String project) async => theBackupsItHas;

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

  /// Every creation asked for.
  final List<({String file, String name, String securityClass, bool preview})> creations =
      <({String file, String name, String securityClass, bool preview})>[];

  @override
  Future<Created> createProject({
    required String file,
    required String name,
    required String securityClass,
    required String baseImage,
    String? upstream,
    List<String> sets = const <String>[],
    bool? dryRun,
  }) async {
    creations.add((
      file: file,
      name: name,
      securityClass: securityClass,
      preview: dryRun == true,
    ));
    final blocked = theCreationProblems.any((problem) => problem.fatal);
    return Created(
      outcome: blocked
          ? 'INVALID'
          : dryRun == true
              ? 'PREVIEWED'
              : theCreationAnswers,
      file: file,
      content: 'project:\n  name: "$name"\n  security_class: "$securityClass"\n'
          'image:\n  base_image: "$baseImage"\n',
      problems: theCreationProblems,
      detail: theCreationAnswers == 'ALREADY_EXISTS'
          ? 'a project file is already there'
          : '',
    );
  }

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
    source: '/home/michi/.config/an-agent/credentials.json',
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

  @override
  Future<Deletion> deleteProject(String project, {bool? dryRun, bool? force}) async {
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

  /// What was approved, and onto which branch.
  final List<({String name, String branch})> approvals =
      <({String name, String branch})>[];

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
  Future<(List<EgressHost>, List<String>)> egressOf(String projectFile) async =>
      (theHostsItMayReach, theHostsItIsRefused);

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
  }) async {
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
  Future<GateState> gateOf(String projectFile) async {
    final refusal = refuseTheGate;
    if (refusal != null) throw refusal;
    return theGate;
  }

  @override
  Future<({String diff, String log})> reviewOf(
    String projectFile,
    String name, {
    String? against,
  }) async =>
      (diff: theDiff, log: 'commit 9a3c1f2\n\n    Round to the nearest penny');

  @override
  Future<void> approve(String projectFile, String name, String branch) async {
    final refusal = refuseTheGate;
    if (refusal != null) throw refusal;
    approvals.add((name: name, branch: branch));
    theGate = GateState.from(const <String, dynamic>{
      'mirror': '/srv/checkout/.sokar/mirror',
      'mode': 'gatekeeping',
      'seededFrom': '',
      'pending': <Map<String, dynamic>>[],
    });
  }

  @override
  Future<void> reject(String projectFile, String name) async {
    rejections.add(name);
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

  /// What agents the machine has.
  static late AgentInventory inventory;

  /// The recurring jobs somebody named.
  static late Templates templates;

  /// Cutting every form of access at once.
  static late EmergencyStop stopping;

  /// What the protected store holds.
  static late Vault vault;

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

  /// Describing and creating a project.
  static late ProjectCreation creating;

  /// What has been backed up of the project being looked at.
  static late Backups backups;

  /// Taking a name back from work that is already running.
  static late Narrowing narrowing;

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
  static Prompt blocked(String destination, {String task = 'sokar-checkout-shell'}) {
    final parts = destination.split(':');
    return Prompt.from(<String, dynamic>{
      'task': task,
      'key': 'tcp/$destination',
      'destination': parts.first,
      'protocol': 'tcp',
      'port': int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      'at': '2026-09-07T15:00:00Z',
      'prefix': 'egress/deny',
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
            'project': was.project,
            'securityClass': was.securityClass,
            'state': running ? 'Up 4 minutes' : 'Exited (0) 12 minutes ago',
            'running': running,
            'helpers': was.helpers,
            'agent': 'an-agent',
            'mode': 'UNATTENDED',
            'branch': 'refs/sokar/incoming/shell',
            'since': since,
            'activity': activity,
            'waitingFor': waitingFor,
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
    operations = Operations();
    logs = Logs();
    gate = Gate();
    egress = Egress();
    widening = Widening();
    starting = StartWork();
    inventory = AgentInventory();
    forwardsAsked.clear();
    forwardsHeld.clear();
    forwardsFailWith = null;
    templates = Templates(settings);
    await templates.load();
    stopping = EmergencyStop();
    vault = Vault();
    newerVersion = NewerVersion(what: File('/tmp/sokar-not-a-build'));
    terminals.clear();
    deleting = ProjectDeletion();
    addTearDown(deleting.dispose);
    readiness = HostReadiness();
    addTearDown(readiness.dispose);
    authentication = Authentication();
    addTearDown(authentication.dispose);
    creating = ProjectCreation();
    addTearDown(creating.dispose);
    backups = Backups();
    addTearDown(backups.dispose);
    narrowing = Narrowing();
    addTearDown(narrowing.dispose);
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
    // F20, and every scenario that does not care must not pay for it.
    machines = Machines(
      settings,
      reach: (machine) => machine.name == 'elsewhere' ? elsewhere : backend,
      tunnels: FakeTunnels(),
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
      open: (_) => shell.goTo(Section.clearance),
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
      creating: creating,
      backups: backups,
      narrowing: narrowing,
    ));
    await tester.pumpAndSettle();
  }

  /// Closes the window and opens it again, keeping what was stored.
  static Future<void> restartApp(WidgetTester tester) async {
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
      open: (_) => shell.goTo(Section.clearance),
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
      creating: creating,
      backups: backups,
      narrowing: narrowing,
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
      creating: creating,
      backups: backups,
      narrowing: narrowing,
    ));
    await settle(tester);
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

