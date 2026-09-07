import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A stand-in for `sokard`, speaking real varlink over a real unix socket.
///
/// **Not scaffolding until the backend is ready.** It is permanent, because it produces states a
/// real daemon cannot be made to produce on demand, and those are the hard ones: a method missing
/// because the backend is older, an outcome this build has never heard of, a stream cut
/// mid-flight, a task refusing to be removed because it holds work. A real daemon always has all
/// its methods and only ever sends values it knows, so those rules are otherwise unenforceable.
///
/// It also means the suite needs no podman, no containers and no runtime - so it runs anywhere.
class MockDaemon {
  /// Interfaces this pretends to serve, in the order `GetInfo` reports them.
  ///
  /// Set it to something newer to check that a client picks the highest name it understands, or
  /// to something older to check it refuses politely.
  List<String> interfaces = const ['org.varlink.service', 'org.fuin.sokar.Tasks1'];

  /// Interface the methods below are registered under.
  String interfaceName = 'org.fuin.sokar.Tasks1';

  /// Version reported by `GetInfo`.
  String version = '0.1.0-mock';

  /// What this returns from `GetInterfaceDescription`, when anything.
  String? description;

  /// Cuts every open connection the moment the next reply would be sent.
  ///
  /// For the requirement that a lost tunnel reads as a disconnection and never as a machine with
  /// nothing running on it.
  bool severed = false;

  final Map<String, _Handler> _methods = {};
  final List<Socket> _clients = [];
  ServerSocket? _server;
  Directory? _directory;

  /// Where this is listening. Valid once [start] has completed.
  String get socketPath => _path;
  late String _path;

  /// Registers a method that answers once.
  ///
  /// The name is bare - `List`, not the full interface - and is qualified with [interfaceName],
  /// so pointing the mock at a different interface moves every method with it.
  void method(String name, FutureOr<Map<String, dynamic>> Function(Map<String, dynamic>) answer) {
    _methods['$interfaceName.$name'] = _Handler.single(answer);
  }

  /// Registers a method that streams.
  ///
  /// The test drives the events; nothing here is on a timer. A mock that emitted on wall clock
  /// makes stream tests flaky, and flaky tests get deleted rather than fixed.
  void stream(String name, Stream<Map<String, dynamic>> Function(Map<String, dynamic>) events) {
    _methods['$interfaceName.$name'] = _Handler.streaming(events);
  }

  /// Registers a method that refuses.
  void fails(String name, String error, [Map<String, dynamic> parameters = const {}]) {
    _methods['$interfaceName.$name'] = _Handler.failing(error, parameters);
  }

  /// Removes a method, so calling it answers `MethodNotFound`.
  ///
  /// This is how a backend older than the interface is simulated, and it is the only way to prove
  /// that a feature degrades instead of the whole client failing.
  void remove(String name) => _methods.remove('$interfaceName.$name');

  /// Binds the socket and starts answering.
  ///
  /// The directory is short on purpose: a unix socket path is limited to about 108 bytes on
  /// Linux, and a test harness's temporary directory can reach that on its own.
  Future<void> start() async {
    _directory = await Directory.systemTemp.createTemp('skm');
    _path = '${_directory!.path}/d.sock';
    _server = await ServerSocket.bind(
        InternetAddress(_path, type: InternetAddressType.unix), 0);
    _server!.listen(_serve);
  }

  /// Stops answering and removes the socket.
  Future<void> stop() async {
    for (final client in List<Socket>.from(_clients)) {
      client.destroy();
    }
    _clients.clear();
    await _server?.close();
    await _directory?.delete(recursive: true);
  }

  /// Methods that close the connection politely instead of answering.
  ///
  /// Different from [severConnections] and the difference matters: a destroyed socket surfaces as
  /// a socket error, while a *graceful* close mid-call surfaces as a stream simply ending. The
  /// second is the dangerous one - it looks like "nothing more to say" and would render as a
  /// machine with no tasks on it.
  final Set<String> hangUpOn = <String>{};

  /// Drops every open connection now, as a tunnel does.
  void severConnections() {
    severed = true;
    for (final client in List<Socket>.from(_clients)) {
      client.destroy();
    }
    _clients.clear();
  }

  void _serve(Socket client) {
    _clients.add(client);
    final buffer = BytesBuilder();
    client.listen(
      (chunk) {
        for (final byte in chunk) {
          if (byte != 0) {
            buffer.addByte(byte);
            continue;
          }
          final call = jsonDecode(utf8.decode(buffer.takeBytes())) as Map<String, dynamic>;
          unawaited(_handle(client, call));
        }
      },
      onError: (Object _) {},
      onDone: () => _clients.remove(client),
      cancelOnError: true,
    );
  }

  Future<void> _handle(Socket client, Map<String, dynamic> call) async {
    final method = call['method'];
    final raw = call['parameters'];
    final parameters = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

    if (method == 'org.varlink.service.GetInfo') {
      return _send(client, {
        'parameters': {
          'vendor': 'fuin.org',
          'product': 'Sokar',
          'version': version,
          'interfaces': interfaces,
        }
      });
    }
    if (method == 'org.varlink.service.GetInterfaceDescription') {
      if (description == null) {
        return _send(client, {
          'error': 'org.varlink.service.InterfaceNotFound',
          'parameters': {'interface': '${parameters['interface']}'},
        });
      }
      return _send(client, {
        'parameters': {'description': description}
      });
    }

    if (hangUpOn.contains('$method'.split('.').last)) {
      _clients.remove(client);
      await client.close();
      return;
    }

    final handler = _methods[method];
    if (handler == null) {
      return _send(client, {
        'error': 'org.varlink.service.MethodNotFound',
        'parameters': {'method': '$method'},
      });
    }
    await handler.run(parameters, call['more'] == true,
        (reply) => _send(client, reply));
  }

  void _send(Socket client, Map<String, dynamic> message) {
    if (severed) return;
    try {
      client.add(utf8.encode(jsonEncode(message)));
      client.add(const [0]);
    } on StateError {
      // The client left. That is how a cancelled stream looks from here, and it is normal.
    }
  }
}

class _Handler {
  final FutureOr<Map<String, dynamic>> Function(Map<String, dynamic>)? _single;
  final Stream<Map<String, dynamic>> Function(Map<String, dynamic>)? _events;
  final String? _error;
  final Map<String, dynamic> _errorParameters;

  _Handler.single(this._single)
      : _events = null,
        _error = null,
        _errorParameters = const {};

  _Handler.streaming(this._events)
      : _single = null,
        _error = null,
        _errorParameters = const {};

  _Handler.failing(this._error, this._errorParameters)
      : _single = null,
        _events = null;

  Future<void> run(Map<String, dynamic> parameters, bool more,
      void Function(Map<String, dynamic>) send) async {
    if (_error != null) {
      return send({'error': _error, 'parameters': _errorParameters});
    }
    if (_single != null) {
      return send({'parameters': await _single(parameters)});
    }
    Map<String, dynamic>? previous;
    await for (final event in _events!(parameters)) {
      if (previous != null) {
        send({'parameters': previous, 'continues': true});
      }
      previous = event;
    }
    // The last event carries no 'continues', which is what ends the stream. Holding one back is
    // the only way to know which one that is.
    send({'parameters': previous ?? const <String, dynamic>{}});
  }
}
