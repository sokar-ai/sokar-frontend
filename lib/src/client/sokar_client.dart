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
/// What one machine has to run agents with: the ones it can use, the ones it cannot, and the ones
/// it will never reach.
///
/// Named rather than positional, because three lists of different things in a row is three
/// positions somebody has to remember at every call site.
typedef AgentsOnTheMachine = ({
  List<Agent> agents,
  Map<String, String> failures,
  List<ShadowedAgent> shadowed,
});


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
  Future<AgentsOnTheMachine> agents() async {
    final reply = await _call('Agents');
    final found = reply['agents'];
    final failures = reply['failures'];
    final shadowed = reply['shadowed'];
    return (
      // One entry per name: they are keyed by name on the daemon side, and a copy that loses to
      // another is resolved away before this list is built rather than marked in it.
      agents: found is List
          ? found.whereType<Map<String, dynamic>>().map(Agent.from).toList()
          : <Agent>[],
      failures: failures is Map
          ? failures.map((key, value) => MapEntry('$key', '$value'))
          : <String, String>{},
      shadowed: shadowed is List
          ? shadowed.whereType<Map<String, dynamic>>().map(ShadowedAgent.from).toList()
          : <ShadowedAgent>[],
    );
  }

  /// What the vault holds, without any of it.
  Future<VaultState> credentials() async => VaultState.from(await _call('Credentials'));

  // --------------------------------------------------------------------- running tasks

  /// Starts a task, streaming the build as it happens.
  ///
  /// The task outlives this call: canceling the stream stops the reporting, never the launch.
  /// Building an image takes minutes, so an interface must show these lines rather than nothing.
  ///
  /// **Giving a [prompt] makes this call run the agent**, not merely bring the container up. It
  /// then lasts as long as the run — minutes, sometimes tens of them — which is why `Start`
  /// streams and why nothing here puts a deadline on it. A deadline would not stop the agent
  /// anyway: the run carries on in the container and the caller has only stopped watching, which
  /// is a different thing to tell somebody than "canceled".
  ///
  /// What arrives is the **raw log**, the same text `Tail` serves for `task.log`. The formatted
  /// view an agent can produce is made in the CLI process and is not on the wire.
  ///
  /// [mode] is genuinely optional and **the backend's default depends on the prompt** —
  /// `UNATTENDED` when one is given, `SHELL` otherwise — so nothing is restated here. What must
  /// never be sent is `SHELL` together with a prompt: it is accepted and recorded, and it says a
  /// person is driving a run nobody is attached to.
  ///
  /// Without a prompt nothing changed: the container comes up and the call returns.
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
    Mode? mode,
    String? prompt,
    String? model,
    int? maxTurns,
    int? minutes,
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
      'mode': ?mode?.name,
      'prompt': ?prompt,
      'model': ?model,
      'maxTurns': ?maxTurns,
      'minutes': ?minutes,
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

  /// Sets or clears the caption a task reads by.
  ///
  /// **Beside the identity, never instead of it.** The container name, the gate ref, the
  /// workspace and the log files do not move: renaming would move a ref that may have unreviewed
  /// pushes behind it, which is what F09 asked for and not what anybody wanted.
  ///
  /// An empty [label] clears it rather than storing spaces.
  Future<Labelled> label(String task, {String? label}) async =>
      Labelled.from(await _call('Label', {'task': task, 'label': ?label}));

  /// Shuts the protected store.
  ///
  /// **There is deliberately no `Unlock`.** A daemon has no terminal to take a passphrase at, so
  /// it can shut the vault and can never open it — that asymmetry is the design, not a missing
  /// method, and it belongs on the screen where somebody looks for the button.
  Future<Locked> lock() async => Locked.from(await _call('Lock'));

  /// Whether work can start, asked **before anything is created**.
  ///
  /// The rule turns on four things — the agent's declaration, the installed providers, the run's
  /// own override, and what the vault already holds — and a client has one of them. So this is
  /// asked rather than assembled, and `credential` names **the key that was actually looked
  /// for**: a vault written before the provider-keyed change answers under the agent's own name,
  /// and naming the other would report a key missing from a vault that has it.
  Future<Readiness> canStart({
    String? project,
    String? agent,
    String? provider,
    String? credentialType,
  }) async =>
      Readiness.from(await _call('CanStart', {
        'project': ?project,
        'agent': ?agent,
        'provider': ?provider,
        'credentialType': ?credentialType,
      }));

  /// Stops every running task and its helpers at once.
  ///
  /// **It stops and never removes.** Workspaces, logs and unpushed commits all survive, and
  /// `Resume` brings a task back with the work it had — so nothing here is a cleanup, and saying
  /// otherwise would send somebody looking for work that is exactly where they left it.
  ///
  /// With `dryRun` it lists what it would stop and stops nothing. Worth doing every time: this is
  /// the action somebody reaches for without yet knowing what is wrong.
  Future<Panicked> panic({bool? dryRun}) async =>
      Panicked.from(await _call('Panic', {'dryRun': ?dryRun}));

  /// Turns enforcement on or off on a task that is already running.
  ///
  /// **Deliberately not widening with a special value.** Those grant and withdraw names, and that
  /// the firewall stays loaded is what they mean; folding *"stop asking about anything"* into them
  /// would make one method mean two unrelated things, and the quiet one would be the dangerous
  /// one.
  Future<ClearanceSet> setClearance(String task, String mode, {bool? dryRun}) async =>
      ClearanceSet.from(await _call(
          'SetClearance', {'task': task, 'mode': mode, 'dryRun': ?dryRun}));

  /// Takes names back from a running task, and optionally from its project file.
  ///
  /// **This stops new connections and not the ones already running.** A transfer in progress runs
  /// to its end, because the ruleset accepts established traffic without consulting the set again.
  ///
  /// [scope] is required and has no default, exactly as for widening: narrowing only the run when
  /// somebody meant the project too leaves the next task starting with the host still open.
  Future<Narrowed> narrowTask(
    String task,
    List<String> domains, {
    required Scope scope,
    bool? dryRun,
  }) async =>
      Narrowed.from(await _call('NarrowTask', {
        'task': task,
        'domains': domains,
        'scope': scope.name,
        'dryRun': ?dryRun,
      }));

  /// What backups have been taken of a project's mirror.
  ///
  /// **Read from a record written when each was taken**, because a bundle is written wherever an
  /// operator names it and nothing could work that out afterwards. Newest first, and **empty is an
  /// ordinary answer**: a project nobody has backed up, or one backed up by a Sokar older than the
  /// record. It never means no bundle exists.
  Future<List<Backup>> backups(String project) async {
    final reply = await _call('Backups', {'project': project});
    final backups = reply['backups'];
    return backups is List
        ? backups.whereType<Map<String, dynamic>>().map(Backup.from).toList()
        : const <Backup>[];
  }

  /// Removes a backup, or says what removing it would take.
  ///
  /// **It takes the path rather than an index**: a list that shifted between somebody reading it
  /// and acting on it would otherwise delete a different backup than the one they chose. And it
  /// refuses a path no record names, which is what keeps it from being a file-deletion primitive
  /// wearing a backup's name.
  Future<BackupDeleted> deleteBackup(String project, String bundle, {bool? dryRun}) async =>
      BackupDeleted.from(await _call('DeleteBackup',
          {'project': project, 'bundle': bundle, 'dryRun': ?dryRun}));

  /// Creates a project file, having checked the answers against this machine first.
  ///
  /// **The checking is what a client cannot do for itself**: whether a security class is spelled
  /// right, whether an egress set exists here, whether the name survives becoming an image tag and
  /// an nftables set name. An answer accepted in a form and rejected at the first task start is
  /// rejected far from where it was given.
  ///
  /// `ALREADY_EXISTS` is **a refusal and never an overwrite**: the file may be somebody's whole
  /// configuration, and this is the one operation that would replace it with nothing to restore
  /// from.
  Future<Created> createProject({
    required String file,
    required String name,
    required String securityClass,
    required String baseImage,
    String? upstream,
    List<String> sets = const <String>[],
    bool? dryRun,
  }) async =>
      Created.from(await _call('CreateProject', {
        'file': file,
        'name': name,
        'securityClass': securityClass,
        'baseImage': baseImage,
        'upstream': ?upstream,
        'sets': sets,
        'dryRun': ?dryRun,
      }));

  /// Builds a project's task image without starting anything.
  ///
  /// **Streamed, because a build takes minutes** and showing nothing for that long is
  /// indistinguishable from having hung.
  ///
  /// [rebuild] is `CACHED`, `AGENT` or `EVERYTHING`. `CACHED` is not *"skip the build"*: the build
  /// runs and the layer cache decides line by line, which is what every task start already does.
  /// `AGENT` keeps the base image and its packages, and is a mechanism rather than a switch —
  /// there is no *"rebuild from here"*, so it works by changing a build argument placed where the
  /// agent's layers begin.
  Stream<PrepareProgress> prepare(
    String project, {
    String? agent,
    String? rebuild,
    bool? dryRun,
  }) =>
      _callMore('Prepare', {
        'project': project,
        'agent': ?agent,
        'rebuild': ?rebuild,
        'dryRun': ?dryRun,
      }).map(PrepareProgress.from);

  /// Whether this machine can actually run a task, and what it is short of.
  ///
  /// **It runs external programs to find out, so it takes a moment and is not something to
  /// poll.** Still a read: nothing about it changes anything.
  Future<Health> doctor() async =>
      Health.from(await _call('Doctor', const <String, dynamic>{}));

  /// Which providers this machine has, and where a credential for each belongs.
  Future<Providers> providers() async =>
      Providers.from(await _call('Providers', const <String, dynamic>{}));

  /// Imports a credential an agent already holds on the machine.
  ///
  /// **No secret crosses this socket doing it**: the daemon reads the agent's own config file on
  /// its own disk, and only a name comes back. [agent] omitted means *the only one installed* —
  /// which is not the same as an empty string, and an empty string matches nothing.
  Future<Imported> importCredential({String? agent, String? configDirectory}) async =>
      Imported.from(await _call('ImportCredential',
          {'agent': ?agent, 'configDirectory': ?configDirectory}));

  /// Which node this is.
  ///
  /// **`GetInfo` says what a daemon is and never which one.** This says which one — so two entries
  /// in a list of machines can be told to be the same node reached two ways, which a client
  /// cannot work out for itself: a hostname has many spellings, and a socket somebody else
  /// forwarded looks nothing like a tunnel this interface raised to the same place.
  ///
  /// **An empty answer is not an identity.** A daemon older than the method answers nothing, and
  /// treating that as a value would report every such machine as the same node.
  Future<String> node() async {
    final answered = await _call('Node', const <String, dynamic>{});
    final id = answered['id'];
    return id is String ? id : '';
  }

  /// Removes what Sokar built for a project.
  ///
  /// **Not "deleting the project".** The project file is the operator's, in their own directory,
  /// and so are their checkout and their real upstream — none is touched, and `keeps` names them.
  /// What goes is the mirror, the image, the build directory, the registry entry, the recorded
  /// upstream distance, and every task with its container, state and logs. Afterwards a task run
  /// in that directory builds all of it again, which is what makes this safe to offer at all.
  ///
  /// It **refuses rather than decides**: unreviewed pushes exist only in the mirror and a running
  /// task is work cut off mid-flight. `force` is how somebody says they meant it.
  Future<Deletion> deleteProject(String project, {bool? dryRun, bool? force}) async =>
      Deletion.from(await _call(
          'DeleteProject', {'project': project, 'dryRun': ?dryRun, 'force': ?force}));

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

/// One reply from a build: a line it printed, or the result.
class PrepareProgress {
  /// A line the build printed, or null on the final reply.
  final String? line;

  /// `PREPARED`, `PREVIEWED`, `NO_SUCH_PROJECT` or `FAILED`. Null while output is still arriving.
  final String? outcome;

  /// The image that was built, or empty when nothing was.
  final String image;

  /// The depth actually used.
  ///
  /// **Read rather than assumed.** It comes back so a depth this build asked for and the daemon
  /// did not recognise is visible instead of being silently defaulted.
  final String rebuild;

  /// Why it failed, naming the step. Empty otherwise.
  final String detail;

  /// Constructor taking every field.
  const PrepareProgress({
    this.line,
    this.outcome,
    this.image = '',
    this.rebuild = '',
    this.detail = '',
  });

  /// Reads one from a reply.
  factory PrepareProgress.from(Map<String, dynamic> map) {
    final line = map['line'];
    final outcome = map['outcome'];
    return PrepareProgress(
      line: line is String ? line : null,
      outcome: outcome is String ? outcome : null,
      image: map['image'] is String ? map['image']! as String : '',
      rebuild: map['rebuild'] is String ? map['rebuild']! as String : '',
      detail: map['detail'] is String ? map['detail']! as String : '',
    );
  }

  /// Whether this is the last reply, carrying the result rather than output.
  bool get isResult => outcome != null;

  /// Whether an image was built.
  bool get built => outcome == 'PREPARED';
}
