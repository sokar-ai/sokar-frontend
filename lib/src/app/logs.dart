import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';

/// One log of one task, followed as it is written.
///
/// **The subscription lives here, not in the view.** Leaving a log open in another pane must not
/// stop it, and coming back must not mean having missed what it said — the same rule the session
/// record follows, for the same reason.
class LogTail {
  /// Constructor taking which log of which task this is.
  LogTail({required this.task, required this.log});

  /// The container the log belongs to.
  final String task;

  /// The file within that task's state directory.
  final String log;

  /// Everything read so far, in order.
  final List<String> lines = <String>[];

  /// Whether new output is being appended as it arrives.
  ///
  /// Suspending stops the *view* moving, never the reading: the lines keep accumulating so that
  /// resuming shows what was written meanwhile rather than a gap.
  bool following = true;

  /// Why it stopped, or null while it is being read.
  ///
  /// `NoSuchLog` lands here: naming a log a task does not have is an answer, not a failure of the
  /// interface, and it is the answer somebody gets while looking for the right name.
  String? problem;

  /// Whether it is still being read.
  bool get live => problem == null;
}

/// Every log this session has opened, and what it has read.
class Logs extends ChangeNotifier {
  final Map<String, LogTail> _open = <String, LogTail>{};
  final Map<String, StreamSubscription<List<String>>> _reading =
      <String, StreamSubscription<List<String>>>{};
  bool _disposed = false;

  /// What has been opened, oldest first.
  List<LogTail> get all => List<LogTail>.unmodifiable(_open.values);

  /// One that is already open, or null.
  LogTail? find(String task, String log) => _open[_keyOf(task, log)];

  /// Opens a log, or hands back the one already open on it.
  LogTail open(FleetBackend backend, String task, String log) {
    final key = _keyOf(task, log);
    final already = _open[key];
    if (already != null) return already;

    final tail = LogTail(task: task, log: log);
    _open[key] = tail;
    _reading[key] = backend.tailLog(task, log).listen(
      (lines) {
        tail.lines.addAll(lines);
        _notify();
      },
      onError: (Object error) {
        tail.problem = _wordsFor(error, task, log);
        _stopReading(key);
        _notify();
      },
      onDone: () {
        // A log that ends is a log that has been fully read, not one that failed.
        _stopReading(key);
        _notify();
      },
    );
    _notify();
    return tail;
  }

  /// Stops the view moving with the output, without stopping the reading.
  void follow(LogTail tail, {required bool following}) {
    if (tail.following == following) return;
    tail.following = following;
    _notify();
  }

  /// Closes one and forgets what it read.
  void close(LogTail tail) {
    final key = _keyOf(tail.task, tail.log);
    _stopReading(key);
    _open.remove(key);
    _notify();
  }

  static String _wordsFor(Object error, String task, String log) {
    if (error is VarlinkException && error.simpleName == 'NoSuchLog') {
      return '$task has no log called "$log".';
    }
    if (error is FeatureNotSupported) return '$error';
    if (error is VarlinkDisconnected) return 'Lost contact while reading: ${error.message}';
    return '$error';
  }

  static String _keyOf(String task, String log) => '$task/$log';

  void _stopReading(String key) {
    _reading.remove(key)?.cancel();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _reading.values) {
      subscription.cancel();
    }
    _reading.clear();
    super.dispose();
  }
}
