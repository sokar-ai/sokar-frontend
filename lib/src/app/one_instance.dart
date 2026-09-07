import 'dart:async';
import 'dart:io';

/// Keeps one interface in charge of a machine.
///
/// Two of these running is not merely untidy: each watches every configured machine, so every
/// clearance question is raised twice and answered by whichever window somebody happened to see.
/// A second launch therefore **joins** — it asks the one already running to come forward and then
/// leaves — rather than failing or competing.
///
/// A unix socket rather than a lock file, because a lock file cannot be talked to: the second
/// launch has something to say, and "come forward" is the whole of it.
class OneInstance {
  OneInstance._(this._listening, this.socketPath);

  final ServerSocket? _listening;

  /// Where the running interface listens.
  final String socketPath;

  /// Whether this process is the one in charge.
  bool get inCharge => _listening != null;

  /// Takes charge, or asks whoever already has it to come forward.
  ///
  /// [comeForward] runs when another launch asks for the window. [at] is injectable so this can be
  /// tested without fighting over the real one.
  static Future<OneInstance> take({
    required void Function() comeForward,
    String? at,
  }) async {
    final path = at ?? _besideTheRuntime();
    try {
      final listening = await ServerSocket.bind(
        InternetAddress(path, type: InternetAddressType.unix),
        0,
      );
      listening.listen((from) {
        comeForward();
        from.destroy();
      });
      return OneInstance._(listening, path);
    } on SocketException {
      // Either somebody is there, or a previous run died without tidying up. Asking settles it:
      // a socket nobody answers is a leftover, and deleting it is the only way back.
      if (await _somebodyAnswered(path)) return OneInstance._(null, path);
      try {
        File(path).deleteSync();
      } on FileSystemException {
        return OneInstance._(null, path);
      }
      return take(comeForward: comeForward, at: path);
    }
  }

  /// Stops listening and tidies up, so the next launch is not met by a leftover.
  Future<void> release() async {
    if (_listening == null) return;
    await _listening.close();
    try {
      File(socketPath).deleteSync();
    } on FileSystemException {
      // Something else removed it. Nothing to do and nothing worth saying.
    }
  }

  static Future<bool> _somebodyAnswered(String path) async {
    try {
      final socket = await Socket.connect(
        InternetAddress(path, type: InternetAddressType.unix),
        0,
        timeout: const Duration(seconds: 1),
      );
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    }
  }

  static String _besideTheRuntime() {
    final runtime = Platform.environment['XDG_RUNTIME_DIR'] ??
        '/run/user/${Process.runSync('id', const <String>['-u']).stdout.toString().trim()}';
    return '$runtime/sokar-frontend.sock';
  }
}
