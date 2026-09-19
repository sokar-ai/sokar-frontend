import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_model.dart';
import 'machines.dart';
import 'operations.dart';
import 'settings.dart';

/// Why a tile sits where it does. Earlier is more urgent.
enum Demand {
  /// A question is open, or the task says it waits on one. It has a deadline.
  question,

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

/// One tile: a piece of work, or a question the list has not caught up with.
@immutable
class Tile {
  /// Constructor taking what the tile is about.
  const Tile({
    required this.machine,
    required this.fleet,
    required this.demand,
    this.task,
    this.questions = const <Prompt>[],
    this.settled,
  });

  /// Which machine it belongs to. On the tile, never a mode of the window.
  final Machine machine;

  /// That machine's model, which answers for it.
  final FleetModel fleet;

  /// Why it sits where it does.
  final Demand demand;

  /// The work, or null for a question the list has not caught up with.
  final Task? task;

  /// Questions open for this work, oldest first.
  final List<Prompt> questions;

  /// The last question about this work that was answered or ran out, or null.
  final Prompt? settled;

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
  Attention(this._machines, [this._settings, this._operations]) {
    _machines.addListener(_follow);
    _settings?.addListener(notifyListeners);
    _operations?.addListener(notifyListeners);
    _follow();
  }

  final Machines _machines;
  final Settings? _settings;
  final Operations? _operations;

  /// Operations a person started that failed and that nobody has opened since, oldest first.
  ///
  /// **Waiting until seen**, the operator's decision on 2026-09-13: a start that failed while its
  /// view was closed was found only by going to that machine, and nobody looked there.
  List<Operation> get failedUnseen => <Operation>[
        for (final operation in _operations?.all ?? const <Operation>[])
          if (operation.failed && !operation.seen) operation,
      ];
  final Set<Listenable> _following = <Listenable>{};

  /// Every machine that is not answering. Said about the machine, above the tiles, never as one:
  /// a machine is not work, and its silence may be hiding a question.
  List<Machine> get silent => <Machine>[
        for (final machine in _counted)
          if (_machines.of(machine).reachability != Reachability.connected &&
            !(_settings?.seenSilent.contains(machine.name) ?? false))
          machine,
      ];

  /// Every machine once: one node reached two ways would deliver every question twice.
  List<Machine> get _counted {
    final machines = _machines.all;
    return <Machine>[
      for (var i = 0; i < machines.length; i++)
        if (!_machines.sameNodeAs(machines[i]).any((other) {
          final at = machines.indexOf(other);
          return at >= 0 && at < i;
        }))
          machines[i],
    ];
  }

  /// Every followed project whose repository stopped being taken **and will stay stopped until
  /// somebody acts**, as the daemon says. Said about the project, never as a tile: it is not work,
  /// and a refused signature may be somebody putting a project file past the machine.
  List<({Machine machine, Project project, Followed followed})> get notFollowing =>
      <({Machine machine, Project project, Followed followed})>[
        for (final machine in _counted)
          for (final each in _machines.of(machine).projects)
            if (each.project.following case final followed? when followed.needsAPerson)
              (machine: machine, project: each.project, followed: followed),
      ];

  /// Stops saying that [machine] is silent, until it has answered again.
  Future<void> markSeen(Machine machine) async {
    final settings = _settings;
    if (settings == null) return;
    await settings.setSeenSilent(<String>{...settings.seenSilent, machine.name});
  }

  /// A machine that answers again is forgotten as seen, so its next silence is said.
  void _changed() {
    final settings = _settings;
    if (settings != null) {
      final answering = <String>{
        for (final machine in _machines.all)
          if (_machines.of(machine).reachability == Reachability.connected) machine.name,
      };
      final stillSilent = settings.seenSilent.difference(answering);
      if (stillSilent.length != settings.seenSilent.length) {
        // Not now: this runs while the frame is being drawn, and settings changing would redraw it.
        scheduleMicrotask(() => settings.setSeenSilent(stillSilent));
      }
    }
    notifyListeners();
  }

  /// The model of one machine.
  FleetModel fleetOf(Machine machine) => _machines.of(machine);

  /// Every tile, most urgent first.
  List<Tile> get tiles => <Tile>[
        for (final machine in _counted) ..._tilesOf(machine),
      ]..sort(_byDemand);

  /// The tiles that need a person: an open question, work waiting at the gate, or the outcome of a
  /// question that was answered or ran out and has not been put away.
  ///
  /// **What the window opens on**, decided by the operator on 2026-09-13. A list of every tile is,
  /// at fifty tasks, fifty tiles of which two need anybody — and the reason to open the window is
  /// the two. Everything else — working, quiet, unseen, stopped — is still drawn, in its machine's
  /// area, which is where somebody looking at that machine goes.
  ///
  /// **An outcome stays until it is put away**, decided the same day: a question that ran out while
  /// nobody looked would otherwise leave without a trace, and an answer's confirmation would go with
  /// the click that gave it.
  List<Tile> get needing => <Tile>[
        for (final tile in tiles)
          if (tile.demand == Demand.question ||
              tile.demand == Demand.gate ||
              tile.settled != null)
            tile,
      ];

  /// One machine's tiles, most urgent first. While it is not answering they are what it last
  /// said: a lost tunnel is a disconnection, never a machine with nothing on it.
  List<Tile> tilesOn(Machine machine) => _tilesOf(machine, evenSilent: true)..sort(_byDemand);

  List<Tile> _tilesOf(Machine machine, {bool evenSilent = false}) {
    final out = <Tile>[];
    final fleet = _machines.of(machine);
    if (evenSilent || fleet.reachability == Reachability.connected) {
      final settled = fleet.clearance.settled;
      final asked = <String, List<Prompt>>{};
      for (final prompt in fleet.clearance.waiting) {
        asked.putIfAbsent(prompt.task, () => <Prompt>[]).add(prompt);
      }
      for (final questions in asked.values) {
        questions.sort(_nearestFirst);
      }
      for (final task in fleet.tasks) {
        final questions = asked.remove(task.name) ?? const <Prompt>[];
        out.add(Tile(
          machine: machine,
          fleet: fleet,
          demand: demandOf(task, questions),
          task: task,
          questions: questions,
          settled: settled.where((each) => each.task == task.name).firstOrNull,
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
    return out;
  }

  /// How many things need somebody now: an open question, a machine that cannot say, or a failure
  /// nobody has seen.
  int get needingSomebody =>
      tiles.where((tile) => tile.demand == Demand.question).length +
      silent.length +
      failedUnseen.length +
      notFollowing.length;

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
    final byDeadline = _endOf(a).compareTo(_endOf(b));
    if (byDeadline != 0) return byDeadline;
    // Then the oldest question: without a deadline, it is the likeliest to be given up on first.
    final byAge = _oldest(a).compareTo(_oldest(b));
    if (byAge != 0) return byAge;
    final byMachine = a.machine.name.compareTo(b.machine.name);
    if (byMachine != 0) return byMachine;
    return (a.task?.name ?? '').compareTo(b.task?.name ?? '');
  }

  static final _never = DateTime.utc(9999);

  static DateTime _endOf(Tile tile) =>
      tile.questions.isEmpty ? _never : tile.questions.first.expiresAt ?? _never;

  static int _nearestFirst(Prompt a, Prompt b) {
    final byEnd = (a.expiresAt ?? _never).compareTo(b.expiresAt ?? _never);
    return byEnd != 0 ? byEnd : a.at.compareTo(b.at);
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
      gone.removeListener(_changed);
    }
    for (final added in wanted.difference(_following)) {
      added.addListener(_changed);
    }
    _following
      ..clear()
      ..addAll(wanted);
    notifyListeners();
  }

  @override
  void dispose() {
    _machines.removeListener(_follow);
    _settings?.removeListener(notifyListeners);
    _operations?.removeListener(notifyListeners);
    for (final each in _following) {
      each.removeListener(_changed);
    }
    super.dispose();
  }
}
