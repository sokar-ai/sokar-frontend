import 'package:flutter/foundation.dart';

/// Which part of the frame the person is working in.
enum Pane {
  /// The projects on the machine.
  projects,

  /// The work under the selected project.
  work,

  /// One piece of work, opened over the frame.
  detail,
}

/// The frame's own state: what is open and where the keyboard is.
///
/// Separate from the backend's state on purpose. Losing contact with a daemon must not move
/// anybody's cursor, and opening a detail must not ask the daemon anything.
class ShellModel extends ChangeNotifier {
  Pane _pane = Pane.projects;
  bool _detailOpen = false;

  /// Where the keyboard is.
  Pane get pane => _pane;

  /// Whether a detail is open over the frame.
  bool get detailOpen => _detailOpen;

  /// Moves the keyboard to a pane.
  void focus(Pane pane) {
    if (_pane == pane) return;
    _pane = pane;
    notifyListeners();
  }

  /// Opens the detail over whatever is showing.
  void openDetail() {
    if (_detailOpen && _pane == Pane.detail) return;
    _detailOpen = true;
    _pane = Pane.detail;
    notifyListeners();
  }

  /// Closes the detail and hands the keyboard back to the work it was opened from.
  ///
  /// The selection is deliberately untouched: coming back to a list with nothing selected is
  /// how people lose their place, which is the whole thing this frame exists to prevent.
  void closeDetail() {
    if (!_detailOpen) return;
    _detailOpen = false;
    _pane = Pane.work;
    notifyListeners();
  }
}
