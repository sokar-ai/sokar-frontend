import 'package:flutter/foundation.dart';

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

/// Everything this session has run.
class OperationsOpened extends Opened {
  /// Constructor.
  const OperationsOpened();
}

/// What one operation printed.
class OperationOpened extends Opened {
  /// Constructor taking which one.
  const OperationOpened(this.id);

  /// The operation's id.
  final String id;
}

/// The frame's own state: what is open and where the keyboard is.
///
/// Separate from the backend's state on purpose. Losing contact with a daemon must not move
/// anybody's cursor, and opening something must not ask the daemon anything.
class ShellModel extends ChangeNotifier {
  Pane _pane = Pane.projects;
  Pane _cameFrom = Pane.projects;
  Opened _opened = const NothingOpened();

  /// Where the keyboard is.
  Pane get pane => _pane;

  /// What is open over the frame.
  Opened get opened => _opened;

  /// Whether anything is open over the frame.
  bool get anythingOpen => _opened is! NothingOpened;

  /// Whether the open thing is a piece of work.
  bool get detailOpen => _opened is WorkOpened;

  /// Moves the keyboard to a pane.
  void focus(Pane pane) {
    if (_pane == pane) return;
    _pane = pane;
    notifyListeners();
  }

  /// Opens the selected work over whatever is showing.
  void openDetail() => _open(const WorkOpened());

  /// Opens the session's record of what it has run.
  void openOperations() => _open(const OperationsOpened());

  /// Opens what one operation printed.
  void openOperation(String id) => _open(OperationOpened(id));

  /// Closes whatever is open and hands the keyboard back to where it came from.
  ///
  /// The selection is deliberately untouched: coming back to a list with nothing selected is how
  /// people lose their place, which is the whole thing this frame exists to prevent.
  void close() {
    if (!anythingOpen) return;
    _opened = const NothingOpened();
    _pane = _cameFrom;
    notifyListeners();
  }

  void _open(Opened what) {
    if (_opened.runtimeType == what.runtimeType && _pane == Pane.opened) {
      if (what is! OperationOpened) return;
      if ((_opened as OperationOpened).id == what.id) return;
    }
    if (!anythingOpen) _cameFrom = _pane;
    _opened = what;
    _pane = Pane.opened;
    notifyListeners();
  }
}
