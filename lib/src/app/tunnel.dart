import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'machines.dart';

/// Where a managed forward has got to.
enum TunnelState {
  /// Nothing has been asked of it yet.
  idle,

  /// `ssh` has been started and the socket is not there yet.
  raising,

  /// The socket exists and the process is alive.
  up,

  /// It could not be raised, or it went away and could not be raised again. [Tunnel.problem]
  /// carries what the transport said.
  down,
}

/// One forward this interface raised and owns.
///
/// **`ssh -L <local socket>:<remote socket> <host> -N`**, one process per machine, supervised.
/// Running `ssh` is not a breach of the rule against shelling out: that rule is about never
/// building a second implementation of the *domain* by parsing the `sokar` CLI, and `ssh` is
/// transport. Nothing about the contract, the calls or the refusals goes near it.
///
/// Three decisions are baked in here and each of them keeps this requirement small:
///
/// * **`BatchMode=yes`, so it never prompts.** A passphrase and an unknown host key are both
///   terminal prompts, and this has no terminal. With batch mode `ssh` fails instead, saying why
///   — *"Permission denied (publickey)"*, *"Host key verification failed"* — and that sentence is
///   shown as it came. The way through is an agent or a key with no passphrase, and accepting a
///   host key once in a shell. **Nothing here handles a passphrase**, deliberately.
/// * **One process per host, not a shared `ControlMaster`.** A master would be shared with the
///   person's own sessions, and tearing ours down could take theirs with it — which is exactly
///   what *"a tunnel the interface did not raise is never torn down by it"* forbids.
/// * **It does not outlive the window.** Friendlier if it did, and it would contradict the
///   criterion that closing leaves no forward running and no socket behind.
class Tunnel {
  /// Constructor taking which machine to reach.
  ///
  /// [start] is injectable so this can be proven without a remote host: a stand-in that creates
  /// the socket and stays up, or one that fails the way `ssh` fails, exercises every path here.
  Tunnel(
    this.machine, {
    Future<Process> Function(List<String> command)? start,
    Duration appears = const Duration(seconds: 10),
  })  : _launch = start ?? _runIt,
        _untilItBinds = appears;

  /// The machine this forwards to.
  final Machine machine;

  final Future<Process> Function(List<String> command) _launch;
  final Duration _untilItBinds;

  Process? _process;
  bool _wanted = false;

  /// Where it has got to.
  TunnelState state = TunnelState.idle;

  /// What the transport said, when it could not be raised. Null when nothing is wrong.
  ///
  /// **`ssh`'s own words, never ours.** *"Host key verification failed"* is a different problem
  /// from *"Connection refused"*, and a machine reported as simply not there sends somebody
  /// looking in the wrong place.
  String? problem;

  /// How many times it has been raised, so a re-raise is observable.
  int raised = 0;

  /// The command that raises it.
  ///
  /// `-N` because nothing is run at the far end; `ExitOnForwardFailure` so a forward that cannot
  /// bind fails the process rather than leaving `ssh` up with no socket under it, which would
  /// read as connected.
  List<String> get command => <String>[
        'ssh',
        '-N',
        '-o', 'BatchMode=yes',
        '-o', 'ExitOnForwardFailure=yes',
        '-o', 'ServerAliveInterval=15',
        '-L', '${machine.socketPath}:${machine.remoteSocket}',
        machine.host,
      ];

  /// Raises it, and waits until the socket is there or the transport says why not.
  Future<void> raise() async {
    _wanted = true;
    state = TunnelState.raising;
    problem = null;

    // ssh refuses to bind a path that already exists. A socket left by a run that died is a
    // leftover, and the alternative is a machine that can never be opened again without somebody
    // knowing to delete a file they have never heard of.
    _clearTheWay();

    final stopped = Completer<void>();
    try {
      final process = await _launch(command);
      _process = process;
      raised++;
      // Collected as one future rather than read line by line, because **the process can exit
      // before a subscription has delivered anything**: `ssh` prints one line and dies, and the
      // first version of this reported "exit code 255" with the sentence still in the pipe.
      final saying = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();
      unawaited(process.exitCode.then((code) async {
        await _itEnded(code, saying);
        if (!stopped.isCompleted) stopped.complete();
      }));
    } on ProcessException catch (ex) {
      state = TunnelState.down;
      problem = ex.message;
      return;
    }

    final by = DateTime.now().add(_untilItBinds);
    while (DateTime.now().isBefore(by)) {
      // The state and the words are both set before this completes, so there is nothing to race.
      if (stopped.isCompleted) return;
      // A *socket*, not merely a file. Anything left at that path would otherwise read as a
      // working forward — which is exactly what a leftover from a run that died looks like.
      if (FileSystemEntity.typeSync(machine.socketPath) ==
          FileSystemEntityType.unixDomainSock) {
        state = TunnelState.up;
        _lockTheEndpoint();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    // Up, and nothing bound. Said as a wait rather than as a refusal, because it is neither a
    // rejection by the far end nor a fault anybody can name.
    state = TunnelState.down;
    problem = 'the forward did not appear within ${_untilItBinds.inSeconds} seconds';
  }

  /// Takes it down and removes what it left.
  ///
  /// Safe to call on a tunnel that was never raised, which is what makes closing the window able
  /// to call it on everything without asking which is which.
  Future<void> drop() async {
    _wanted = false;
    final process = _process;
    _process = null;
    process?.kill();
    if (process != null) await process.exitCode;
    _clearTheWay();
    state = TunnelState.idle;
  }

  /// What is worth saying about it, or null when there is nothing.
  String? get words => switch (state) {
        TunnelState.raising => 'raising the forward…',
        TunnelState.down => problem,
        _ => null,
      };

  Future<void> _itEnded(int code, Future<List<String>> saying) async {
    // Everything ssh printed, in order. It says one useful sentence and several unhelpful ones,
    // and which is which depends on the failure — so all of it is kept and shown.
    final said = await saying;
    if (!_wanted) return;
    state = TunnelState.down;
    problem = said.isEmpty
        ? 'the forward stopped, exit code $code'
        : said.join(' ');
  }

  void _clearTheWay() {
    try {
      final left = File(machine.socketPath);
      if (left.existsSync()) left.deleteSync();
    } on FileSystemException {
      // Something else owns it. Raising will fail and say so, which is better than deciding here.
    }
  }

  /// Makes the endpoint owner-only.
  ///
  /// `ssh` already creates it that way; this is belt and braces on the one property of the
  /// transport that can be checked from here, and it costs nothing.
  void _lockTheEndpoint() {
    try {
      Process.runSync('chmod', <String>['600', machine.socketPath]);
    } on ProcessException {
      // Nothing to do, and nothing worth saying: the socket is already owner-only when ssh made
      // it, and this only ever tightens.
    }
  }

  static Future<Process> _runIt(List<String> command) =>
      Process.start(command.first, command.sublist(1));
}

/// Every forward this interface owns.
///
/// **It owns only what it raised.** A machine described by a socket path somebody else forwarded
/// is opened exactly as it always was: nothing is raised, nothing is supervised, and nothing is
/// taken down. That path has no credential handling in it at all, which is why it must keep
/// working untouched.
class Tunnels extends ChangeNotifier {
  /// Constructor taking how to start a forward, injectable for tests.
  Tunnels({
    Future<Process> Function(List<String> command)? start,
    Duration appears = const Duration(seconds: 10),
  })  : _launch = start,
        _untilItBinds = appears;

  final Future<Process> Function(List<String> command)? _launch;

  /// How long a forward is given to bind before it is called down.
  final Duration _untilItBinds;
  final Map<String, Tunnel> _mine = <String, Tunnel>{};

  /// The forward for one machine, or null when this interface did not raise it.
  Tunnel? of(Machine machine) => _mine[machine.name];

  /// Whether this interface raised the way in to [machine].
  bool manages(Machine machine) => _mine.containsKey(machine.name);

  /// Raises the forward for [machine], if it is one this interface manages.
  ///
  /// A machine that names no host is left alone and answers true: it is already reachable, by
  /// somebody else's forward, and there is nothing to do.
  Future<bool> raiseFor(Machine machine) async {
    if (!machine.needsATunnel) return true;
    final tunnel = _mine.putIfAbsent(
      machine.name,
      () => Tunnel(machine, start: _launch, appears: _untilItBinds),
    );
    await tunnel.raise();
    notifyListeners();
    return tunnel.state == TunnelState.up;
  }

  /// Raises it again after it dropped.
  ///
  /// Without being asked, because a forward that goes away is not a decision anybody made — but
  /// only for one this interface raised, and only while it is still wanted.
  Future<void> raiseAgainIfItDropped(Machine machine) async {
    final tunnel = _mine[machine.name];
    if (tunnel == null || tunnel.state != TunnelState.down) return;
    await tunnel.raise();
    notifyListeners();
  }

  /// Takes down the forward for one machine, if this interface raised it.
  Future<void> dropFor(Machine machine) async {
    final tunnel = _mine.remove(machine.name);
    if (tunnel == null) return;
    await tunnel.drop();
    notifyListeners();
  }

  /// Takes down everything this interface raised.
  ///
  /// Called when the window closes. **Only what is in here** — a forward somebody else raised is
  /// not in this map and is therefore untouchable, which is the whole of that criterion.
  Future<void> dropEverything() async {
    for (final tunnel in _mine.values.toList()) {
      await tunnel.drop();
    }
    _mine.clear();
    notifyListeners();
  }
}
