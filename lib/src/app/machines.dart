import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';
import 'fleet_model.dart';
import 'settings.dart';

/// One machine this interface can reach.
///
/// A name and a socket path, and nothing else — because that is the whole of the difference
/// between a local Sokar and one on another machine. The forward is somebody else's to raise;
/// [F27](../../../requirements/F27-Managed-Tunnels.md) is the interface raising it, and must
/// never become the only way in.
@immutable
class Machine {
  /// Constructor taking what to call it and where its socket is.
  const Machine({required this.name, required this.socketPath});

  /// The daemon on this machine.
  factory Machine.local() =>
      Machine(name: 'this machine', socketPath: Backend.local().socketPath);

  /// Reads one back from what was stored.
  factory Machine.fromStored(Map<String, Object?> stored) => Machine(
        name: stored['name'] as String? ?? '',
        socketPath: stored['socket'] as String? ?? '',
      );

  /// What to call it. Shown wherever an action could be ambiguous about where it lands.
  final String name;

  /// The unix socket to open.
  final String socketPath;

  /// How it is stored between runs.
  Map<String, Object?> get stored =>
      <String, Object?>{'name': name, 'socket': socketPath};

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
      other is Machine && other.name == name && other.socketPath == socketPath;

  @override
  int get hashCode => Object.hash(name, socketPath);
}

/// Every machine this interface is watching, and which one it is acting on.
///
/// **Connected to all of them, acting on one.** A clearance prompt has a deadline and does not
/// come again, so a machine nobody is connected to is a machine whose blocked work expires
/// unseen. Which one an action lands on is a separate question, and it is answered by [selected]
/// — never by which one happens to be reachable.
class Machines extends ChangeNotifier {
  /// Constructor taking where the list is kept and how to reach a machine.
  Machines(this._settings, {FleetBackend Function(Machine)? reach})
      : _reach = reach ?? _overSocket;

  final Settings _settings;
  final FleetBackend Function(Machine) _reach;
  final Map<String, FleetModel> _watching = <String, FleetModel>{};
  final List<Machine> _machines = <Machine>[];
  String? _selected;
  bool _disposed = false;

  static FleetBackend _overSocket(Machine machine) =>
      SokarBackend(Backend(socketPath: machine.socketPath, label: machine.name));

  /// Every machine, in the order they were added.
  List<Machine> get all => List<Machine>.unmodifiable(_machines);

  /// What is being acted on.
  Machine get current =>
      _machines.firstWhere((machine) => machine.name == _selected,
          orElse: () => _machines.isEmpty ? Machine.local() : _machines.first);

  /// The fleet of the machine being acted on.
  FleetModel get fleet => of(current);

  /// The fleet of one machine, whether or not it is the one being acted on.
  FleetModel of(Machine machine) => _watching[machine.name]!;

  /// How many machines are not answering.
  int get unreachable => _watching.values
      .where((fleet) => fleet.reachability == Reachability.unreachable)
      .length;

  /// Reads the machines an earlier run stored and opens all of them.
  Future<void> load() async {
    final stored = await _settings.machines();
    _machines
      ..clear()
      ..addAll(stored.isEmpty ? <Machine>[Machine.local()] : stored);
    _selected ??= _machines.first.name;
    for (final machine in _machines) {
      _open(machine);
    }
    _notify();
  }

  /// Adds a machine and opens it. Adding never changes which one is being acted on.
  Future<void> add(Machine machine) async {
    if (_machines.any((each) => each.name == machine.name)) return;
    _machines.add(machine);
    _open(machine);
    await _remember();
    _notify();
  }

  /// Forgets a machine, closing what was watching it.
  ///
  /// Forgetting the one being acted on moves to another rather than leaving nothing selected: a
  /// frame with no machine behind it has nothing to say and no way to say why.
  Future<void> forget(Machine machine) async {
    if (_machines.length == 1) return;
    _machines.remove(machine);
    _watching.remove(machine.name)?.dispose();
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

  void _open(Machine machine) {
    final fleet = FleetModel(_reach(machine))..addListener(_notify);
    _watching[machine.name] = fleet;
    unawaited(fleet.connect());
  }

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
