import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/host_keys.dart';

/// OpenSSH as far as these checks ask it: `ssh -G`, `ssh-keygen -F` and `-l`, `ssh-keyscan`.
class _Ssh {
  _Ssh({this.config = 'hostname build.example.test\nport 22\nuserknownhostsfile ~/.ssh/known_hosts ~/.ssh/known_hosts2\n'});

  final String config;

  /// Which `known_hosts` files know which hosts.
  final Map<String, Set<String>> knows = <String, Set<String>>{};

  String scanned = '|1|abc= ssh-ed25519 AAAAC3Nza\n# a comment ssh-keyscan prints\n';
  final List<List<String>> ran = <List<String>>[];
  String? given;

  Future<ProcessResult> run(List<String> command, {String? input}) async {
    ran.add(command);
    ProcessResult answer(int code, [String out = '', String err = '']) => ProcessResult(0, code, out, err);
    switch (command) {
      case ['ssh', '-G', _]:
        return answer(0, config);
      case ['ssh-keygen', '-F', final host, '-f', final file]:
        return answer((knows[file] ?? const <String>{}).contains(host) ? 0 : 1);
      case ['ssh-keyscan', ...]:
        return answer(0, scanned);
      case ['ssh-keygen', '-l', '-f', '-']:
        given = input;
        return answer(0, '256 SHA256:fingerprint build.example.test (ED25519)\n');
      default:
        return answer(0);
    }
  }
}

void main() {
  test('an unknown host is scanned on the port ssh will use, and its fingerprints are shown', () async {
    final ssh = _Ssh();

    final check = await SshHostKeys(run: ssh.run, home: '/home/somebody').check('michi@build');

    expect(check.known, isFalse);
    expect(check.host, 'build.example.test', reason: 'the alias was not resolved');
    expect(ssh.ran, anyElement(equals(<String>['ssh-keyscan', '-T', '10', '-H', '-p', '22', 'build.example.test'])));
    expect(check.scanned, <String>['|1|abc= ssh-ed25519 AAAAC3Nza'], reason: 'a comment would be written');
    expect(check.fingerprints.single, contains('SHA256:fingerprint'));
    expect(ssh.given, contains('ssh-ed25519 AAAAC3Nza'), reason: 'the fingerprints are of other keys');
  });

  test('a host known in any of the files ssh reads is not scanned at all', () async {
    final ssh = _Ssh()..knows['/home/somebody/.ssh/known_hosts2'] = <String>{'build.example.test'};

    final check = await SshHostKeys(run: ssh.run, home: '/home/somebody').check('build');

    expect(check.known, isTrue);
    expect(ssh.ran.where((each) => each.first == 'ssh-keyscan'), isEmpty);
  });

  test('off port 22 the host is named the way known_hosts names it', () async {
    final ssh = _Ssh(config: 'hostname 203.0.113.10\nport 2222\nuserknownhostsfile ~/.ssh/known_hosts\n')
      ..knows['/home/somebody/.ssh/known_hosts'] = <String>{'203.0.113.10'};

    final check = await SshHostKeys(run: ssh.run, home: '/home/somebody').check('rented');

    expect(check.host, '[203.0.113.10]:2222');
    expect(check.known, isFalse, reason: 'the key for port 22 stood in for port 2222');
    expect(ssh.ran, anyElement(equals(<String>['ssh-keyscan', '-T', '10', '-H', '-p', '2222', '203.0.113.10'])));
  });

  test('a host that offers no key says so, and there is nothing to trust', () async {
    final ssh = _Ssh()..scanned = '';

    final check = await SshHostKeys(run: ssh.run, home: '/home/somebody').check('build');

    expect(check.problem, contains('No host key came back'));
    expect(check.scanned, isEmpty);
  });

  test('accepting appends exactly what was scanned, owner-only', () async {
    final home = Directory.systemTemp.createTempSync('host-keys-');
    addTearDown(() => home.deleteSync(recursive: true));
    File('${(Directory('${home.path}/.ssh')..createSync()).path}/known_hosts')
        .writeAsStringSync('existing line\n');

    await SshHostKeys(home: home.path).accept(const HostKeyCheck(
      destination: 'build',
      host: 'build.example.test',
      known: false,
      scanned: <String>['|1|abc= ssh-ed25519 AAAAC3Nza'],
    ));

    expect(File('${home.path}/.ssh/known_hosts').readAsStringSync(),
        'existing line\n|1|abc= ssh-ed25519 AAAAC3Nza\n');
  });

  test('a first known_hosts is made owner-only', () async {
    final home = Directory.systemTemp.createTempSync('host-keys-');
    addTearDown(() => home.deleteSync(recursive: true));

    await SshHostKeys(home: home.path).accept(const HostKeyCheck(
      destination: 'build',
      host: 'build.example.test',
      known: false,
      scanned: <String>['|1|abc= ssh-ed25519 AAAAC3Nza'],
    ));

    expect(FileStat.statSync('${home.path}/.ssh').mode & 0x1FF, 0x1C0); // 700
    expect(FileStat.statSync('${home.path}/.ssh/known_hosts').mode & 0x1FF, 0x180); // 600
  });
}
