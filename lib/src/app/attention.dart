import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_model.dart';
import 'machines.dart';

/// Why a tile sits where it does. Earlier is more urgent.
enum Demand {
  /// A question is open, or the task says it waits on one. It has a deadline.
  question,

  /// A machine that cannot be reached, which may be hiding a question.
  unreachable,

  /// Its own work waits at the gate. No deadline, and it can sit for days.
  gate,

  /// Producing output.
  working,

  /// Quiet, as far as anything can tell. A guess.
  quiet,

  /// Up, and nothing on this side can see what it is doing.
  unseen,

  /// Not running.
  stopped,
}

/// One tile: a piece of work, or a machine that cannot say what it holds.
@immutable
class Tile {
  /// Constructor taking what the tile is about.
  const Tile({
    required this.machine,
    required this.fleet,
    required this.demand,
    this.task,
    this.questions = const <Prompt>[],
  });

  /// Which machine it belongs to. On the tile, never a mode of the window.
  final Machine machine;

  /// That machine's model, which answers for it.
  final FleetModel fleet;

  /// Why it sits where it does.
  final Demand demand;

  /// The work, or null for a machine that cannot be reached or a question the list has not
  /// caught up with.
  final Task? task;

  /// Questions open for this work, oldest first.
  final List<Prompt> questions;

  /// Whether what the tile says is a guess rather than something the machine knows.
  bool get inferred => demand == Demand.quiet;
}

/// Everything that might need a person, from every machine at once, most urgent first.
///
/// **Read from the models that already exist, never from a stream of its own.** Each machine's
/// [FleetModel] watches its tasks and its [Clearance] watches its questions; a second subscription
/// here would be two answers to one question.
class Attention extends ChangeNotifier {
  /// Constructor taking the machines to read across.
  Attention(this._machines) {
    _machines.addListener(_follow);
    _follow();
  }

  final Machines _machines;
  final Set<Listenable> _following = <Listenable>{};

  /// Every tile, most urgent first.
  List<Tile> get tiles {
    final machines = _machines.all;
    final out = <Tile>[];
    for (var i = 0; i < machines.length; i++) {
      final machine = machines[i];
      // One node reached two ways would deliver every question twice.
      final twin = _machines.sameNodeAs(machine).any((other) {
        final at = machines.indexOf(other);
        return at >= 0 && at < i;
      });
      if (twin) continue;

      final fleet = _machines.of(machine);
      if (fleet.reachability != Reachability.connected) {
        out.add(Tile(machine: machine, fleet: fleet, demand: Demand.unreachable));
        continue;
      }

      final asked = <String, List<Prompt>>{};
      for (final prompt in fleet.clearance.waiting) {
        asked.putIfAbsent(prompt.task, () => <Prompt>[]).add(prompt);
      }
      for (final task in fleet.tasks) {
        final questions = asked.remove(task.name) ?? const <Prompt>[];
        out.add(Tile(
          machine: machine,
          fleet: fleet,
          demand: demandOf(task, questions),
          task: task,
          questions: questions,
        ));
      }
      // A question can arrive before the list names its task. It is shown, not held back.
      for (final questions in asked.values) {
        out.add(Tile(
          machine: machine,
          fleet: fleet,
          demand: Demand.question,
          questions: questions,
        ));
      }
    }
    return out..sort(_byDemand);
  }

  /// How many tiles need somebody now: an open question, or a machine that cannot say.
  int get needingSomebody => tiles
      .where((tile) => tile.demand == Demand.question || tile.demand == Demand.unreachable)
      .length;

  /// Why one piece of work sits where it does.
  static Demand demandOf(Task task, List<Prompt> questions) {
    if (questions.isNotEmpty || task.activity == Activity.waiting) return Demand.question;
    if (task.hasWorkWaiting) return Demand.gate;
    if (task.activity == Activity.dead || !task.running) return Demand.stopped;
    return switch (task.activity.name) {
      'WORKING' => Demand.working,
      'IDLE' => Demand.quiet,
      _ => Demand.unseen,
    };
  }

  static int _byDemand(Tile a, Tile b) {
    final byDemand = a.demand.index.compareTo(b.demand.index);
    if (byDemand != 0) return byDemand;
    // Oldest question first: it is the one nearest its machine giving up.
    final byAge = _oldest(a).compareTo(_oldest(b));
    if (byAge != 0) return byAge;
    final byMachine = a.machine.name.compareTo(b.machine.name);
    if (byMachine != 0) return byMachine;
    return (a.task?.name ?? '').compareTo(b.task?.name ?? '');
  }

  static String _oldest(Tile tile) => tile.questions.isNotEmpty
      ? tile.questions.first.at
      : tile.demand == Demand.question
          ? tile.task?.since ?? ''
          : '';

  void _follow() {
    final wanted = <Listenable>{
      for (final machine in _machines.all) ...<Listenable>[
        _machines.of(machine),
        _machines.of(machine).clearance,
      ],
    };
    for (final gone in _following.difference(wanted)) {
      gone.removeListener(notifyListeners);
    }
    for (final added in wanted.difference(_following)) {
      added.addListener(notifyListeners);
    }
    _following
      ..clear()
      ..addAll(wanted);
    notifyListeners();
  }

  @override
  void dispose() {
    _machines.removeListener(_follow);
    for (final each in _following) {
      each.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
