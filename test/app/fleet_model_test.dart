import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/fleet_backend.dart';
import 'package:sokar_frontend/src/app/fleet_model.dart';

/// A backend that is reachable and useless: the socket opens and nothing is ever answered.
class _Wedged implements FleetBackend {
  @override
  String get label => 'the mock';

  @override
  Future<ServiceInfo> open() async =>
      throw const VarlinkDisconnected('GetInfo was not answered within 5 seconds');

  @override
  Future<List<Task>> tasks() async => const <Task>[];

  @override
  Future<List<Project>> projects() async => const <Project>[];

  @override
  Stream<List<Task>> watch() => const Stream<List<Task>>.empty();

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
  }) =>
      const Stream<String>.empty();

  @override
  Future<Stopped> stopTask(String task) async =>
      throw const VarlinkDisconnected('nothing there');

  @override
  Future<Removed> removeTask(String task, {bool? rescue, bool? force}) async =>
      throw const VarlinkDisconnected('nothing there');

  @override
  Future<StartProgress> startAgain({required String project, required String task}) async =>
      throw const VarlinkDisconnected('nothing there');

  @override
  Future<List<Log>> logsOf(String task) async => const <Log>[];

  @override
  Future<GateState> gateOf(String projectFile) async =>
      GateState.from(const <String, dynamic>{});

  @override
  Future<({String diff, String log})> reviewOf(
    String projectFile,
    String name, {
    String? against,
  }) async =>
      (diff: '', log: '');

  @override
  Future<void> approve(String projectFile, String name, String branch) async {}

  @override
  Future<void> reject(String projectFile, String name) async {}

  @override
  Future<(List<EgressHost>, List<String>)> egressOf(String projectFile) async =>
      (const <EgressHost>[], const <String>[]);

  @override
  Future<(List<EgressSet>, List<String>)> egressSets() async =>
      (const <EgressSet>[], const <String>[]);

  @override
  Future<EgressChange> changeEgress(
    String projectFile, {
    List<String>? addSets,
    List<String>? removeSets,
    List<String>? addDomains,
    List<String>? removeDomains,
    bool? dryRun,
  }) async =>
      EgressChange.from(const <String, dynamic>{});


  @override
  Stream<Prompt> prompts() => const Stream<Prompt>.empty();

  @override
  Future<void> decide(Prompt prompt, {required bool allow}) async {}



  @override
  Stream<List<String>> tailLog(String task, String log) =>
      const Stream<List<String>>.empty();
  @override
  Future<Widened> widenTask(
    String task,
    List<String> domains, {
    required Scope scope,
    bool? dryRun,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AgentsOnTheMachine> agentsOn() async => (
        agents: const <Agent>[],
        failures: const <String, String>{},
        shadowed: const <ShadowedAgent>[],
      );

  @override
  Future<Panicked> panic({bool? dryRun}) async =>
      const Panicked(tasks: <PanickedTask>[], surviving: <String>[], previewed: false);

  @override
  Future<String> node() async => '';

  @override
  Stream<PrepareProgress> prepare(String project,
          {String? agent, String? rebuild, bool? dryRun}) =>
      const Stream<PrepareProgress>.empty();

  @override
  Future<ClearanceSet> setClearance(String task, String mode, {bool? dryRun}) async =>
      const ClearanceSet(outcome: 'CHANGED', was: 'prompt', now: 'off', detail: '');

  @override
  Future<Narrowed> narrowTask(String task, List<String> domains,
          {required Scope scope, bool? dryRun}) async =>
      const Narrowed(
          outcome: WidenOutcome.widened,
          closes: <String>[],
          addresses: 0,
          persisted: false,
          detail: '');

  @override
  Future<HeldWork> workHeld(String task) async =>
      const HeldWork(readable: true, changedFiles: 0, unpushedCommits: 0);

  @override
  Future<Synced> syncUpstream(String project) async => const Synced(
      outcome: 'MEASURED', behind: 0, measured: true, reason: 'MEASURED', detail: '');

  @override
  Future<Restored> restoreBackup(String project, String bundle,
          {bool? dryRun, bool? force}) async =>
      const Restored(
          outcome: 'RESTORED', mirror: '', unreviewed: <String>[], detail: '');

  @override
  Future<List<Backup>> backups(String project) async => const <Backup>[];

  @override
  Future<BackupDeleted> deleteBackup(String project, String bundle, {bool? dryRun}) async =>
      const BackupDeleted(outcome: 'DELETED', fileRemoved: true, refs: 0, detail: '');

  @override
  Future<Created> createProject({
    required String file,
    required String name,
    required String securityClass,
    required String baseImage,
    String? upstream,
    List<String> sets = const <String>[],
    bool? dryRun,
  }) async =>
      const Created(
          outcome: 'CREATED',
          file: '',
          content: '',
          problems: <Problem>[],
          detail: '');

  @override
  Future<Health> doctor() async =>
      const Health(probes: <Probe>[], ready: true);

  @override
  Future<Providers> providers() async =>
      const Providers(providers: <Provider>[], readable: true);

  @override
  Future<Imported> importCredential({String? agent, String? configDirectory}) async =>
      const Imported(
          outcome: 'IMPORTED', name: '', type: '', length: 0, source: '', detail: '');

  @override
  Future<Deletion> deleteProject(String project, {bool? dryRun, bool? force}) async =>
      const Deletion(
          outcome: DeleteOutcome.deleted,
          removes: <Removal>[],
          keeps: <String>[],
          unreviewed: <String>[],
          running: <String>[],
          detail: '');

  @override
  Future<Readiness> canStart({String? project, String? agent}) async => const Readiness(
        ready: true,
        outcome: StartOutcome.ready,
        agent: '',
        provider: '',
        credential: '',
        detail: '',
      );

  @override
  Future<VaultState> credentials() async => VaultState.from(const <String, dynamic>{});

  @override
  Future<Locked> lock() async =>
      const Locked(keyring: true, wasCached: false, holding: 0);

  @override
  Future<Labelled> labelTask(String task, {String? label}) async =>
      const Labelled(outcome: 'LABELLED', label: '');

}

/// A machine that lists one project nothing has ever run on, and one task belonging to a project
/// it does not list at all.
class _Machine implements FleetBackend {
  @override
  String get label => 'the mock';

  @override
  Future<ServiceInfo> open() async => const ServiceInfo(
      product: 'Sokar', version: '0', vendor: 'fuin.org', interfaces: <String>[]);

  @override
  Future<List<Task>> tasks() async => <Task>[
        Task.from(const <String, dynamic>{'name': 'sokar-orphan', 'project': 'vanished'}),
      ];

  @override
  Future<List<Project>> projects() async => <Project>[
        Project.from(const <String, dynamic>{'name': 'never-run', 'tasks': 0}),
        // Counts that do not match what List returned, on purpose: the daemon assembles them from
        // the mirrors and the tasks that exist, and knows about work this end has not matched.
        Project.from(const <String, dynamic>{
          'name': 'busy',
          'tasks': 7,
          'running': 3,
        }),
      ];

  @override
  Stream<List<Task>> watch() => const Stream<List<Task>>.empty();

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
  }) =>
      const Stream<String>.empty();

  @override
  Future<Stopped> stopTask(String task) async => throw UnimplementedError();

  @override
  Future<Removed> removeTask(String task, {bool? rescue, bool? force}) async =>
      throw UnimplementedError();

  @override
  Future<StartProgress> startAgain({required String project, required String task}) async =>
      throw UnimplementedError();

  @override
  Future<List<Log>> logsOf(String task) async => const <Log>[];

  @override
  Future<GateState> gateOf(String projectFile) async =>
      GateState.from(const <String, dynamic>{});

  @override
  Future<({String diff, String log})> reviewOf(
    String projectFile,
    String name, {
    String? against,
  }) async =>
      (diff: '', log: '');

  @override
  Future<void> approve(String projectFile, String name, String branch) async {}

  @override
  Future<void> reject(String projectFile, String name) async {}

  @override
  Stream<Prompt> prompts() => const Stream<Prompt>.empty();

  @override
  Future<void> decide(Prompt prompt, {required bool allow}) async {}
  @override
  Future<(List<EgressHost>, List<String>)> egressOf(String projectFile) async =>
      (const <EgressHost>[], const <String>[]);

  @override
  Future<(List<EgressSet>, List<String>)> egressSets() async =>
      (const <EgressSet>[], const <String>[]);

  @override
  Future<EgressChange> changeEgress(
    String projectFile, {
    List<String>? addSets,
    List<String>? removeSets,
    List<String>? addDomains,
    List<String>? removeDomains,
    bool? dryRun,
  }) async =>
      EgressChange.from(const <String, dynamic>{});




  @override
  Stream<List<String>> tailLog(String task, String log) =>
      const Stream<List<String>>.empty();
  @override
  Future<Widened> widenTask(
    String task,
    List<String> domains, {
    required Scope scope,
    bool? dryRun,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AgentsOnTheMachine> agentsOn() async => (
        agents: const <Agent>[],
        failures: const <String, String>{},
        shadowed: const <ShadowedAgent>[],
      );

  @override
  Future<Panicked> panic({bool? dryRun}) async =>
      const Panicked(tasks: <PanickedTask>[], surviving: <String>[], previewed: false);

  @override
  Future<String> node() async => '';

  @override
  Stream<PrepareProgress> prepare(String project,
          {String? agent, String? rebuild, bool? dryRun}) =>
      const Stream<PrepareProgress>.empty();

  @override
  Future<ClearanceSet> setClearance(String task, String mode, {bool? dryRun}) async =>
      const ClearanceSet(outcome: 'CHANGED', was: 'prompt', now: 'off', detail: '');

  @override
  Future<Narrowed> narrowTask(String task, List<String> domains,
          {required Scope scope, bool? dryRun}) async =>
      const Narrowed(
          outcome: WidenOutcome.widened,
          closes: <String>[],
          addresses: 0,
          persisted: false,
          detail: '');

  @override
  Future<HeldWork> workHeld(String task) async =>
      const HeldWork(readable: true, changedFiles: 0, unpushedCommits: 0);

  @override
  Future<Synced> syncUpstream(String project) async => const Synced(
      outcome: 'MEASURED', behind: 0, measured: true, reason: 'MEASURED', detail: '');

  @override
  Future<Restored> restoreBackup(String project, String bundle,
          {bool? dryRun, bool? force}) async =>
      const Restored(
          outcome: 'RESTORED', mirror: '', unreviewed: <String>[], detail: '');

  @override
  Future<List<Backup>> backups(String project) async => const <Backup>[];

  @override
  Future<BackupDeleted> deleteBackup(String project, String bundle, {bool? dryRun}) async =>
      const BackupDeleted(outcome: 'DELETED', fileRemoved: true, refs: 0, detail: '');

  @override
  Future<Created> createProject({
    required String file,
    required String name,
    required String securityClass,
    required String baseImage,
    String? upstream,
    List<String> sets = const <String>[],
    bool? dryRun,
  }) async =>
      const Created(
          outcome: 'CREATED',
          file: '',
          content: '',
          problems: <Problem>[],
          detail: '');

  @override
  Future<Health> doctor() async =>
      const Health(probes: <Probe>[], ready: true);

  @override
  Future<Providers> providers() async =>
      const Providers(providers: <Provider>[], readable: true);

  @override
  Future<Imported> importCredential({String? agent, String? configDirectory}) async =>
      const Imported(
          outcome: 'IMPORTED', name: '', type: '', length: 0, source: '', detail: '');

  @override
  Future<Deletion> deleteProject(String project, {bool? dryRun, bool? force}) async =>
      const Deletion(
          outcome: DeleteOutcome.deleted,
          removes: <Removal>[],
          keeps: <String>[],
          unreviewed: <String>[],
          running: <String>[],
          detail: '');

  @override
  Future<Readiness> canStart({String? project, String? agent}) async => const Readiness(
        ready: true,
        outcome: StartOutcome.ready,
        agent: '',
        provider: '',
        credential: '',
        detail: '',
      );

  @override
  Future<VaultState> credentials() async => VaultState.from(const <String, dynamic>{});

  @override
  Future<Locked> lock() async =>
      const Locked(keyring: true, wasCached: false, holding: 0);

  @override
  Future<Labelled> labelTask(String task, {String? label}) async =>
      const Labelled(outcome: 'LABELLED', label: '');

}

/// A backend that answers nothing, for a test that must not reach one.
final aBackendThatRefusesEverything = _Machine();

void main() {
  test('a backend that never answers reads as not connected, and says why', () async {
    // Otherwise the frame sits on "asking the backend what is here" for ever, which is the one
    // state a person can neither act on nor understand.
    final fleet = FleetModel(_Wedged());

    await fleet.connect();

    expect(fleet.reachability, Reachability.unreachable);
    expect(fleet.status, contains('not answered'));
    fleet.dispose();
  });

  test('a project that has never run anything is listed, and so is orphaned work', () async {
    // Two things a derived list gets wrong in opposite directions: it cannot show a project with
    // no tasks at all, and it would silently drop work whose project the daemon no longer lists.
    final fleet = FleetModel(_Machine());

    await fleet.connect();

    expect(fleet.projects.map((project) => project.name),
        containsAll(<String>['never-run', 'vanished']));
    final vanished =
        fleet.projects.firstWhere((project) => project.name == 'vanished');
    expect(vanished.tasks, hasLength(1));
    expect(vanished.canBeActedOn, isFalse);
    fleet.dispose();
  });

  test('how much work a project has is the daemon count, not one made up here', () async {
    // Projects lists every project, not only the busy ones, and gives both numbers rather than
    // leaving one to be inferred. Counting the tasks this end happened to match would report
    // nothing for a project whose work it could not pair up.
    final fleet = FleetModel(_Machine());

    await fleet.connect();

    final busy = fleet.projects.firstWhere((project) => project.name == 'busy');
    expect(busy.howMuchWork, 7);
    expect(busy.running, 3);
    expect(busy.tasks, isEmpty);
    fleet.dispose();
  });
}
