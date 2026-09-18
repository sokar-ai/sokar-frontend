import 'dart:io';

/// Runs a program and answers what it printed, the way [Process.run] does, with optional input.
typedef RunWith = Future<ProcessResult> Function(List<String> command, {String? input});

/// What is known about a machine's host key before anything logs in.
class HostKeyCheck {
  /// Constructor taking what was found.
  const HostKeyCheck({
    required this.destination,
    required this.host,
    required this.known,
    this.scanned = const <String>[],
    this.fingerprints = const <String>[],
    this.problem,
  });

  /// What was asked about: `user@host`, a host, or an alias from `~/.ssh/config`.
  final String destination;

  /// The host as `known_hosts` names it: `host`, or `[host]:port` off port 22.
  final String host;

  /// Whether `known_hosts` already holds a key for it.
  final bool known;

  /// The keys the host offered, as `ssh-keyscan` printed them, ready to append.
  final List<String> scanned;

  /// What the person compares: one line per key, with its type and SHA256 fingerprint.
  final List<String> fingerprints;

  /// Why nothing could be found, in words, or null.
  final String? problem;
}

/// Confirming a machine's host key before the first login, **never silently**.
///
/// Every connection here runs with `BatchMode=yes`, so an unknown host key is a failure rather than
/// a prompt — and accepting it blind would be the one step a man in the middle needs. So the key
/// is fetched, its fingerprints are shown, and only a person's yes writes it to `known_hosts`.
abstract interface class HostKeys {
  /// What is known about [destination]'s host key, fetching the keys it offers when none is known.
  Future<HostKeyCheck> check(String destination);

  /// Writes the keys a person accepted to `known_hosts`.
  Future<void> accept(HostKeyCheck check);
}

/// Host keys through OpenSSH's own tools, so an alias, a port or a `known_hosts` elsewhere in the
/// person's ssh config is honoured exactly as `ssh` itself will honour it.
class SshHostKeys implements HostKeys {
  /// Constructor, optionally with what runs a program and whose home `~/.ssh` is in.
  SshHostKeys({RunWith? run, String? home})
      : _run = run ?? _runForReal,
        _home = home ?? Platform.environment['HOME'] ?? '';

  final RunWith _run;
  final String _home;

  static Future<ProcessResult> _runForReal(List<String> command, {String? input}) async {
    if (input == null) return Process.run(command.first, command.sublist(1));
    final process = await Process.start(command.first, command.sublist(1));
    process.stdin.write(input);
    await process.stdin.close();
    final out = await process.stdout.transform(const SystemEncoding().decoder).join();
    final err = await process.stderr.transform(const SystemEncoding().decoder).join();
    return ProcessResult(process.pid, await process.exitCode, out, err);
  }

  @override
  Future<HostKeyCheck> check(String destination) async {
    // What ssh will actually connect to: the alias resolved, the port, and where it looks.
    final config = await _run(<String>['ssh', '-G', destination]);
    if (config.exitCode != 0) {
      return HostKeyCheck(
        destination: destination,
        host: destination,
        known: false,
        problem: 'ssh could not read its configuration for $destination: '
            '${'${config.stderr}'.trim()}',
      );
    }
    final settings = <String, String>{};
    for (final line in '${config.stdout}'.split('\n')) {
      final space = line.indexOf(' ');
      if (space > 0) settings.putIfAbsent(line.substring(0, space), () => line.substring(space + 1));
    }
    final hostname = settings['hostname'] ?? destination;
    final port = settings['port'] ?? '22';
    final host = port == '22' ? hostname : '[$hostname]:$port';
    final files = (settings['userknownhostsfile'] ?? '~/.ssh/known_hosts').split(' ');
    for (final named in files) {
      // `ssh -G` expands a home it knows, but nothing here runs a shell to expand one it left.
      final file = named.startsWith('~/') ? '$_home${named.substring(1)}' : named;
      final found = await _run(<String>['ssh-keygen', '-F', host, '-f', file]);
      if (found.exitCode == 0) {
        return HostKeyCheck(destination: destination, host: host, known: true);
      }
    }
    final scan = await _run(<String>['ssh-keyscan', '-T', '10', '-H', '-p', port, hostname]);
    final scanned = <String>[
      for (final line in '${scan.stdout}'.split('\n'))
        if (line.trim().isNotEmpty && !line.startsWith('#')) line.trim(),
    ];
    if (scanned.isEmpty) {
      return HostKeyCheck(
        destination: destination,
        host: host,
        known: false,
        problem: 'No host key came back from $host. Is it reachable, and is ssh running there?',
      );
    }
    final printed = await _run(<String>['ssh-keygen', '-l', '-f', '-'], input: '${scanned.join('\n')}\n');
    return HostKeyCheck(
      destination: destination,
      host: host,
      known: false,
      scanned: scanned,
      fingerprints: <String>[
        for (final line in '${printed.stdout}'.split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
      ],
    );
  }

  @override
  Future<void> accept(HostKeyCheck check) async {
    final ssh = Directory('$_home/.ssh');
    if (!ssh.existsSync()) {
      ssh.createSync(recursive: true);
      await _run(<String>['chmod', '700', ssh.path]);
    }
    final file = File('${ssh.path}/known_hosts');
    final existed = file.existsSync();
    file.writeAsStringSync('${check.scanned.join('\n')}\n', mode: FileMode.append, flush: true);
    if (!existed) await _run(<String>['chmod', '600', file.path]);
  }
}
