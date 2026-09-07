import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';
import 'fleet_model.dart';
import 'tunnel.dart';
import 'settings.dart';

/// One machine this interface can reach.
///
/// A name and a socket path — and, when the interface raises the way in itself, where that
/// machine is. **Both kinds must keep working.** A socket somebody else forwarded is the path
/// with no credential handling in it at all, so a machine described by a path is opened exactly
/// as it always was: nothing raised, nothing supervised, nothing taken down.
@immutable
class Machine {
  /// Constructor taking what to call it and where its socket is.
  ///
  /// [host] and [remoteSocket] are given only for a machine this interface reaches itself. With
  /// no [host] it is a socket somebody else forwarded, which is the first half of
  /// [F20](../../../requirements/F20-Access-From-Elsewhere.md) and stays untouched.
  const Machine({
    required this.name,
    required this.socketPath,
    this.host = '',
    this.remoteSocket = '',
  });

  /// The machine to open when nothing has been stored yet.
  ///
  /// The local daemon, unless `SOKAR_SOCKET` names another socket — a forwarded one, or the mock
  /// while the interface is being worked on. [environment] is injectable so this can be held to
  /// that: it was quietly dropped once during the rework that made several machines possible, and
  /// nothing noticed until the window said it could not connect to a daemon nobody was running.
  factory Machine.local({Map<String, String>? environment}) {
    final socket = (environment ?? Platform.environment)['SOKAR_SOCKET'];
    if (socket == null || socket.isEmpty) {
      return Machine(name: 'this machine', socketPath: Backend.local().socketPath);
    }
    return Machine(name: socket.split('/').last, socketPath: socket);
  }

  /// Reads one back from what was stored.
  factory Machine.fromStored(Map<String, Object?> stored) => Machine(
        name: stored['name'] as String? ?? '',
        socketPath: stored['socket'] as String? ?? '',
        host: stored['host'] as String? ?? '',
        remoteSocket: stored['remoteSocket'] as String? ?? '',
      );

  /// What to call it. Shown wherever an action could be ambiguous about where it lands.
  final String name;

  /// The unix socket to open. For a managed machine, the local end this interface creates.
  final String socketPath;

  /// Where the machine is, as `ssh` would be given it. Empty when somebody else forwards it.
  final String host;

  /// The socket on that machine. Empty when somebody else forwards it.
  final String remoteSocket;

  /// Whether this interface raises the way in to it.
  ///
  /// The one question a person needs answered about a machine in the list, because it decides
  /// what happens when it stops answering — and what happens when the window closes.
  bool get needsATunnel => host.isNotEmpty && remoteSocket.isNotEmpty;

  /// How it is stored between runs.
  ///
  /// The host is stored; **nothing about a key ever is.** What makes the forward possible lives
  /// in the person's own SSH configuration, which is where it was before this interface existed.
  Map<String, Object?> get stored => <String, Object?>{
        'name': name,
        'socket': socketPath,
        if (host.isNotEmpty) 'host': host,
        if (remoteSocket.isNotEmpty) 'remoteSocket': remoteSocket,
      };

  /// Where the local end of a managed forward goes.
  ///
  /// Under the runtime directory, which is the one place already owner-only — the criterion that
  /// the endpoint is readable by nobody else is answered by where it is put, not by what is done
  /// to it afterwards.
  static String endpointFor(String name, {Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final runtime = env['XDG_RUNTIME_DIR'] ??
        '/run/user/${Process.runSync('id', const <String>['-u']).stdout.toString().trim()}';
    final safe = name.replaceAll(RegExp('[^A-Za-z0-9_-]'), '-');
    return '$runtime/sokar-tunnel-$safe.sock';
  }

  /// Whether the socket is readable by anybody but its owner.
  ///
  /// `ssh` creates a forwarded endpoint owner-only, so this should never be true — but it is the
  /// one property of the transport that can be checked from here, and a forward somebody made by
  /// hand can be looser than the socket it forwards.
  bool get readableByOthers {
    try {
      final mode = FileStat.statSync(socketPath).mode;
      return mode & 0x3F != 0; // any group or other bit
    } on FileSystemException {
      return false;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Machine &&
      other.name == name &&
      other.socketPath == socketPath &&
      other.host == host &&
      other.remoteSocket == remoteSocket;

  @override
  int get hashCode => Object.hash(name, socketPath, host, remoteSocket);
}

/// Every machine this interface is watching, and which one it is acting on.
///
/// **Connected to all of them, acting on one.** A clearance prompt has a deadline and does not
/// come again, so a machine nobody is connected to is a machine whose blocked work expires
/// unseen. Which one an action lands on is a separate question, and it is answered by [selected]
/// — never by which one happens to be reachable.
class Machines extends ChangeNotifier {
  /// Constructor taking where the list is kept and how to reach a machine.
  ///
  /// One machine exists from the moment this does, before anything is read back from disk. The
  /// frame is drawn before [load] can finish, and a frame with no machine behind it has nothing
  /// to draw — which it did, as a crash on the first frame.
  Machines(this._settings, {FleetBackend Function(Machine)? reach, Tunnels? tunnels})
      : _reach = reach ?? _overSocket,
        tunnels = tunnels ?? Tunnels() {
    _adopt(<Machine>[Machine.local()]);
  }

  final Settings _settings;
  final FleetBackend Function(Machine) _reach;

  /// The forwards this interface raised. **Only the ones it raised** — a socket somebody else
  /// forwarded is opened as it always was, and is not in here to be taken down.
  final Tunnels tunnels;
  final Map<String, FleetModel> _watching = <String, FleetModel>{};
  final List<Machine> _machines = <Machine>[];
  String? _selected;
  bool _disposed = false;

  static FleetBackend _overSocket(Machine machine) =>
      SokarBackend(Backend(socketPath: machine.socketPath, label: machine.name));

  /// Every machine, in the order they were added.
  List<Machine> get all => List<Machine>.unmodifiable(_machines);

  /// What is being acted on. There is always one.
  Machine get current => _machines.firstWhere(
      (machine) => machine.name == _selected,
      orElse: () => _machines.first);

  /// The fleet of the machine being acted on.
  FleetModel get fleet => of(current);

  /// The fleet of one machine, whether or not it is the one being acted on.
  FleetModel of(Machine machine) => _watching[machine.name]!;

  /// How many machines are not answering.
  int get unreachable => _watching.values
      .where((fleet) => fleet.reachability == Reachability.unreachable)
      .length;

  /// Reads the machines an earlier run stored and opens all of them.
  ///
  /// Nothing stored leaves the one this started with, which is the local daemon or whatever
  /// `SOKAR_SOCKET` names.
  Future<void> load() async {
    final stored = await _settings.machines();
    if (stored.isEmpty) return;
    _adopt(stored);
    _notify();
  }

  /// Replaces the set of machines being watched, closing what watched the old ones.
  void _adopt(List<Machine> machines) {
    for (final fleet in _watching.values) {
      fleet
        ..removeListener(_notify)
        ..dispose();
    }
    _watching.clear();
    _machines
      ..clear()
      ..addAll(machines);
    _selected = _machines.first.name;
    for (final machine in _machines) {
      _open(machine);
    }
  }

  /// Adds a machine and opens it. Adding never changes which one is being acted on.
  Future<void> add(Machine machine) async {
    if (_machines.any((each) => each.name == machine.name)) return;
    _machines.add(machine);
    _open(machine);
    await _remember();
    _notify();
  }

  /// Forgets a machine, closing what was watching it and taking down any forward raised for it.
  ///
  /// Forgetting the one being acted on moves to another rather than leaving nothing selected: a
  /// frame with no machine behind it has nothing to say and no way to say why.
  Future<void> forget(Machine machine) async {
    if (_machines.length == 1) return;
    _machines.remove(machine);
    _watching.remove(machine.name)?.dispose();
    unawaited(tunnels.dropFor(machine));
    if (_selected == machine.name) _selected = _machines.first.name;
    await _remember();
    _notify();
  }

  /// Chooses which machine actions land on.
  void select(Machine machine) {
    if (_selected == machine.name) return;
    _selected = machine.name;
    _notify();
  }

  final Set<String> _raisingAgain = <String>{};

  void _open(Machine machine) {
    final fleet = FleetModel(_reach(machine));
    // Not simply `_notify`: a managed machine that stops answering is a forward that dropped, and
    // nobody should have to ask for it to come back.
    fleet.addListener(() {
      _notify();
      if (fleet.reachability == Reachability.unreachable) {
        unawaited(raiseAgainIfNeeded(machine));
      }
    });
    _watching[machine.name] = fleet;
    unawaited(_openAndConnect(machine, fleet));
  }

  /// Raises the way in, if this interface owns it, and then connects.
  ///
  /// A machine somebody else forwarded goes straight to connecting: [Tunnels.raiseFor] answers
  /// true for it without starting anything.
  Future<void> _openAndConnect(Machine machine, FleetModel fleet) async {
    await tunnels.raiseFor(machine);
    await fleet.connect();
    _notify();
  }

  /// Raises a dropped forward again and reconnects over it.
  ///
  /// Without being asked: a forward that goes away is not a decision anybody made. Only for one
  /// this interface raised, and only for a machine that is not answering — a working connection
  /// is never disturbed to check on the thing underneath it.
  Future<void> raiseAgainIfNeeded(Machine machine) async {
    if (!tunnels.manages(machine)) return;
    final fleet = _watching[machine.name];
    if (fleet == null || fleet.reachability == Reachability.connected) return;
    // Reconnecting moves the fleet, which notifies, which lands back here. One at a time per
    // machine, or a forward that cannot be raised becomes a loop that never stops trying.
    if (!_raisingAgain.add(machine.name)) return;
    try {
      await tunnels.raiseAgainIfItDropped(machine);
      if (tunnels.of(machine)?.state == TunnelState.up) await fleet.connect();
    } finally {
      _raisingAgain.remove(machine.name);
    }
    _notify();
  }

  /// Takes down every forward this interface raised.
  ///
  /// Closing the window leaves nothing running and no socket behind — and touches nothing
  /// somebody else raised, because nothing of theirs is in [tunnels].
  Future<void> letGoOfTheTunnels() => tunnels.dropEverything();

  Future<void> _remember() => _settings.rememberMachines(_machines);

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final fleet in _watching.values) {
      fleet
        ..removeListener(_notify)
        ..dispose();
    }
    _watching.clear();
    super.dispose();
  }
}
