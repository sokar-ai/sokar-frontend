import 'dart:io';

import '../wire/varlink_connection.dart';
import '../wire/varlink_exception.dart';
import 'models.dart';

/// Where a backend is.
///
/// Local and remote differ by one string - the socket path - because a remote daemon is reached
/// by forwarding its socket over SSH. **There is no second transport, and there must never be
/// one**; anything that looks like it needs one is a design that has gone wrong.
class Backend {
  /// Path to the daemon's unix socket.
  final String socketPath;

  /// What to call this backend in the interface. Several may be reachable at once, and an action
  /// must never be ambiguous about which machine it acts on.
  final String label;

  /// Constructor with the socket and how to name it.
  const Backend({required this.socketPath, required this.label});

  /// The daemon on this machine.
  factory Backend.local() {
    final runtime = Platform.environment['XDG_RUNTIME_DIR'] ?? '/run/user/${_uid()}';
    return Backend(socketPath: '$runtime/sokar/sokard.sock', label: 'this machine');
  }

  static String _uid() => Process.runSync('id', const ['-u']).stdout.toString().trim();
}

/// A feature this build has that the backend it is talking to does not.
///
/// Thrown instead of a raw error so a caller cannot mistake it for a failure: the interface
/// disables that one feature and keeps everything else. A backend is routinely older than the
/// interface pointed at it, and refusing to connect over one missing method would make a fleet
/// unusable during any upgrade.
class FeatureNotSupported implements Exception {
  /// The method the backend does not have.
  final String method;

  /// Constructor with the missing method.
  const FeatureNotSupported(this.method);

  @override
  String toString() => 'this backend has no $method';
}

/// The Sokar backend, typed.
///
/// One [Backend] per instance. Every call opens its own connection, because the framing has no
/// request ids and a connection therefore carries one call at a time - which costs nothing and
/// means a stream can be canceled without disturbing anything else.
class SokarClient {
  /// Interface versions this build understands, newest first.
  ///
  /// The trailing number is the compatibility promise. A backend serving a newer one also serves
  /// this one for at least a release, so taking the newest *understood* name - rather than the
  /// newest offered, and never a version comparison - is what keeps an old interface working
  /// against a new backend and the other way round.
  static const supported = <String>['org.fuin.sokar.Tasks1'];

  /// Where this is pointed.
  final Backend backend;

  /// Which interface was agreed with this backend.
  final String interfaceName;

  /// What the backend says it is.
  final ServiceInfo info;

  SokarClient._(this.backend, this.interfaceName, this.info);

  /// Connects and agrees an interface.
  ///
  /// Throws [VarlinkDisconnected] when there is nothing there, and [StateError] when the backend
  /// serves no interface this build knows - which is a backend too new or too old to talk to at
  /// all, and is worth saying plainly rather than failing on the first call.
  static Future<SokarClient> connect(Backend backend) async {
    final connection = await VarlinkConnection.open(backend.socketPath);
    try {
      // Shorter than the default: "is there a daemon on the other end of this socket" has to
      // answer quickly, or the window sits on an empty frame saying it is connecting.
      final info = ServiceInfo.from(await connection.call(
          'org.varlink.service.GetInfo', const {}, const Duration(seconds: 5)));
      final agreed = supported.where(info.interfaces.contains);
      if (agreed.isEmpty) {
        throw StateError(
            '${backend.label} serves ${info.interfaces}, none of which this build understands '
            '(it knows $supported)');
      }
      return SokarClient._(backend, agreed.first, info);
    } finally {
      await connection.close();
    }
  }

  /// The contract, read off this running backend.
  ///
  /// Served by the daemon itself, so it always matches what is answering - unlike a copy.
  Future<String> contract() async {
    final reply = await _call('org.varlink.service.GetInterfaceDescription',
        {'interface': interfaceName}, false);
    final description = reply['description'];
    return description is String ? description : '';
  }

  // --------------------------------------------------------------------- what exists

  /// Every task on the machine, running or stopped.
  Future<List<Task>> tasks() async =>
      _tasksOf(await _call('List'));

  /// The task list, again whenever it changes.
  ///
  /// Only on change, and the age in [Task.state] does not count as one - it moves on its own, and
  /// a view redrawing for it would redraw every second forever.
  Stream<List<Task>> watchTasks() => _callMore('Watch').map(_tasksOf);

  /// Agent binaries installed on the machine.
  ///
  /// The second value is what could not be asked, by file name. An agent that fails to describe
  /// itself is installed and unusable, and leaving it out would read as absent.
  Future<(List<Agent>, Map<String, String>)> agents() async {
    final reply = await _call('Agents');
    final found = reply['agents'];
    final failures = reply['failures'];
    return (
      found is List
          ? found.whereType<Map<String, dynamic>>().map(Agent.from).toList()
          : <Agent>[],
      failures is Map
          ? failures.map((key, value) => MapEntry('$key', '$value'))
          : <String, String>{},
    );
  }

  /// What the vault holds, without any of it.
  Future<VaultState> credentials() async => VaultState.from(await _call('Credentials'));

  // --------------------------------------------------------------------- running tasks

  /// Starts a task, streaming the build as it happens.
  ///
  /// The task outlives this call: canceling the stream stops the reporting, never the launch.
  /// Building an image takes minutes, so an interface must show these lines rather than nothing.
  Stream<StartProgress> start({
    String? task,
    String? project,
    String? agent,
    String? provider,
    String? credentialType,
    int? tokenHours,
    String? upstream,
    bool? noGate,
    bool? dryRun,
    String? clearance,
    bool? keep,
  }) {
    // Only what the caller named is sent, so the backend's own defaults stay the only defaults.
    // Restating them here would be a second place for them to drift.
    final parameters = <String, dynamic>{
      'task': ?task,
      'project': ?project,
      'agent': ?agent,
      'provider': ?provider,
      'credentialType': ?credentialType,
      'tokenHours': ?tokenHours,
      'upstream': ?upstream,
      'noGate': ?noGate,
      'dryRun': ?dryRun,
      'clearance': ?clearance,
      'keep': ?keep,
    };
    return _callMore('Start', parameters).map(StartProgress.from);
  }

  /// Stops a task and removes what is left of it.
  ///
  /// Refuses rather than destroys: a task holding commits that never reached the gate comes back
  /// as [Outcome.holdsWork], untouched. That refusal needs a real place in the interface - it is
  /// the product working, not an error.
  Future<Stopped> stop(String task,
          {bool? purge, bool? rescue, bool? force}) async =>
      Stopped.from(await _call('Stop', {
        'task': task,
        'purge': ?purge,
        'rescue': ?rescue,
        'force': ?force,
      }));

  /// Starts a stopped task again, with the helpers it is recorded as having had.
  Future<Resumed> resume(String task) async =>
      Resumed.from(await _call('Resume', {'task': task}));

  /// Every project on the machine.
  ///
  /// Nothing refreshes this: there is no `WatchProjects`, so it is asked again after anything
  /// that would change it — a task started or removed, a push approved.
  Future<List<Project>> projects() async {
    final reply = await _call('Projects');
    final projects = reply['projects'];
    return projects is List
        ? projects.whereType<Map<String, dynamic>>().map(Project.from).toList()
        : const <Project>[];
  }

  /// The curated destination sets installed on this machine, and where they were found.
  ///
  /// Scanned every time rather than fixed: a set an operator drops into their own directory turns
  /// up without anything being rebuilt, and theirs wins over a packaged one of the same name —
  /// which is why the locations come back in search order.
  Future<(List<EgressSet>, List<String>)> sets() async {
    final reply = await _call('Sets');
    final sets = reply['sets'];
    final locations = reply['locations'];
    return (
      sets is List
          ? sets.whereType<Map<String, dynamic>>().map(EgressSet.from).toList()
          : <EgressSet>[],
      locations is List ? locations.whereType<String>().toList() : <String>[],
    );
  }

  /// What a project's work may reach, and what it asks for and is deliberately not given.
  ///
  /// The whole composition a task run uses, the agent's own grants and its provider's host
  /// included. `refused` is the distinction a dropped packet cannot make: "we said no" and
  /// "nobody added it" look identical to the firewall.
  Future<(List<EgressHost>, List<String>)> egress(String project, {String? agent}) async {
    final reply = await _call('Egress', {'project': project, 'agent': ?agent});
    final hosts = reply['hosts'];
    final refused = reply['refused'];
    return (
      hosts is List
          ? hosts.whereType<Map<String, dynamic>>().map(EgressHost.from).toList()
          : <EgressHost>[],
      refused is List ? refused.whereType<String>().toList() : <String>[],
    );
  }

  /// Changes what a project's work may reach, or says what the change would do.
  ///
  /// With `dryRun` it answers `PREVIEWED` and writes nothing, having worked out exactly the
  /// `opens` and `closes` a real call would produce. **Nothing here reaches a running task**: a
  /// container's ruleset is built when it starts, so a change applies to the next one.
  Future<EgressChange> setEgress(
    String project, {
    List<String>? addSets,
    List<String>? removeSets,
    List<String>? addDomains,
    List<String>? removeDomains,
    bool? dryRun,
  }) async =>
      EgressChange.from(await _call('SetEgress', {
        'project': project,
        'addSets': ?addSets,
        'removeSets': ?removeSets,
        'addDomains': ?addDomains,
        'removeDomains': ?removeDomains,
        'dryRun': ?dryRun,
      }));

  /// Lets a **running** task reach names it could not reach before.
  ///
  /// Unlike [setEgress], which edits a file the *next* task reads, this reaches the container in
  /// front of somebody: the resolver is told without being restarted, and the grant is recorded
  /// where the clearance watcher reads it.
  ///
  /// [scope] is required and there is no default — the daemon answers `ScopeRequired` to a call
  /// without one. [Scope.run] does not survive a `Resume`.
  ///
  /// Names only. Sets are not granted this way, and **nothing narrows a running task**: taking a
  /// grant back from a container that has it is not decided, so there is no method for it.
  ///
  /// With `dryRun` it answers `PREVIEWED` with exactly the names a real call would grant, having
  /// changed nothing. Worth doing every time: this edit lands on work that is running.
  Future<Widened> widenTask(
    String task,
    List<String> domains, {
    required Scope scope,
    bool? dryRun,
  }) async =>
      Widened.from(await _call('WidenTask', {
        'task': task,
        'domains': domains,
        'scope': scope.wire,
        'dryRun': ?dryRun,
      }));

  /// Which logs a task has.
  ///
  /// Asked rather than assumed: which files exist depends on what the task started — one with no
  /// gate has no `gate.log`, one run with clearance off has no `clearance.log` — so a client that
  /// held the names would open an empty viewer on a file that was never going to exist, and would
  /// never show one a later release adds.
  ///
  /// An empty list is a normal answer. A task whose state directory is gone, which is what `Stop`
  /// with purge does, has no logs; so does a name that is not a Sokar task.
  Future<List<Log>> logsOf(String task) async {
    final reply = await _call('Logs', {'task': task});
    final logs = reply['logs'];
    return logs is List
        ? logs.whereType<Map<String, dynamic>>().map(Log.from).toList()
        : const <Log>[];
  }

  /// Reads a task's log once.
  Future<List<String>> readLog(String task, String log) async =>
      _linesOf(await _call('Tail', {'task': task, 'log': log}));

  /// Follows a task's log as it is written.
  Stream<List<String>> tailLog(String task, String log) =>
      _callMore('Tail', {'task': task, 'log': log}).map(_linesOf);

  // --------------------------------------------------------------------- the gate

  /// What is waiting at a project's gate.
  Future<GateState> gate(String project, {String? upstream}) async =>
      GateState.from(await _call('Pending', {
        'project': project,
        'upstream': ?upstream,
      }));

  /// What a pending push contains, as a diff and a log.
  Future<(String, String)> review(String project, String name,
      {String? upstream, String? against}) async {
    final reply = await _call('Review', {
      'project': project,
      'name': name,
      'upstream': ?upstream,
      'against': ?against,
    });
    final diff = reply['diff'];
    final log = reply['log'];
    return (diff is String ? diff : '', log is String ? log : '');
  }

  /// Forwards a pending push upstream.
  ///
  /// The only call that sends anything anywhere, and it makes the caller name the branch.
  Future<void> approve(String project, String name, String branch,
          {String? upstream}) async =>
      _call('Approve', {
        'project': project,
        'name': name,
        'branch': branch,
        'upstream': ?upstream,
      });

  /// Drops a pending push. The work stays in the mirror; only the request is gone.
  Future<void> reject(String project, String name, {String? upstream}) async =>
      _call('Reject', {
        'project': project,
        'name': name,
        'upstream': ?upstream,
      });

  // --------------------------------------------------------------------- clearance

  /// Blocked connections from every running task, as they happen.
  ///
  /// One subscription covers tasks started after the call, so an interface never has to discover
  /// and connect to each task's own socket.
  Stream<Prompt> prompts() => _callMore('Prompts').map(Prompt.from);

  /// Answers one prompt.
  ///
  /// [Prompt.key] goes back unchanged. A task that is not running has no watcher to tell, and
  /// that is refused rather than accepted and dropped.
  Future<bool> decide(Prompt prompt, {required bool allow}) async {
    final reply = await _call('Decide', {
      'task': prompt.task,
      'key': prompt.key,
      'address': prompt.destination,
      'allow': allow,
    });
    return reply['ok'] == true;
  }

  // --------------------------------------------------------------------- plumbing

  Future<Map<String, dynamic>> _call(String method,
      [Map<String, dynamic> parameters = const {}, bool qualify = true]) async {
    final connection = await VarlinkConnection.open(backend.socketPath);
    try {
      return await connection.call(qualify ? '$interfaceName.$method' : method, parameters);
    } on VarlinkException catch (ex) {
      if (ex.isMethodNotFound) throw FeatureNotSupported(method);
      rethrow;
    } finally {
      await connection.close();
    }
  }

  Stream<Map<String, dynamic>> _callMore(String method,
      [Map<String, dynamic> parameters = const {}]) async* {
    final connection = await VarlinkConnection.open(backend.socketPath);
    try {
      yield* connection.callMore('$interfaceName.$method', parameters).handleError(
            (Object error) => throw FeatureNotSupported(method),
            test: (dynamic error) => error is VarlinkException && error.isMethodNotFound,
          );
    } finally {
      await connection.close();
    }
  }

  static List<Task> _tasksOf(Map<String, dynamic> reply) {
    final tasks = reply['tasks'];
    return tasks is List
        ? tasks.whereType<Map<String, dynamic>>().map(Task.from).toList()
        : const [];
  }

  static List<String> _linesOf(Map<String, dynamic> reply) {
    final lines = reply['lines'];
    return lines is List ? lines.whereType<String>().toList() : const [];
  }
}

/// One reply from a task launch: either a line of output, or the result.
class StartProgress {
  /// A line the launch printed, or null on the final reply.
  final String? line;

  /// Container name of the started task, set on the final reply.
  final String? container;

  /// What the launch returned; zero is success. Set on the final reply.
  final int? exitCode;

  /// Constructor taking every field.
  const StartProgress({this.line, this.container, this.exitCode});

  /// Reads one from a reply.
  factory StartProgress.from(Map<String, dynamic> map) {
    final line = map['line'];
    final container = map['container'];
    final exitCode = map['exitCode'];
    return StartProgress(
      line: line is String ? line : null,
      container: container is String ? container : null,
      exitCode: exitCode is num ? exitCode.toInt() : null,
    );
  }

  /// Whether this is the last reply, carrying the result rather than output.
  bool get isResult => container != null || exitCode != null;
}
