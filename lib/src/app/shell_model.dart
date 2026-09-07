import 'package:flutter/foundation.dart';

/// A place in the product, reached from the rail.
///
/// Sections are *where you are*; the menu bar is *what you can do*; the command finder is how you
/// find one quickly. Three surfaces over one list of actions, each answering a different question
/// — which is why none of them is redundant.
enum Section {
  /// The projects on the machine and the work under them. The daily loop.
  work('Work'),

  /// Everything this session has run.
  operations('This session'),

  /// Blocked connections waiting for an answer.
  clearance('Blocked');

  const Section(this.label);

  /// What the rail calls it.
  final String label;
}

/// Which part of the frame the person is working in.
enum Pane {
  /// The projects on the machine.
  projects,

  /// The work under the selected project.
  work,

  /// Whatever is open over the frame.
  opened,
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

/// The frame's own state: where you are, what is open and where the keyboard is.
///
/// Separate from the backend's state on purpose. Losing contact with a daemon must not move
/// anybody's cursor, and opening something must not ask the daemon anything.
class ShellModel extends ChangeNotifier {
  Section _section = Section.work;
  Pane _pane = Pane.projects;
  Pane _cameFrom = Pane.projects;
  Opened _opened = const NothingOpened();

  /// Where in the product you are.
  Section get section => _section;

  /// Where the keyboard is.
  Pane get pane => _pane;

  /// What is open over the frame.
  Opened get opened => _opened;

  /// Whether anything is open over the frame.
  bool get anythingOpen => _opened is! NothingOpened;

  /// Whether the open thing is a piece of work.
  bool get detailOpen => _opened is WorkOpened;

  /// Goes to a section.
  ///
  /// Closes whatever was open over the frame: what is open belongs to where it was opened from,
  /// and carrying it to another section would leave somebody looking at a task detail over a
  /// screen that has nothing to do with it.
  void goTo(Section section) {
    if (_section == section && !anythingOpen) return;
    _section = section;
    _opened = const NothingOpened();
    _pane = section == Section.work ? _cameFrom : Pane.opened;
    notifyListeners();
  }

  /// Moves the keyboard to a pane.
  void focus(Pane pane) {
    if (_pane == pane) return;
    _pane = pane;
    notifyListeners();
  }

  /// Opens the selected work over whatever is showing.
  void openDetail() => _open(const WorkOpened());

  /// Opens what one operation printed.
  void openOperation(String id) => _open(OperationOpened(id));

  /// Opens one of a task's logs.
  void openLog(String task, String log) => _open(LogOpened(task, log));

  /// Opens what is waiting at the selected project's gate.
  void openGate() => _open(const GateOpened());

  /// Opens the push being judged.
  void openReview() => _open(const ReviewOpened());

  /// Closes whatever is open and hands the keyboard back to where it came from.
  ///
  /// The selection is deliberately untouched: coming back to a list with nothing selected is how
  /// people lose their place, which is the whole thing this frame exists to prevent.
  void close() {
    if (!anythingOpen) return;
    _opened = const NothingOpened();
    _pane = _section == Section.work ? _cameFrom : Pane.opened;
    notifyListeners();
  }

  void _open(Opened what) {
    if (_opened is OperationOpened && what is OperationOpened) {
      if ((_opened as OperationOpened).id == what.id) return;
    } else if (_opened is LogOpened && what is LogOpened) {
      final open = _opened as LogOpened;
      if (open.task == what.task && open.log == what.log) return;
    } else if (_opened.runtimeType == what.runtimeType && _pane == Pane.opened) {
      return;
    }
    if (!anythingOpen) _cameFrom = _pane;
    _opened = what;
    _pane = Pane.opened;
    notifyListeners();
  }
}
