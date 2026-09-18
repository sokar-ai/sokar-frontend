import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/machine_setup.dart';

/// Against the real `ssh-keygen`: the pair it makes, and the check that two pasted halves belong
/// together, are only worth as much as the tool that answers them.
void main() {
  late Directory home;
  late MachineSetup setup;

  setUp(() {
    home = Directory.systemTemp.createTempSync('machine-setup-');
    setup = MachineSetup(home: home.path);
  });

  tearDown(() => home.deleteSync(recursive: true));

  int mode(String path) => FileStat.statSync(path).mode & 0x1FF;

  test('a generated pair belongs together and is written owner-only', () async {
    final pair = await setup.generate('sokar build machine');

    expect(pair.publicKey, startsWith('ssh-ed25519 '));
    expect(pair.publicKey, endsWith('sokar build machine'));
    expect(await setup.mismatch(pair), isNull);

    final path = await setup.save(pair, 'sokar-build');

    expect(path, '${home.path}/.ssh/sokar-build');
    expect(mode('${home.path}/.ssh'), 0x1C0, reason: '~/.ssh is not 700');
    expect(mode(path), 0x180, reason: 'the private key is not 600');
    expect(mode('$path.pub'), 0x1A4, reason: 'the public key is not 644');
    expect(File(path).readAsStringSync(), pair.privateKey);
  });

  test("halves of two different pairs are refused before anything is written", () async {
    final one = await setup.generate('one');
    final other = await setup.generate('other');

    final said = await setup.mismatch(KeyPair(privateKey: one.privateKey, publicKey: other.publicKey));

    expect(said, contains('does not belong'));
  });

  test('a comment that differs is still the same key', () async {
    final pair = await setup.generate('as generated');
    final renamed = '${pair.publicKey.split(' ').take(2).join(' ')} renamed by somebody';

    expect(await setup.mismatch(KeyPair(privateKey: pair.privateKey, publicKey: renamed)), isNull);
  });

  test('something that is not a private key says so', () async {
    final pair = await setup.generate('x');

    final said = await setup.mismatch(KeyPair(privateKey: 'not a key', publicKey: pair.publicKey));

    expect(said, contains('cannot be read'));
  });

  test('saving twice is harmless, and another key under that name is never overwritten', () async {
    final pair = await setup.generate('first');
    await setup.save(pair, 'sokar-build');
    await setup.save(pair, 'sokar-build');

    final other = await setup.generate('second');
    await expectLater(setup.save(other, 'sokar-build'), throwsA(isA<MachineSetupFailed>()));
    expect(File('${home.path}/.ssh/sokar-build').readAsStringSync(), pair.privateKey);
  });

  test('a pair never says its private half', () async {
    final pair = await setup.generate('x');

    expect('$pair', isNot(contains('PRIVATE')));
  });

  test('a failed root login says what ssh said', () async {
    final failing = MachineSetup(
      home: home.path,
      run: (command, {input}) async => ProcessResult(0, 255, '', 'root@203.0.113.10: Permission denied (publickey).'),
    );

    expect(await failing.loginAsRoot('203.0.113.10', '/k'), contains('Permission denied'));
  });

  group('the Host entry', () {
    Future<String> add({String alias = 'sokar-build', String user = 'agents'}) => setup.addHostEntry(
        alias: alias, host: '203.0.113.10', user: user, keyFile: '${home.path}/.ssh/sokar-build');

    String config() => File('${home.path}/.ssh/config').readAsStringSync();

    test('a first entry makes the file owner-only and names the work user and the key', () async {
      await add();

      expect(config(), 'Host sokar-build\n    HostName 203.0.113.10\n    User agents\n'
          '    IdentityFile ${home.path}/.ssh/sokar-build\n    IdentitiesOnly yes\n');
      expect(mode('${home.path}/.ssh/config'), 0x180);
    });

    test("somebody's own entries are kept, a copy is made first, and the entry is appended", () async {
      Directory('${home.path}/.ssh').createSync();
      File('${home.path}/.ssh/config').writeAsStringSync('Host mine\n    User me\n');

      await add();

      expect(config(), startsWith('Host mine\n    User me\n\nHost sokar-build\n'));
      expect(File('${home.path}/.ssh/config.before-sokar-build').readAsStringSync(),
          'Host mine\n    User me\n');
    });

    test('adding it twice changes nothing', () async {
      await add();
      final once = config();

      expect(await add(), contains('already has'));
      expect(config(), once);
    });

    test('an entry of that name that says something else is never overwritten', () async {
      await add();

      await expectLater(add(user: 'somebody-else'), throwsA(isA<MachineSetupFailed>()));
      expect(config(), contains('User agents'));
      expect(config(), isNot(contains('somebody-else')));
    });
  });

  test('every exit the setup script promises is said in words', () {
    expect(MachineSetup.whatTheScriptSaid(0), 'The machine is prepared.');
    expect(MachineSetup.whatTheScriptSaid(3), contains('does not know this operating system'));
    expect(MachineSetup.whatTheScriptSaid(4), contains('root'));
    expect(MachineSetup.whatTheScriptSaid(5), contains('not usable'));
    expect(MachineSetup.whatTheScriptSaid(9), contains('9'));
  });

  test('allowing the key names the user in every command and appends it only once', () {
    final script = MachineSetup.authorize('agents', 'ssh-ed25519 AAAA laptop');

    expect(script, contains("-o 'agents' -g 'agents'"));
    expect(script, contains("grep -qxF 'ssh-ed25519 AAAA laptop'"));
    expect(script, startsWith('set -e'));
  });

  group('what a machine could install', () {
    test('every field is read, and a missing one reads as nothing rather than failing', () {
      final packages = MachineSetup.installableIn('{"packages": ['
          '{"name": "sokar-agent-claude", "kind": "agent", "description": "Claude Code", '
          '"installed": true, "version": "1.0"}, {"name": "sokar-agent-omp"}]}');

      expect(packages.map((each) => each.name), <String>['sokar-agent-claude', 'sokar-agent-omp']);
      expect(packages.first.kind, 'agent');
      expect(packages.first.installed, isTrue);
      expect(packages.first.version, '1.0');
      expect(packages.last.installed, isFalse);
      expect(packages.last.description, isEmpty);
    });

    test('a name that could not be a package never reaches a root command line', () {
      final packages = MachineSetup.installableIn('{"packages": ['
          '{"name": "x\'; rm -rf / #"}, {"name": "Upper"}, {"name": "ok-1.0+b"}]}');

      expect(packages.map((each) => each.name), <String>['ok-1.0+b']);
    });

    test('a shape this build does not read is said, not guessed at', () {
      expect(() => MachineSetup.installableIn('{"items": []}'), throwsA(isA<MachineSetupFailed>()));
    });

    test('the choice is carried into both showing and running, the same way', () {
      expect(MachineSetup.show('agents', <String>['sokar-agent-claude']),
          contains("--user 'agents' --with 'sokar-agent-claude' --show"));
      expect(MachineSetup.prepare('agents', <String>['sokar-agent-claude']),
          "bash /root/sokar-setup.sh --user 'agents' --with 'sokar-agent-claude'\n");
    });
  });
}

