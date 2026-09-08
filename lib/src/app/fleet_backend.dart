import 'package:sokar_frontend/client.dart';

/// The backend, narrowed to what the frame asks of it.
///
/// The frame is judged on what a person sees when a backend answers, refuses or goes away, and
/// all three have to be producible in a widget test. A widget test runs on a fake clock, under
/// which a real socket makes no progress — so the wire is proven where it belongs, over a real
/// socket against the mock daemon in `test/client`, and the frame is proven against this.
///
/// It is deliberately four members wide. Anything that grows it is probably a screen reaching
/// past the frame for something it should be asking the client for directly.
abstract class FleetBackend {
  /// What to call this machine. An action must never be ambiguous about where it acts.
  String get label;

  /// Opens it and answers what it says it is.
  ///
  /// Throws [VarlinkDisconnected] when there is nothing there, and [StateError] when it serves
  /// no interface this build understands.
  Future<ServiceInfo> open();

  /// Every task on it, running or stopped.
  Future<List<Task>> tasks();

  /// What the machine has to run agents with.
  ///
  /// Asked rather than assumed: what is installed is a property of the machine, and a name this
  /// build knew would be one that was never going to exist somewhere else. Three answers, and the
  /// third is the one nobody would go looking for — a binary installed and permanently hidden by
  /// another copy.
  Future<AgentsOnTheMachine> agentsOn();

  /// Every project on it.
  ///
  /// Asked for, never derived from the task list: a project that has never run anything would be
  /// invisible, and that is the one most likely to need attention.
  Future<List<Project>> projects();

  /// The task list, again whenever it changes.
  ///
  /// Errors with [FeatureNotSupported] against a backend too old to have `Watch`, which is a
  /// reason to stop expecting changes rather than a reason to stop.
  Stream<List<Task>> watch();

  /// Starts a task, streaming what it prints, one line per event.
  ///
  /// Long: building an image takes minutes, and an interface showing nothing for that long is
  /// indistinguishable from one that has hung. The stream ending is success; it errors when the
  /// launch returned a non-zero code, because what an exit code means is known here and not by
  /// whatever records the result.
  ///
  /// With `dryRun` it does everything up to starting the container and then reports, creating
  /// nothing. That is all the frame uses today — choosing a name, an agent and a mode is
  /// [F08](../../../requirements/F08-Task-Creation-And-Modes.md), and it fills in the rest of
  /// these parameters rather than replacing them.
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
  });

  /// Stops a task and removes what is left of it, or refuses and says why.
  ///
  /// Refusing is the interesting answer: a task holding commits that never reached the gate comes
  /// back as `HOLDS_WORK`, untouched, and the caller decides what that work is worth.
  Future<Stopped> stopTask(
    String task, {
    bool? purge,
    bool? rescue,
    bool? force,
  });

  /// Starts a stopped task's container again, with the helpers it is recorded as having had.
  Future<Resumed> resumeTask(String task);

  /// What the protected store holds, by name. **Never a value.**
  Future<VaultState> credentials();

  /// Shuts the protected store. There is no `Unlock`: a daemon has no terminal for a passphrase.
  Future<Locked> lock();

  /// Whether work can start, asked before anything is created.
  Future<Readiness> canStart({String? project, String? agent});

  /// Stops every running task and its helpers at once, or says what it would stop.
  ///
  /// **Stops and never removes.** What comes back is what survived, not what was cleared away.
  Future<Panicked> panic({bool? dryRun});

  /// Blocked connections from every task on this machine, as they happen.
  ///
  /// Streaming only, and one subscription covers tasks started after the call.
  Stream<Prompt> prompts();

  /// Answers one blocked connection.
  ///
  /// A task that is not running has no watcher to tell, and that is refused with `NoClearance`
  /// rather than accepted and dropped.
  Future<void> decide(Prompt prompt, {required bool allow});

  /// What a project's work may reach, and what is asked for and deliberately not given.
  Future<(List<EgressHost>, List<String>)> egressOf(String projectFile);

  /// The destination sets installed on this machine, and where they were found.
  Future<(List<EgressSet>, List<String>)> egressSets();

  /// Changes what a project's work may reach, or says what the change would do.
  ///
  /// **Nothing here reaches a running task**: a container's ruleset is built when it starts.
  Future<EgressChange> changeEgress(
    String projectFile, {
    List<String>? addSets,
    List<String>? removeSets,
    List<String>? addDomains,
    List<String>? removeDomains,
    bool? dryRun,
  });

  /// Lets a **running** task reach names it could not reach before.
  ///
  /// The counterpart to [changeEgress], which reaches the next task and not this one. [scope] is
  /// required and has no default: this run, or this run and the project file.
  Future<Widened> widenTask(
    String task,
    List<String> domains, {
    required Scope scope,
    bool? dryRun,
  });

  /// What is waiting at a project's gate.
  ///
  /// [projectFile] is `Project.file`, passed through unchanged. A project that has none can be
  /// listed and not asked about — that is a state to render, never a call to make anyway.
  Future<GateState> gateOf(String projectFile);

  /// What one waiting push contains, so it can be judged before it is forwarded.
  ///
  /// [against] diffs against something other than the upstream's default branch.
  Future<({String diff, String log})> reviewOf(
    String projectFile,
    String name, {
    String? against,
  });

  /// Forwards a waiting push upstream, onto a branch the caller names.
  ///
  /// **The only thing in this interface that sends anything anywhere**, and the branch is never
  /// inferred: a push forwarded onto a guess is one nobody decided about.
  Future<void> approve(String projectFile, String name, String branch);

  /// Drops the request. The work stays in the mirror; only the asking is gone.
  Future<void> reject(String projectFile, String name);

  /// Which logs a task has, asked rather than assumed.
  ///
  /// An empty list is a normal answer: a task whose state directory is gone has none.
  Future<List<Log>> logsOf(String task);

  /// Follows one of a task's logs as it is written, a batch of lines per reply.
  ///
  /// The name comes from [logsOf] unchanged: it is a file in the task's state directory, never a
  /// path, and `Tail` refuses anything else.
  Stream<List<String>> tailLog(String task, String log);
}

/// A real Sokar daemon, local or forwarded.
class SokarBackend implements FleetBackend {
  /// Constructor taking where the daemon is.
  SokarBackend(this.backend);

  /// The socket and its name.
  final Backend backend;

  SokarClient? _client;

  @override
  String get label => backend.label;

  @override
  Future<ServiceInfo> open() async {
    final client = await SokarClient.connect(backend);
    _client = client;
    return client.info;
  }

  @override
  Future<List<Task>> tasks() => _opened().tasks();

  @override
  Future<AgentsOnTheMachine> agentsOn() => _opened().agents();

  @override
  Future<List<Project>> projects() => _opened().projects();

  @override
  Stream<List<Task>> watch() => _opened().watchTasks();

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
  }) async* {
    // Streaming, so every line arrives as `line`; the contract's `output` list is for a caller
    // that did not ask to stream and is empty here.
    var exitCode = 0;
    await for (final progress in _opened().start(
      task: task,
      project: project,
      agent: agent,
      dryRun: dryRun,
      mode: mode,
      prompt: prompt,
      model: model,
      maxTurns: maxTurns,
      minutes: minutes,
    )) {
      final line = progress.line;
      if (line != null) yield line;
      if (progress.exitCode != null) exitCode = progress.exitCode!;
    }
    if (exitCode != 0) throw OperationFailed(exitCode);
  }

  @override
  Future<Stopped> stopTask(
    String task, {
    bool? purge,
    bool? rescue,
    bool? force,
  }) =>
      _opened().stop(task, purge: purge, rescue: rescue, force: force);

  @override
  Future<Resumed> resumeTask(String task) => _opened().resume(task);

  @override
  Future<VaultState> credentials() => _opened().credentials();

  @override
  Future<Locked> lock() => _opened().lock();

  @override
  Future<Readiness> canStart({String? project, String? agent}) =>
      _opened().canStart(project: project, agent: agent);

  @override
  Future<Panicked> panic({bool? dryRun}) => _opened().panic(dryRun: dryRun);

  @override
  Stream<Prompt> prompts() => _opened().prompts();

  @override
  Future<void> decide(Prompt prompt, {required bool allow}) async =>
      _opened().decide(prompt, allow: allow);

  @override
  Future<(List<EgressHost>, List<String>)> egressOf(String projectFile) =>
      _opened().egress(projectFile);

  @override
  Future<(List<EgressSet>, List<String>)> egressSets() => _opened().sets();

  @override
  Future<EgressChange> changeEgress(
    String projectFile, {
    List<String>? addSets,
    List<String>? removeSets,
    List<String>? addDomains,
    List<String>? removeDomains,
    bool? dryRun,
  }) =>
      _opened().setEgress(
        projectFile,
        addSets: addSets,
        removeSets: removeSets,
        addDomains: addDomains,
        removeDomains: removeDomains,
        dryRun: dryRun,
      );

  @override
  Future<Widened> widenTask(
    String task,
    List<String> domains, {
    required Scope scope,
    bool? dryRun,
  }) =>
      _opened().widenTask(task, domains, scope: scope, dryRun: dryRun);

  @override
  Future<GateState> gateOf(String projectFile) => _opened().gate(projectFile);

  @override
  Future<({String diff, String log})> reviewOf(
    String projectFile,
    String name, {
    String? against,
  }) async {
    final (diff, log) =
        await _opened().review(projectFile, name, against: against);
    return (diff: diff, log: log);
  }

  @override
  Future<void> approve(String projectFile, String name, String branch) =>
      _opened().approve(projectFile, name, branch);

  @override
  Future<void> reject(String projectFile, String name) =>
      _opened().reject(projectFile, name);

  @override
  Future<List<Log>> logsOf(String task) => _opened().logsOf(task);

  @override
  Stream<List<String>> tailLog(String task, String log) =>
      _opened().tailLog(task, log);

  SokarClient _opened() {
    final client = _client;
    if (client == null) throw StateError('open() has not answered yet');
    return client;
  }
}

/// A launch that ran and came back with something other than zero.
///
/// Not a fault in the client and not a lost backend: the operation ran, and it failed. It gets
/// said in the same place a success would have been said.
class OperationFailed implements Exception {
  /// Constructor taking what the launch returned.
  const OperationFailed(this.exitCode);

  /// What the launch returned. Never zero.
  final int exitCode;

  /// Whether there is a log worth offering.
  ///
  /// Two of the bands are not failed runs at all. `69` means the run was **refused before
  /// anything was created**, so there is nothing to read — offering a log view there opens an
  /// empty window on a file that was never written.
  bool get leftALog => exitCode != 69;

  /// Whether the run was stopped by its own time limit rather than by going wrong.
  ///
  /// The log is kept, deliberately, and what it managed to do is usually the interesting part.
  bool get ranOutOfTime => exitCode == 124;

  /// Whether nothing ran, as opposed to something running badly.
  ///
  /// Nothing was created either: no container, no workspace, nothing to clear up. More than one
  /// thing answers `69` — no agent installed, and an unattended run whose credential could not be
  /// read — so **the reason is in the output and is never guessed at here.** `Start` has no
  /// outcome vocabulary, which is the gap this band is standing in for.
  bool get nothingRan => exitCode == 69;

  @override
  String toString() => switch (exitCode) {
        // Four bands, not two. Reading every non-zero code as "it failed" throws away the two
        // that are not failures of the work at all.
        124 => 'It ran out of the time it was given and was stopped. What it managed to do is '
            'in the log.',
        // Not "no agent is installed": more than one refusal answers 69, and the daemon prints
        // which. Naming one of them here would be wrong exactly when it was believed.
        69 => 'Nothing ran, and nothing was created. It was refused before it began; '
            'what was refused is in the output above.',
        _ => 'The agent exited with code $exitCode.',
      };
}
