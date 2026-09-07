import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'varlink_exception.dart';

/// One connection to a varlink service over a unix socket.
///
/// The whole protocol is here, and it is small: a JSON object per message, a NUL byte between
/// them, no length prefix and no request ids. Because there are no ids, **a connection carries one
/// call at a time** - so a stream gets its own connection, which costs nothing.
class VarlinkConnection {
  final Socket _socket;
  final StreamController<Map<String, dynamic>> _replies =
      StreamController<Map<String, dynamic>>();

  VarlinkConnection._(this._socket) {
    final buffer = BytesBuilder();
    _socket.listen(
      (chunk) {
        for (final byte in chunk) {
          if (byte != 0) {
            buffer.addByte(byte);
            continue;
          }
          final text = utf8.decode(buffer.takeBytes());
          _replies.add(jsonDecode(text) as Map<String, dynamic>);
        }
      },
      onError: (Object error) => _replies.addError(VarlinkDisconnected('$error')),
      onDone: _replies.close,
      cancelOnError: true,
    );
  }

  /// Opens a connection to the service listening on [socketPath].
  ///
  /// Throws [VarlinkDisconnected] rather than a platform error, because "there is no daemon
  /// there" and "the tunnel dropped" are the same thing to whatever has to render it.
  static Future<VarlinkConnection> open(String socketPath) async {
    try {
      final socket = await Socket.connect(
          InternetAddress(socketPath, type: InternetAddressType.unix), 0);
      return VarlinkConnection._(socket);
    } on SocketException catch (ex) {
      throw VarlinkDisconnected('cannot reach $socketPath: ${ex.message}');
    }
  }

  /// How long a single call may go unanswered before it is treated as a lost backend.
  ///
  /// A backend that accepts a connection and then says nothing is indistinguishable from one
  /// answering slowly, and an interface that waited on it forever would sit saying it was
  /// connecting with no way out. Generous, because stopping a task can genuinely take a while;
  /// finite, because "no answer" has to become an answer eventually.
  static const answerWithin = Duration(seconds: 30);

  /// Sends one call and returns its single reply.
  ///
  /// Only for calls that answer once. A stream deliberately has no deadline here: `Prompts` may
  /// legitimately have nothing to say for hours, and a timeout on it would report a working
  /// backend as a broken one.
  Future<Map<String, dynamic>> call(String method,
      [Map<String, dynamic> parameters = const {},
      Duration timeout = answerWithin]) async {
    _send(method, parameters, more: false);
    try {
      await for (final reply in _replies.stream.timeout(timeout)) {
        return _parameters(reply);
      }
    } on TimeoutException {
      throw VarlinkDisconnected(
          '$method was not answered within ${timeout.inSeconds} seconds');
    }
    throw const VarlinkDisconnected('the connection closed before the call was answered');
  }

  /// Sends one call and returns every reply it produces.
  ///
  /// The stream ends when the service sends a reply without `continues`, or when the connection
  /// goes away - the latter as an error, never as a quiet completion. A stream that ends silently
  /// is indistinguishable from one with nothing to say, and that is how a truncated answer gets
  /// read as an empty machine.
  Stream<Map<String, dynamic>> callMore(String method,
      [Map<String, dynamic> parameters = const {}]) async* {
    _send(method, parameters, more: true);
    await for (final reply in _replies.stream) {
      yield _parameters(reply);
      if (reply['continues'] != true) return;
    }
    throw const VarlinkDisconnected('the stream ended without a final reply');
  }

  void _send(String method, Map<String, dynamic> parameters, {required bool more}) {
    final call = <String, dynamic>{'method': method, 'parameters': parameters};
    if (more) call['more'] = true;
    _socket.add(utf8.encode(jsonEncode(call)));
    _socket.add(const [0]);
  }

  static Map<String, dynamic> _parameters(Map<String, dynamic> reply) {
    final error = reply['error'];
    if (error is String) {
      final parameters = reply['parameters'];
      throw VarlinkException(
          error, parameters is Map<String, dynamic> ? parameters : const {});
    }
    final parameters = reply['parameters'];
    return parameters is Map<String, dynamic> ? parameters : const {};
  }

  /// Closes the connection.
  Future<void> close() async {
    await _socket.close();
    _socket.destroy();
  }
}
