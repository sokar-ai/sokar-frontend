import 'package:flutter/foundation.dart';

/// A place in the product, reached from the rail.
///
/// What needs a person on every machine, or one machine with everything on it. An action lives
/// where it acts, and the finder goes there and shows it.
enum Section {
  /// What needs a person, from every machine at once. The window opens here.
  attention('Needs you'),

  /// One machine: its projects, its work and what it ran. Which one is `Machines.current`.
  machine('Machine');

  const Section(this.label);

  /// What the rail calls it.
  final String label;
}

/// What is open over the frame.
///
/// A closed set rather than a flag per thing: the frame is the one place everything opens over,
/// and a boolean per screen becomes a set of states that contradict each other the moment there
/// are three of them.
sealed class Opened {
  const Opened();
}

/// The frame itself, with nothing over it.
class NothingOpened extends Opened {
  /// Constructor.
  const NothingOpened();
}

/// One piece of work.
class WorkOpened extends Opened {
  /// Constructor.
  const WorkOpened();
}

/// What one operation printed.
class OperationOpened extends Opened {
  /// Constructor taking which one.
  const OperationOpened(this.id);

  /// The operation's id.
  final String id;
}

/// What is waiting at a project's gate.
class GateOpened extends Opened {
  /// Constructor.
  const GateOpened();
}

/// What a project's work may reach.
class EgressOpened extends Opened {
  /// Constructor.
  const EgressOpened();
}

/// What the protected store holds.
class VaultOpened extends Opened {
  /// Constructor.
  const VaultOpened();
}

/// What has been backed up of a project's mirror.
class BackupsOpened extends Opened {
  /// Constructor.
  const BackupsOpened();
}

/// Which providers this machine has.
class ProvidersOpened extends Opened {
  /// Constructor.
  const ProvidersOpened();
}

/// Whether this machine can run anything.
class ReadinessOpened extends Opened {
  /// Constructor.
  const ReadinessOpened();
}

/// What agents are installed on this machine.
class AgentsOpened extends Opened {
  /// Constructor.
  const AgentsOpened();
}

/// A new project being described, on the machine it will live on.
class ProjectCreationOpened extends Opened {
  /// Constructor.
  const ProjectCreationOpened();
}

/// What this session ran on the machine.
class OperationsOpened extends Opened {
  /// Constructor.
  const OperationsOpened();
}

/// One waiting push, being judged.
class ReviewOpened extends Opened {
  /// Constructor.
  const ReviewOpened();
}

/// One of a task's logs.
class LogOpened extends Opened {
  /// Constructor taking which log of which task.
  const LogOpened(this.task, this.log);

  /// The container.
  final String task;

  /// The file within its state directory.
  final String log;
}

/// The frame's own state: where you are, what is open, and what the finder is showing.
///
/// Separate from the backend's state on purpose. Losing contact with a daemon must not move
/// anybody, and opening something must not ask the daemon anything.
class ShellModel extends ChangeNotifier {
  Section _section = Section.attention;
  Opened _opened = const NothingOpened();
  String? _highlight;
  final Set<String> _collapsed = <String>{};

  /// Where in the product you are.
  Section get section => _section;

  /// What is open over the frame.
  Opened get opened => _opened;

  /// Whether anything is open over the frame.
  bool get anythingOpen => _opened is! NothingOpened;

  /// Whether the open thing is a piece of work.
  bool get detailOpen => _opened is WorkOpened;

  /// The command the finder went to, marked where it lives until something else happens.
  String? get highlight => _highlight;

  /// Whether a machine's projects are shown under it on the left. Open until somebody closes it.
  bool isExpanded(String machine) => !_collapsed.contains(machine);

  /// Shows a machine's projects under it, or hides them.
  void setExpanded(String machine, {required bool expanded}) {
    final changed = expanded ? _collapsed.remove(machine) : _collapsed.add(machine);
    if (changed) notifyListeners();
  }

  /// Goes to a section, closing whatever was open over the one before.
  void goTo(Section section) {
    if (_section == section && !anythingOpen && _highlight == null) return;
    _section = section;
    _opened = const NothingOpened();
    _highlight = null;
    notifyListeners();
  }

  /// Shows where [command] lives: on the machine, with nothing open over it.
  void show(String command) {
    _section = Section.machine;
    _opened = const NothingOpened();
    _highlight = command;
    notifyListeners();
  }

  /// Stops marking where a command lives.
  void shown() {
    if (_highlight == null) return;
    _highlight = null;
    notifyListeners();
  }

  /// Opens the selected work over whatever is showing.
  void openDetail() => _open(const WorkOpened());

  /// Opens what one operation printed.
  void openOperation(String id) => _open(OperationOpened(id));

  /// Opens the description of a new project.
  void openProjectCreation() => _open(const ProjectCreationOpened());

  /// Opens what this session ran on the machine.
  void openOperations() => _open(const OperationsOpened());

  /// Opens one of a task's logs.
  void openLog(String task, String log) => _open(LogOpened(task, log));

  /// Opens what is waiting at the selected project's gate.
  void openGate() => _open(const GateOpened());

  /// Opens the push being judged.
  void openReview() => _open(const ReviewOpened());

  /// Opens what the selected project's work may reach.
  void openEgress() => _open(const EgressOpened());

  /// Opens what agents are installed here.
  void openAgents() => _open(const AgentsOpened());

  /// Opens whether this machine can run anything.
  void openReadiness() => _open(const ReadinessOpened());

  /// Opens which providers this machine has.
  void openProviders() => _open(const ProvidersOpened());

  /// Opens what has been backed up of the selected project.
  void openBackups() => _open(const BackupsOpened());

  /// Opens what the protected store holds.
  void openVault() => _open(const VaultOpened());

  /// Closes whatever is open. The selection is untouched, so nobody loses their place.
  void close() {
    if (!anythingOpen) return;
    _opened = const NothingOpened();
    notifyListeners();
  }

  void _open(Opened what) {
    final open = _opened;
    final same = switch ((open, what)) {
      (OperationOpened(:final id), OperationOpened(id: final next)) => id == next,
      (LogOpened(:final task, :final log), LogOpened(task: final t, log: final l)) =>
        task == t && log == l,
      (OperationOpened() || LogOpened(), _) => false,
      _ => open.runtimeType == what.runtimeType,
    };
    if (same && _highlight == null) return;
    _opened = what;
    _highlight = null;
    notifyListeners();
  }
}
