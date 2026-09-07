import 'package:sokar_frontend/client.dart';

/// The backend, narrowed to what the frame asks of it.
///
/// The frame is judged on what a person sees when a backend answers, refuses or goes away, and
/// all three have to be producible in a widget test. A widget test runs on a fake clock, under
/// which a real socket makes no progress — so the wire is proven where it belongs, over a real
/// socket against the mock daemon in `test/client`, and the frame is proven against this.
///
/// It is deliberately four members wide. Anything that grows it is probably a screen reaching
/// past the frame for something it should be asking the client for directly.
abstract class FleetBackend {
  /// What to call this machine. An action must never be ambiguous about where it acts.
  String get label;

  /// Opens it and answers what it says it is.
  ///
  /// Throws [VarlinkDisconnected] when there is nothing there, and [StateError] when it serves
  /// no interface this build understands.
  Future<ServiceInfo> open();

  /// Every task on it, running or stopped.
  Future<List<Task>> tasks();

  /// The task list, again whenever it changes.
  ///
  /// Errors with [FeatureNotSupported] against a backend too old to have `Watch`, which is a
  /// reason to stop expecting changes rather than a reason to stop.
  Stream<List<Task>> watch();
}

/// A real Sokar daemon, local or forwarded.
class SokarBackend implements FleetBackend {
  /// Constructor taking where the daemon is.
  SokarBackend(this.backend);

  /// The socket and its name.
  final Backend backend;

  SokarClient? _client;

  @override
  String get label => backend.label;

  @override
  Future<ServiceInfo> open() async {
    final client = await SokarClient.connect(backend);
    _client = client;
    return client.info;
  }

  @override
  Future<List<Task>> tasks() => _opened().tasks();

  @override
  Stream<List<Task>> watch() => _opened().watchTasks();

  SokarClient _opened() {
    final client = _client;
    if (client == null) throw StateError('open() has not answered yet');
    return client;
  }
}
