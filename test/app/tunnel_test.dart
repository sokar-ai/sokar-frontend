import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/machines.dart';
import 'package:sokar_frontend/src/app/tunnel.dart';

/// Forwards this interface raises and owns.
///
/// Held against **real processes and real sockets**, with a stand-in in place of `ssh`. There is
/// no remote host to reach and there does not need to be: everything this class decides is about
/// a process that either binds a socket or dies saying why, and both are producible here. A test
/// that mocked the process away would prove the arrangement of the code and nothing about the
/// thing that goes wrong.
void main() {
  late Directory where;

  setUp(() {
    where = Directory.systemTemp.createTempSync('sokar-tunnel-test');
    addTearDown(() {
      if (where.existsSync()) where.deleteSync(recursive: true);
    });
  });

  Machine machineAt(String socket) => Machine(
        name: 'the build machine',
        socketPath: socket,
        host: 'user@build',
        remoteSocket: '/run/user/1001/sokar/sokard.sock',
      );

  /// A stand-in for `ssh` that binds the socket and stays up, as a working forward does.
  Future<Process> Function(List<String>) bindsAndStays(String socket) =>
      (_) => Process.start('sh', <String>[
            '-c',
            // A real unix socket, made by something other than this test, then held open. `nc -lU`
            // is not everywhere; a two-line python is.
            'python3 -c "'
                'import socket,time;'
                's=socket.socket(socket.AF_UNIX);'
                's.bind(\'$socket\');'
                's.listen(1);'
                'time.sleep(300)"',
          ]);

  /// A stand-in that fails the way `ssh` fails: nothing bound, a sentence on stderr, non-zero.
  Future<Process> Function(List<String>) failsSaying(String words) =>
      (_) => Process.start('sh', <String>['-c', 'echo "$words" >&2; exit 255']);

  test('a forward that binds is up, and the endpoint exists', () async {
    final socket = '${where.path}/up.sock';
    final tunnel = Tunnel(machineAt(socket), start: bindsAndStays(socket));
    addTearDown(tunnel.drop);

    await tunnel.raise();

    expect(tunnel.state, TunnelState.up);
    expect(File(socket).existsSync(), isTrue);
    expect(tunnel.problem, isNull);
  });

  test('a forward that is refused says what the transport said', () async {
    final tunnel = Tunnel(
      machineAt('${where.path}/refused.sock'),
      start: failsSaying('Host key verification failed.'),
    );

    await tunnel.raise();

    // ssh's own words. "Host key verification failed" is a different problem from a machine that
    // is not there, and reporting the second sends somebody looking in the wrong place.
    expect(tunnel.state, TunnelState.down);
    expect(tunnel.problem, contains('Host key verification failed'));
  });

  test('a command that does not exist is a refusal, not a crash', () async {
    final tunnel = Tunnel(
      machineAt('${where.path}/missing.sock'),
      start: (command) => Process.start('definitely-not-a-command-here', const <String>[]),
    );

    await tunnel.raise();

    expect(tunnel.state, TunnelState.down);
    expect(tunnel.problem, isNotNull);
  });

  test('a forward that never binds gives up and says so', () async {
    final tunnel = Tunnel(
      machineAt('${where.path}/never.sock'),
      // Up, and nothing bound: the shape ExitOnForwardFailure exists to prevent, produced here
      // by a process that simply sits there.
      start: (_) => Process.start('sh', const <String>['-c', 'sleep 30']),
      appears: const Duration(milliseconds: 300),
    );
    addTearDown(tunnel.drop);

    await tunnel.raise();

    expect(tunnel.state, TunnelState.down);
    expect(tunnel.problem, contains('did not appear'));
  });

  test('a plain file where the socket goes is not a forward', () async {
    // Anything at that path would read as a working forward if existence were the test, and a
    // leftover from a run that died is exactly a file at that path. It has to be a socket.
    final socket = '${where.path}/not-a-socket.sock';
    final tunnel = Tunnel(
      machineAt(socket),
      start: (_) => Process.start('sh', <String>['-c', 'touch $socket; sleep 30']),
      appears: const Duration(milliseconds: 400),
    );
    addTearDown(tunnel.drop);

    await tunnel.raise();

    expect(tunnel.state, TunnelState.down);
    expect(tunnel.problem, contains('did not appear'));
  });

  test('a socket left by a run that died is taken over, not surrendered to', () async {
    // Otherwise one crash means the machine can never be opened again without somebody knowing to
    // delete a file they have never heard of. ssh refuses to bind a path that exists.
    final socket = '${where.path}/leftover.sock';
    File(socket).writeAsStringSync('');
    final tunnel = Tunnel(machineAt(socket), start: bindsAndStays(socket));
    addTearDown(tunnel.drop);

    await tunnel.raise();

    expect(tunnel.state, TunnelState.up);
  });

  test('dropping it takes the process down and leaves no socket behind', () async {
    final socket = '${where.path}/dropped.sock';
    final tunnel = Tunnel(machineAt(socket), start: bindsAndStays(socket));
    await tunnel.raise();
    expect(File(socket).existsSync(), isTrue);

    await tunnel.drop();

    expect(tunnel.state, TunnelState.idle);
    expect(File(socket).existsSync(), isFalse,
        reason: 'closing must leave no socket file behind');
  });

  test('the endpoint it creates is readable by nobody else', () async {
    final socket = '${where.path}/private.sock';
    final tunnel = Tunnel(machineAt(socket), start: bindsAndStays(socket));
    addTearDown(tunnel.drop);

    await tunnel.raise();

    final mode = FileStat.statSync(socket).mode;
    expect(mode & 0x3F, 0, reason: 'no group or other bits');
  });

  test('a forward that drops is raised again', () async {
    final socket = '${where.path}/again.sock';
    var attempt = 0;
    final tunnel = Tunnel(
      machineAt(socket),
      // The first one dies on its own, as a forward does when the network goes; the second holds.
      start: (_) async {
        attempt++;
        return attempt == 1
            ? Process.start('sh', <String>['-c', 'echo "Connection closed" >&2; exit 255'])
            : Process.start('sh', <String>[
                '-c',
                'python3 -c "'
                    'import socket,time;'
                    's=socket.socket(socket.AF_UNIX);'
                    's.bind(\'$socket\');'
                    's.listen(1);'
                    'time.sleep(300)"',
              ]);
      },
    );
    addTearDown(tunnel.drop);
    final tunnels = Tunnels();

    await tunnel.raise();
    expect(tunnel.state, TunnelState.down);

    await tunnel.raise();

    expect(tunnel.state, TunnelState.up);
    expect(tunnel.raised, 2);
    tunnels.dispose();
  });

  group('what the interface owns', () {
    test('a machine somebody else forwarded is never raised or torn down', () async {
      // The path with no credential handling in it at all. It must keep working untouched, which
      // means nothing is started for it and nothing is stopped for it.
      final tunnels = Tunnels(start: (_) => throw StateError('nothing should be started'));
      addTearDown(tunnels.dispose);
      const theirs = Machine(name: 'theirs', socketPath: '/tmp/somebody-elses.sock');

      final ready = await tunnels.raiseFor(theirs);

      expect(ready, isTrue, reason: 'it is already reachable');
      expect(tunnels.manages(theirs), isFalse);
      await tunnels.dropEverything();
      expect(File('/tmp/somebody-elses.sock').existsSync(), isFalse);
    });

    test('dropping everything takes down only what was raised here', () async {
      final socket = '${where.path}/ours.sock';
      final tunnels = Tunnels(start: bindsAndStays(socket));
      addTearDown(tunnels.dispose);
      final ours = machineAt(socket);
      const theirs = Machine(name: 'theirs', socketPath: '/tmp/not-ours.sock');

      await tunnels.raiseFor(ours);
      await tunnels.raiseFor(theirs);
      expect(tunnels.manages(ours), isTrue);
      expect(tunnels.manages(theirs), isFalse);

      await tunnels.dropEverything();

      expect(File(socket).existsSync(), isFalse);
      expect(tunnels.manages(ours), isFalse);
    });
  });
  /// Starting a daemon at the far end.
  ///
  /// **The script is run, not mocked.** What can go wrong here is the line itself — a missing
  /// binary, a unit that is not there, a start that blocks because its output was never
  /// redirected — and a stand-in for `ssh` that echoed a fixed answer would prove none of it. So
  /// the far end is this machine, with `PATH` deciding what it has.
  group('starting a daemon at the far end', () {
    Tunnels runningTheScript(String path) => Tunnels(
          run: (command) => Process.run(
            '/bin/sh',
            <String>['-c', command.last],
            environment: <String, String>{'PATH': path},
            includeParentEnvironment: false,
          ),
        );

    test('the line names the host, asks for a unit first, and never prompts', () {
      final command = Tunnels.startCommandFor(machineAt('/tmp/unused.sock'));

      expect(command.first, 'ssh');
      expect(command, contains('user@build'));
      // Batch mode, for the same reason the forward uses it: there is no terminal to prompt at.
      expect(command, contains('BatchMode=yes'));
      expect(command.last.indexOf('systemctl'), lessThan(command.last.indexOf('setsid')),
          reason: 'a supervised unit is preferred to a loose process');
    });

    test('a machine with no sokard on it says so, and starts nothing', () async {
      // A path with nothing on it, and deliberately not this machine's own: a far end that has no
      // daemon is the case being tested, and running the real one here would be a side effect of
      // a test.
      final bare = Directory('${where.path}/bare')..createSync();

      final started = await runningTheScript(bare.path).startSokarOn(machineAt('/tmp/unused.sock'));

      expect(started.went, isFalse);
      expect(started.words, contains('no sokard is installed there'));
    });

    test('a machine that has it starts it detached, and does not wait for it', () async {
      final marker = '${where.path}/it-ran';
      final fake = File('${where.path}/sokard')
        ..writeAsStringSync('#!/bin/sh\necho ran > $marker\nsleep 5\n');
      Process.runSync('chmod', <String>['755', fake.path]);

      final started = await runningTheScript('${where.path}:/usr/bin:/bin')
          .startSokarOn(machineAt('/tmp/unused.sock'));

      expect(started.went, isTrue);
      expect(started.words, contains('started sokard itself'));
      // It came back while the daemon is still running, which is the whole of "detached": a start
      // that waited for the daemon to finish would hold the window for as long as it serves.
      final by = DateTime.now().add(const Duration(seconds: 5));
      while (!File(marker).existsSync() && DateTime.now().isBefore(by)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(File(marker).existsSync(), isTrue, reason: 'it was never run at the far end');
    });

    test('a machine somebody else forwards is refused before anything is run', () async {
      var asked = false;
      final tunnels = Tunnels(run: (_) async {
        asked = true;
        return ProcessResult(0, 0, '', '');
      });
      addTearDown(tunnels.dispose);

      final started = await tunnels
          .startSokarOn(const Machine(name: 'elsewhere', socketPath: '/tmp/elsewhere.sock'));

      expect(started.went, isFalse);
      expect(asked, isFalse, reason: 'there is no host to log into');
      expect(started.words, contains('forwarded by somebody else'));
    });

    test('ssh that cannot be run at all is a refusal, not a crash', () async {
      final tunnels = Tunnels(
        run: (_) => Future<ProcessResult>.error(
            const ProcessException('ssh', <String>[], 'No such file or directory')),
      );
      addTearDown(tunnels.dispose);

      final started = await tunnels.startSokarOn(machineAt('/tmp/unused.sock'));

      expect(started.went, isFalse);
      expect(started.words, contains('No such file or directory'));
    });
  });
}
