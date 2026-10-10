import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/wsl.dart';
import 'package:sokar_frontend/src/app/wsl_setup.dart';

/// The checks before a WSL distribution is connected to, in order, stopping at the first that
/// fails; and the offer to set Sokar up, shown line by line and run only after a yes, the key checked
/// against the fingerprint the interface carries.
void main() {
  const windows11 = '"Windows 11 Pro" 10.0 (Build 26100)';
  const ubuntu = 'PRETTY_NAME="Ubuntu 26.04 LTS"\nID=ubuntu\nVERSION_ID="26.04"\n';

  /// A distribution called Ubuntu that runs as WSL2, answering [answers] by command.
  ({WslSetup setup, List<String> ran}) distribution({
    String os = ubuntu,
    String systemd = 'running',
    bool sokar = true,
    bool daemon = true,
    String fingerprint = sokarKeyFingerprint,
    int failAt = -1,
    String version = windows11,
  }) {
    final ran = <String>[];
    final wsl = Wsl(run: (arguments) async => (
          code: 0,
          printed: switch (arguments.join(' ')) {
            '-l -q' || '-l --running -q' => 'Ubuntu\n'.codeUnits,
            '-l -v' => '  NAME   STATE   VERSION\n* Ubuntu Running 2\n'.codeUnits,
            _ => <int>[],
          }
        ));
    final setup = WslSetup(
      distribution: 'Ubuntu',
      operatingSystemVersion: version,
      wsl: wsl,
      answers: (_) async => daemon,
      run: (name, command, {bool asRoot = false}) async {
        final line = '${asRoot ? 'root: ' : ''}${command.join(' ')}';
        ran.add(line);
        if (failAt >= 0 && ran.length - 1 == failAt) return (code: 1, said: 'it failed');
        return switch (command.join(' ')) {
          'cat /etc/os-release' => (code: 0, said: os),
          'systemctl is-system-running' => (code: systemd == 'offline' ? 1 : 0, said: systemd),
          'sokar --version' => (code: sokar ? 0 : 127, said: sokar ? 'sokar 0.4.2' : 'not found'),
          'id -un' => (code: 0, said: 'somebody\n'),
          'gpg --show-keys --with-colons /tmp/sokar.asc' =>
            (code: 0, said: 'pub:-:4096:1:6B488A9326920DBE:::::\nfpr:::::::::$fingerprint:\n'),
          _ => (code: 0, said: ''),
        };
      },
    );
    return (setup: setup, ran: ran);
  }

  test('a supported running distribution with Sokar answering passes every check', () async {
    final it = distribution().setup;

    await it.check();

    expect(it.ready, isTrue);
    expect(it.machine.kind, 'wsl');
    expect(it.machine.distribution, 'Ubuntu');
  });

  test('a Windows older than build 19041 is told so, and nothing else is asked', () async {
    final it = distribution(version: '"Windows 10 Pro" 10.0 (Build 18363)').setup;

    await it.check();

    expect(it.failed?.check, WslCheck.windows);
    expect(it.failed?.words, contains('build 18363'));
    expect(it.findings, hasLength(1));
  });

  test('a system Sokar does not support is said, and no setup is offered', () async {
    final it = distribution(os: 'PRETTY_NAME="Ubuntu 24.04 LTS"\nID=ubuntu\nVERSION_ID="24.04"\n').setup;

    await it.check();

    expect(it.failed?.check, WslCheck.supported);
    expect(it.failed?.words, contains('Ubuntu 24.04 LTS'));
    expect(it.offersTheSetup, isFalse);
  });

  test('without systemd, the separate question is asked, not the setup', () async {
    final it = distribution(systemd: 'offline').setup;

    await it.check();

    expect(it.asksForSystemd, isTrue);
    expect(it.offersTheSetup, isFalse);
  });

  test('without Sokar, the setup is offered', () async {
    final it = distribution(sokar: false).setup;

    await it.check();

    expect(it.failed?.check, WslCheck.sokar);
    expect(it.offersTheSetup, isTrue);
  });

  test('the supported systems are Ubuntu 26.04 or later, Debian 13 and Fedora 43 and 44', () {
    bool supported(String id, String version) => OsRelease(id: id, version: version, name: '').supported;

    expect(supported('ubuntu', '26.04'), isTrue);
    expect(supported('ubuntu', '26.10'), isTrue);
    expect(supported('ubuntu', '24.04'), isFalse);
    expect(supported('debian', '13'), isTrue);
    expect(supported('debian', '12'), isFalse);
    expect(supported('fedora', '43'), isTrue);
    expect(supported('fedora', '44'), isTrue);
    expect(supported('fedora', '42'), isFalse);
    expect(supported('arch', ''), isFalse);
  });

  test('the lines for apt name the key, the source, the agents chosen, lingering and the setup', () async {
    final it = distribution(sokar: false).setup;
    await it.check();
    it.agents.addAll(<String>{'sokar-agent-pi', 'sokar-agent-claude'});

    final shown = it.setupLines('somebody').map((each) => each.shown).toList();

    expect(shown, <String>[
      "sudo sh -c 'curl -fsSL $sokarKeyAddress -o /tmp/sokar.asc'",
      'sudo gpg --dearmor --yes -o /usr/share/keyrings/sokar.gpg /tmp/sokar.asc',
      'sudo sh -c \'echo "deb [signed-by=/usr/share/keyrings/sokar.gpg] $sokarDebRepository releases main" '
          '> /etc/apt/sources.list.d/sokar.list\'',
      "sudo sh -c 'apt-get update && apt-get install -y sokar sokar-agent-claude sokar-agent-pi'",
      'sudo loginctl enable-linger somebody',
      'sokar setup',
    ]);
  });

  test('nothing is chosen in advance: with no agent chosen, only Sokar is installed', () async {
    final it = distribution(sokar: false, os: 'PRETTY_NAME="Fedora Linux 44"\nID=fedora\nVERSION_ID=44\n').setup;
    await it.check();

    final shown = it.setupLines('somebody').map((each) => each.shown).toList();

    expect(it.agents, isEmpty);
    expect(shown, contains("sudo sh -c 'dnf install -y sokar'"));
    expect(shown.join('\n'), contains('/etc/yum.repos.d/sokar.repo'));
  });

  test('a key that does not match the carried fingerprint stops the setup before anything is written', () async {
    final run = distribution(sokar: false, fingerprint: '0000000000000000000000000000000000000000');
    final recorded = <String>[];
    final it = WslSetup(
      distribution: 'Ubuntu',
      operatingSystemVersion: windows11,
      wsl: Wsl(run: (arguments) async => (code: 0, printed: <int>[])),
      run: (name, command, {bool asRoot = false}) async {
        run.ran.add(command.join(' '));
        return command.first == 'gpg' && command[1] == '--show-keys'
            ? (code: 0, said: 'fpr:::::::::0000000000000000000000000000000000000000:\n')
            : (code: 0, said: '');
      },
      record: (line, said) => recorded.add(line),
    );

    await it.runSetup(it.setupLines('somebody'));

    expect(it.stopped, contains('Expected $sokarKeyFingerprint'));
    expect(it.stopped, contains('0000000000000000000000000000000000000000'));
    expect(run.ran.where((each) => each.contains('dearmor') || each.contains('install')), isEmpty);
    expect(recorded, contains('check the key'));
  });

  test('every line that ran is recorded, and a failing one stops the rest', () async {
    final run = distribution(sokar: false, failAt: 3);
    final recorded = <String>[];
    final it = WslSetup(
      distribution: 'Ubuntu',
      operatingSystemVersion: windows11,
      wsl: Wsl(run: (arguments) async => (code: 0, printed: <int>[])),
      run: (name, command, {bool asRoot = false}) async {
        run.ran.add(command.join(' '));
        if (command.join(' ').startsWith('sh -c echo')) return (code: 1, said: 'refused');
        return command.first == 'gpg' && command[1] == '--show-keys'
            ? (code: 0, said: 'fpr:::::::::$sokarKeyFingerprint:\n')
            : (code: 0, said: '');
      },
      record: (line, said) => recorded.add(line),
    );

    await it.runSetup(it.setupLines('somebody'));

    expect(it.stopped, contains('ended with 1'));
    expect(recorded, hasLength(3));
    expect(run.ran.where((each) => each.contains('apt-get')), isEmpty);
  });

  test('the Windows build is read from what Dart says the system is', () {
    expect(windowsBuild('"Windows 10 Pro" 10.0 (Build 19045)'), 19045);
    expect(windowsBuild('Linux 7.0.0'), isNull);
  });
}
