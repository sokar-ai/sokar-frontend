import 'dart:async';

import 'package:flutter/foundation.dart';

/// Where a long operation got to.
enum OperationState {
  /// Still going.
  running,

  /// Finished, and did what it said.
  succeeded,

  /// Finished, and did not. The output says why.
  failed,
}

/// One long operation the interface started, and everything it produced.
///
/// Builds, synchronisations and setup run for minutes and print a great deal. The output is kept
/// here rather than on screen, so that leaving the view does not lose it and arriving late does
/// not mean having missed it.
class Operation {
  /// Constructor taking what it is and when it began.
  Operation({required this.id, required this.title, required this.startedAt});

  /// Identifies it for the life of the session.
  final String id;

  /// What it is, in words, for somebody reading the list an hour later.
  final String title;

  /// When it began.
  final DateTime startedAt;

  /// When it stopped, or null while it is still going.
  DateTime? finishedAt;

  /// Where it got to.
  OperationState state = OperationState.running;

  /// What became of it, in the same words whether it worked or not.
  String summary = 'Running.';

  /// Everything it printed, in order.
  final List<String> output = <String>[];

  /// Whether it is still going.
  bool get running => state == OperationState.running;

  /// Whether it finished badly. Reported in the same place success would have been.
  bool get failed => state == OperationState.failed;
}

/// Every long operation started in this session, in the order they were started.
///
/// The session record is what makes an unattended machine reviewable: somebody comes back after
/// an hour and needs to know what happened, in order, without having watched.
///
/// **The subscription lives here, not in a view.** That is the whole point of the class: closing
/// the window onto an operation must not stop it, and nothing that is watched should have to stay
/// watched.
class Operations extends ChangeNotifier {
  final List<Operation> _all = <Operation>[];
  final Map<String, StreamSubscription<String>> _running =
      <String, StreamSubscription<String>>{};
  int _counted = 0;
  bool _disposed = false;

  /// Everything started in this session, oldest first.
  List<Operation> get all => List<Operation>.unmodifiable(_all);

  /// How many are still going.
  int get running => _all.where((operation) => operation.running).length;

  /// The most recently started one, or null when nothing has run.
  Operation? get latest => _all.isEmpty ? null : _all.last;

  /// One by [id], or null when this session never had it.
  Operation? byId(String id) {
    for (final operation in _all) {
      if (operation.id == id) return operation;
    }
    return null;
  }

  /// Starts one, recording what [output] prints until it ends.
  ///
  /// The stream completing is success and the stream erroring is failure — which is how a
  /// non-zero exit reaches here, because the thing that knows what an exit code means is the
  /// caller and not this.
  Operation run({required String title, required Stream<String> output}) {
    final operation = Operation(
      id: 'operation-${++_counted}',
      title: title,
      startedAt: DateTime.now(),
    );
    _all.add(operation);

    _running[operation.id] = output.listen(
      (line) {
        operation.output.add(line);
        _notify();
      },
      onError: (Object error) => _finish(
        operation,
        OperationState.failed,
        // Failure is reported as failure and in words, never as a silent stop.
        '$error',
      ),
      onDone: () {
        // onError already settled it; a stream may do both.
        if (operation.running) {
          _finish(operation, OperationState.succeeded, 'Finished.');
        }
      },
    );

    _notify();
    return operation;
  }

  void _finish(Operation operation, OperationState state, String summary) {
    operation.state = state;
    operation.summary = summary;
    operation.finishedAt = DateTime.now();
    _running.remove(operation.id)?.cancel();
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _running.values) {
      subscription.cancel();
    }
    _running.clear();
    super.dispose();
  }
}
