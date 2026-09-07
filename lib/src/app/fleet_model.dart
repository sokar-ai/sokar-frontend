import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';
import 'outcome_words.dart';

/// Whether the interface can currently reach the backend it is pointed at.
enum Reachability {
  /// Opening the socket, or asking what is there.
  connecting,

  /// Answering.
  connected,

  /// Nothing there, or the tunnel went away. Never the same thing as an empty machine.
  unreachable,

  /// Reachable, but serving no interface this build understands.
  incompatible,
}

/// One project, as far as a task list can say what a project is.
///
/// Derived from [Task.project] rather than asked for, because the backend has no method that
/// lists projects yet: a project with no tasks on it is invisible here. That is a real gap
/// rather than a simplification, and it is [F02](../../../requirements/F02-Project-Overview.md).
@immutable
class Project {
  /// Constructor taking the name and the work under it.
  const Project({required this.name, required this.tasks});

  /// Name the tasks recorded, or empty when nothing recorded one.
  final String name;

  /// Every task belonging to it, running or not.
  final List<Task> tasks;

  /// How many of them the runtime says are up.
  int get running => tasks.where((task) => task.running).length;

  /// What to call it on screen.
  String get label => name.isEmpty ? 'No project recorded' : name;

  /// The security classes its tasks run under, which is the one thing worth seeing unopened.
  List<String> get securityClasses {
    final classes = tasks
        .map((task) => task.securityClass)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return classes;
  }
}

/// Groups tasks into projects, with the unattributed ones last.
///
/// Last rather than first: a task whose project nothing recorded is the odd case, and putting
/// it at the top would push the real projects down on every machine that has one.
List<Project> projectsOf(List<Task> tasks) {
  final grouped = <String, List<Task>>{};
  for (final task in tasks) {
    grouped.putIfAbsent(task.project, () => <Task>[]).add(task);
  }
  final names = grouped.keys.toList()
    ..sort((a, b) {
      if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
      return a.compareTo(b);
    });
  return <Project>[
    for (final name in names)
      Project(name: name, tasks: grouped[name]!..sort((a, b) => a.name.compareTo(b.name))),
  ];
}

/// A `Stop` that came back refusing, and what it said.
///
/// A refusal is the product working, not an error path: it needs a real place in the interface
/// where what is held is legible and the choice about it is made deliberately. It is never
/// softened into a "force" that quietly discards somebody's afternoon.
@immutable
class Refusal {
  /// Constructor taking which task refused and what it answered.
  const Refusal({required this.task, required this.result});

  /// The task that was left exactly as it was.
  final String task;

  /// What `Stop` answered, including what the task holds.
  final Stopped result;

  /// Whether the task holds commits that never reached the gate.
  bool get holdsWork => result.outcome == Outcome.holdsWork;

  /// Whether nothing could say what it holds.
  bool get nothingKnows => result.outcome == Outcome.nothingKnows;
}

/// What the interface knows about one backend, and the selections made over it.
///
/// Everything the shell renders comes from here, so there is one place that knows whether the
/// machine is reachable — and one place that keeps the last answer when it stops being.
class FleetModel extends ChangeNotifier {
  /// Constructor taking the backend to talk to.
  ///
  /// [retryAfter] is how long to wait before trying a machine that stopped answering. A tunnel
  /// that drops has to recover without anybody restarting the interface, so this is a loop and
  /// not a button — the button is there as well, for somebody who does not want to wait.
  FleetModel(this.backend, {this.retryAfter = const Duration(seconds: 2)});

  /// Which machine this is.
  final FleetBackend backend;

  /// How long to wait before trying a machine that stopped answering.
  final Duration retryAfter;

  ServiceInfo? _info;
  StreamSubscription<List<Task>>? _watching;
  Timer? _retry;
  bool _disposed = false;

  Reachability _reachability = Reachability.connecting;
  String _status = 'Starting up.';
  bool _busy = false;
  bool _live = false;
  List<Task> _tasks = const <Task>[];
  String? _selectedProject;
  String? _selectedTask;
  Refusal? _refusal;

  /// Whether the backend is answering.
  Reachability get reachability => _reachability;

  /// The last thing that happened, in words, for the status line.
  String get status => _status;

  /// Whether something is running now. Deliberately separate from [status], which has to stay
  /// readable while it does.
  bool get busy => _busy;

  /// Whether the task list is arriving by itself. False against a backend without `Watch`.
  bool get liveUpdates => _live;

  /// What the backend said it is, once connected.
  ServiceInfo? get info => _info;

  /// Every task on the machine, as last answered.
  List<Task> get tasks => _tasks;

  /// The projects those tasks belong to.
  List<Project> get projects => projectsOf(_tasks);

  /// The selected project, or null before anything is chosen.
  Project? get selectedProject {
    final name = _selectedProject;
    if (name == null) return null;
    for (final project in projects) {
      if (project.name == name) return project;
    }
    return null;
  }

  /// The selected task, or null when none is.
  Task? get selectedTask {
    final name = _selectedTask;
    if (name == null) return null;
    for (final task in _tasks) {
      if (task.name == name) return task;
    }
    return null;
  }

  /// The work under the selected project.
  List<Task> get workInView => selectedProject?.tasks ?? const <Task>[];

  /// Opens the backend, reads what is there and follows it.
  Future<void> connect() async {
    _reachability = Reachability.connecting;
    _say('Connecting to ${backend.label}.');
    try {
      final info = await backend.open();
      _info = info;
      _retry?.cancel();
      _reachability = Reachability.connected;
      _say('Connected to ${backend.label}, ${info.product} ${info.version}.');
      await _readOnce();
      _follow();
    } on VarlinkDisconnected catch (ex) {
      _reachability = Reachability.unreachable;
      _say('Cannot reach ${backend.label}: ${ex.message}');
      _tryAgainLater();
    } on StateError catch (ex) {
      _reachability = Reachability.incompatible;
      _say(ex.message);
    }
  }

  /// Asks again now, for a backend that cannot tell us by itself.
  Future<void> refresh() async {
    if (_info == null) {
      await connect();
      return;
    }
    _busy = true;
    _notify();
    try {
      await _readOnce();
      _say('Refreshed: ${_tasks.length} ${_tasks.length == 1 ? 'task' : 'tasks'}.');
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Selects a project. Selecting never changes anything about it.
  void selectProject(String? name) {
    if (_selectedProject == name) return;
    _selectedProject = name;
    _selectedTask = null;
    _notify();
  }

  /// A `Stop` that refused, until it is answered or dismissed.
  Refusal? get refusal => _refusal;

  /// Stops a task and removes what is left of it.
  ///
  /// [purge] discards work that never reached the gate; [rescue] pushes it into the mirror
  /// first; [force] removes it when nothing can say what it holds. None of them is a default,
  /// and each is a separate thing to have decided.
  Future<void> stopWork(
    String task, {
    bool purge = false,
    bool rescue = false,
    bool force = false,
  }) async {
    await _acting(() async {
      final result = await backend.stopTask(
        task,
        purge: purge ? true : null,
        rescue: rescue ? true : null,
        force: force ? true : null,
      );
      _say(stopWords(task, result));
      _refusal = result.removed ? null : Refusal(task: task, result: result);
      await _readOnce();
    });
  }

  /// Starts a stopped task's container again.
  Future<void> resumeWork(String task) async {
    await _acting(() async {
      _say(resumeWords(task, await backend.resumeTask(task)));
      await _readOnce();
    });
  }

  /// Puts a refusal away without acting on it, leaving the task exactly as it is.
  void letItBe() {
    if (_refusal == null) return;
    _refusal = null;
    _notify();
  }

  /// Runs one action, keeping the interface honest about what happened either way.
  Future<void> _acting(Future<void> Function() action) async {
    _busy = true;
    _notify();
    try {
      await action();
    } on VarlinkDisconnected catch (ex) {
      _lostContact(ex);
    } on VarlinkException catch (ex) {
      // A named refusal from the daemon is an answer. It gets said, not swallowed.
      _say('Refused: ${ex.simpleName}.');
    } on FeatureNotSupported catch (ex) {
      _say('$ex');
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Selects a piece of work under the selected project.
  void selectTask(String? name) {
    if (_selectedTask == name) return;
    _selectedTask = name;
    _notify();
  }

  Future<void> _readOnce() async {
    try {
      _adopt(await backend.tasks());
    } on VarlinkDisconnected catch (ex) {
      _lostContact(ex);
    }
  }

  void _follow() {
    _watching?.cancel();
    _watching = backend.watch().listen(
      (tasks) {
        _live = true;
        _adopt(tasks);
      },
      onError: (Object error) {
        if (error is FeatureNotSupported) {
          // Per feature, not per connection: this backend is older, so the list stops arriving
          // by itself and everything else carries on.
          _live = false;
          _say('This backend cannot push changes; refresh to see them.');
          return;
        }
        if (error is VarlinkDisconnected) {
          _lostContact(error);
          return;
        }
        _say('Watching failed: $error');
      },
    );
  }

  void _adopt(List<Task> tasks) {
    _tasks = tasks;
    // A selection that no longer exists is dropped rather than left pointing at nothing.
    final projectNames = projects.map((project) => project.name).toSet();
    if (_selectedProject != null && !projectNames.contains(_selectedProject)) {
      _selectedProject = null;
      _selectedTask = null;
    }
    if (_selectedTask != null && !tasks.any((task) => task.name == _selectedTask)) {
      _selectedTask = null;
    }
    _notify();
  }

  void _lostContact(VarlinkDisconnected ex) {
    // The last known list is kept on purpose. Clearing it would show a machine with nothing
    // running on it, which is the one reading a lost tunnel must never produce.
    _reachability = Reachability.unreachable;
    _live = false;
    _say('Lost contact with ${backend.label}: ${ex.message}');
    _tryAgainLater();
  }

  /// Tries again on its own, so a tunnel coming back does not need anybody to notice.
  ///
  /// A cut stream is resumed rather than left dead: reconnecting reads the list again and starts
  /// watching again, which is the whole of what was lost.
  void _tryAgainLater() {
    if (_disposed || retryAfter == Duration.zero) return;
    _retry?.cancel();
    _retry = Timer(retryAfter, () {
      if (_disposed) return;
      unawaited(connect());
    });
  }

  void _say(String status) {
    _status = status;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _watching?.cancel();
    super.dispose();
  }
}
