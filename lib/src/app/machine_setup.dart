import 'dart:convert';
import 'dart:io';

import 'host_keys.dart';

/// An ssh key pair as text: what a person pastes, or what the wizard generates.
///
/// **The private half is a secret and this never says it**: [toString] names the public key only.
class KeyPair {
  /// Constructor taking both halves.
  const KeyPair({required this.privateKey, required this.publicKey});

  /// The private key, in OpenSSH's format.
  final String privateKey;

  /// The public key, one line: type, key, comment.
  final String publicKey;

  @override
  String toString() => 'KeyPair($publicKey)';
}

/// The steps of preparing a new machine that happen on this computer and over ssh as root: the key,
/// and whether that key logs in.
///
/// **Everything that could hold the private key is owner-only before it is written**, and nothing
/// here puts it in a command line, a log or an error.
class MachineSetup {
  /// Constructor, optionally with what runs a program and whose home `~/.ssh` is in.
  MachineSetup({RunWith? run, String? home})
      : _run = run ?? _runForReal,
        _home = home ?? Platform.environment['HOME'] ?? '';

  final RunWith _run;
  final String _home;

  static Future<ProcessResult> _runForReal(List<String> command, {String? input}) async {
    if (input == null) return Process.run(command.first, command.sublist(1));
    final process = await Process.start(command.first, command.sublist(1));
    process.stdin.write(input);
    await process.stdin.close();
    final out = process.stdout.transform(const SystemEncoding().decoder).join();
    final err = process.stderr.transform(const SystemEncoding().decoder).join();
    return ProcessResult(process.pid, await process.exitCode, await out, await err);
  }

  /// Where Sokar publishes its setup script (B62), for a machine that has nothing installed yet.
  static const String setupScript =
      'https://fuinorg.jfrog.io/artifactory/sokar-dist-deb/setup/sokar-setup-latest.sh';

  /// Fetches Sokar's setup script onto the machine, where every later step runs it from.
  static String _fetch() => '''set -e
f=/root/sokar-setup.sh
if command -v curl >/dev/null 2>&1; then curl -fsSL -o "\$f" '$setupScript'
else wget -qO "\$f" '$setupScript'; fi
''';

  /// Fetches the script and asks it what this machine could install, installing nothing: the
  /// machine's own package source is the catalogue, never this interface (QF19).
  static String listInstallable() => '${_fetch()}bash "\$f" --list --json\n';

  /// Prints every command the setup script would run for [user] and the chosen [packages],
  /// running none. **What the person reads is the script's own `--show`**, not a summary written
  /// here.
  static String show(String user, Iterable<String> packages) =>
      '${_fetch()}bash "\$f" ${_arguments(user, packages)} --show\n';

  /// Runs the setup script fetched by [show]: it creates [user] and installs Sokar and [packages].
  static String prepare(String user, Iterable<String> packages) =>
      'bash /root/sokar-setup.sh ${_arguments(user, packages)}\n';

  static String _arguments(String user, Iterable<String> packages) =>
      <String>["--user '$user'", for (final each in packages) "--with '$each'"].join(' ');

  /// What `--list --json` answered: one entry per package this machine could have.
  static List<InstallablePackage> installableIn(String json) {
    final decoded = jsonDecode(json);
    final packages = decoded is Map ? decoded['packages'] : null;
    if (packages is! List) {
      throw const MachineSetupFailed('The setup script answered its list in a shape this build does not read.');
    }
    return <InstallablePackage>[
      for (final each in packages)
        if (each is Map && each['name'] is String && _isPackageName(each['name'] as String))
          InstallablePackage(
            name: each['name'] as String,
            kind: each['kind'] is String ? each['kind'] as String : '',
            description: each['description'] is String ? each['description'] as String : '',
            installed: each['installed'] == true,
            version: each['version'] is String ? each['version'] as String : '',
          ),
    ];
  }

  /// Whether [name] can be a package name, so nothing else reaches a root command line.
  static bool _isPackageName(String name) => RegExp(r'^[a-z0-9][a-z0-9+.-]*$').hasMatch(name);

  /// Lets [publicKey] log in as [user], once, owner-only.
  static String authorize(String user, String publicKey) => '''set -e
home=\$(getent passwd '$user' | cut -d: -f6)
install -d -m 700 -o '$user' -g '$user' "\$home/.ssh"
touch "\$home/.ssh/authorized_keys"
chown '$user:$user' "\$home/.ssh/authorized_keys"
chmod 600 "\$home/.ssh/authorized_keys"
grep -qxF '$publicKey' "\$home/.ssh/authorized_keys" || echo '$publicKey' >> "\$home/.ssh/authorized_keys"
''';

  /// Turns off logging in as root and with a password, once the work user has logged in.
  static const String harden = '''set -e
printf 'PermitRootLogin no\\nPasswordAuthentication no\\n' > /etc/ssh/sshd_config.d/10-sokar.conf
systemctl reload ssh 2>/dev/null || systemctl reload sshd
''';

  /// What each exit of the setup script means, as B62 promises them.
  static String whatTheScriptSaid(int exitCode) => switch (exitCode) {
        0 => 'The machine is prepared.',
        2 => 'The setup script did not understand what it was asked.',
        3 => 'The setup script does not know this operating system, so nothing was installed.',
        4 => 'The setup script did not run as root.',
        5 => 'A check failed and the machine is not usable yet; what it said is above.',
        _ => 'The setup script ended with $exitCode.',
      };

  /// Runs [script] as root on [host] with the key at [keyFile], on standard input: nothing of it
  /// is in a command line, and it is exactly the text that was shown.
  Future<ProcessResult> asRoot(String host, String keyFile, String script) => _run(<String>[
        'ssh', '-i', keyFile, '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
        '-o', 'ConnectTimeout=10', 'root@$host', 'bash', '-s',
      ], input: script);

  /// [asRoot], with every line handed to [onLine] as it arrives, so a person watching a script that
  /// takes minutes sees it working rather than a window that looks stuck.
  Future<ProcessResult> asRootLive(
    String host,
    String keyFile,
    String script,
    void Function(String line) onLine,
  ) async {
    final process = await Process.start('ssh', <String>[
      '-i', keyFile, '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
      '-o', 'ConnectTimeout=10', 'root@$host', 'bash', '-s',
    ]);
    process.stdin.write(script);
    await process.stdin.close();
    final out = StringBuffer();
    final err = StringBuffer();
    Future<void> follow(Stream<List<int>> stream, StringBuffer into) => stream
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .forEach((line) {
      into.writeln(line);
      onLine(line);
    });
    await Future.wait(<Future<void>>[follow(process.stdout, out), follow(process.stderr, err)]);
    return ProcessResult(process.pid, await process.exitCode, '$out', '$err');
  }

  /// Runs [command] as the work user through the `Host` entry [alias].
  Future<ProcessResult> asUser(String alias, String command) => _run(<String>[
        'ssh', '-n', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', alias, command,
      ]);

  /// Adds a `Host` entry for the machine to `~/.ssh/config`: **as the work user, never root**.
  ///
  /// Appended, after a copy of the file is kept; an entry of that name that already says the same
  /// is left alone, and one that says something else is never overwritten.
  Future<String> addHostEntry({
    required String alias,
    required String host,
    required String user,
    required String keyFile,
  }) async {
    final entry = 'Host $alias\n'
        '    HostName $host\n'
        '    User $user\n'
        '    IdentityFile $keyFile\n'
        '    IdentitiesOnly yes\n';
    final directory = Directory(sshDirectory);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      await _run(<String>['chmod', '700', directory.path]);
    }
    final config = File('${directory.path}/config');
    final before = config.existsSync() ? config.readAsStringSync() : '';
    if (before.contains(entry)) return '~/.ssh/config already has $alias.';
    if (RegExp('^Host\\s+${RegExp.escape(alias)}\\s*\$', multiLine: true).hasMatch(before)) {
      throw MachineSetupFailed(
          '~/.ssh/config already has a Host $alias that says something else, so nothing was written.');
    }
    if (before.isNotEmpty) {
      final kept = '${config.path}.before-$alias';
      File(kept).writeAsStringSync(before);
      await _run(<String>['chmod', '600', kept]);
    } else {
      config.createSync();
    }
    await _run(<String>['chmod', '600', config.path]);
    final separator = before.isEmpty || before.endsWith('\n\n') ? '' : (before.endsWith('\n') ? '\n' : '\n\n');
    config.writeAsStringSync('$separator$entry', mode: FileMode.append, flush: true);
    return 'Added Host $alias to ~/.ssh/config.';
  }

  /// Where the keys go.
  String get sshDirectory => '$_home/.ssh';

  /// Generates an ed25519 pair with no passphrase — the interface never asks for one — named [comment].
  Future<KeyPair> generate(String comment) => _inAPrivateDirectory((directory) async {
        final file = '${directory.path}/key';
        final made = await _run(<String>['ssh-keygen', '-q', '-t', 'ed25519', '-N', '', '-C', comment, '-f', file]);
        if (made.exitCode != 0) {
          throw MachineSetupFailed('ssh-keygen could not make a key: ${'${made.stderr}'.trim()}');
        }
        return KeyPair(
          privateKey: File(file).readAsStringSync(),
          publicKey: File('$file.pub').readAsStringSync().trim(),
        );
      });

  /// Why [pair]'s halves do not belong together, or null when they do.
  ///
  /// Asked of `ssh-keygen` rather than parsed here: it reads the private key and derives the public
  /// one, which is the only comparison that proves the two are a pair.
  Future<String?> mismatch(KeyPair pair) => _inAPrivateDirectory((directory) async {
        // Owner-only before it holds anything: ssh-keygen refuses a private key others could read.
        final file = File('${directory.path}/key')..createSync();
        await _run(<String>['chmod', '600', file.path]);
        file.writeAsStringSync(_ending(pair.privateKey));
        final derived = await _run(<String>['ssh-keygen', '-y', '-P', '', '-f', file.path]);
        if (derived.exitCode != 0) {
          return 'That private key cannot be read. It needs to be an OpenSSH private key with no '
              'passphrase.';
        }
        if (_keyOf('${derived.stdout}') != _keyOf(pair.publicKey)) {
          return 'The public key does not belong to that private key.';
        }
        return null;
      });

  /// Writes [pair] to `~/.ssh/<name>` and `<name>.pub`, owner-only, and answers the private key's path.
  ///
  /// **A file already there is never overwritten** unless it holds the same key, so running the
  /// wizard again is harmless and a person's other key is never lost to a name clash.
  Future<String> save(KeyPair pair, String name) async {
    final directory = Directory(sshDirectory);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      await _run(<String>['chmod', '700', directory.path]);
    }
    final private = File('${directory.path}/$name');
    final public = File('${private.path}.pub');
    for (final (file, content) in <(File, String)>[(private, pair.privateKey), (public, pair.publicKey)]) {
      if (file.existsSync() && file.readAsStringSync().trim() != content.trim()) {
        throw MachineSetupFailed('${file.path} already holds another key, so nothing was written.');
      }
    }
    if (!private.existsSync()) {
      private.createSync();
      await _run(<String>['chmod', '600', private.path]);
      private.writeAsStringSync(_ending(pair.privateKey), flush: true);
    }
    if (!public.existsSync()) {
      public.writeAsStringSync('${pair.publicKey.trim()}\n', flush: true);
      await _run(<String>['chmod', '644', public.path]);
    }
    return private.path;
  }

  /// The keys a wizard kept here before, newest name first: `~/.ssh/sokar-*` without `.pub`.
  List<String> existingKeys() {
    final directory = Directory(sshDirectory);
    if (!directory.existsSync()) return const <String>[];
    return <String>[
      for (final file in directory.listSync().whereType<File>())
        if (file.uri.pathSegments.last.startsWith('sokar-') && !file.path.endsWith('.pub'))
          file.path,
    ]..sort();
  }

  /// Every private key in `~/.ssh`, by path: a file beside its `.pub`, or one that begins as a
  /// private key does. **Only the first line of a file is read**, and nothing of it is shown.
  List<String> sshKeys() {
    final directory = Directory(sshDirectory);
    if (!directory.existsSync()) return const <String>[];
    bool looksPrivate(File file) {
      RandomAccessFile? handle;
      try {
        handle = file.openSync();
        return String.fromCharCodes(handle.readSync(64)).contains('PRIVATE KEY');
      } on FileSystemException {
        return false;
      } finally {
        handle?.closeSync();
      }
    }

    return <String>[
      for (final file in directory.listSync().whereType<File>())
        if (!file.path.endsWith('.pub') &&
            (File('${file.path}.pub').existsSync() || looksPrivate(file)))
          file.path,
    ]..sort();
  }

  /// The public half of the private key at [keyFile], as `ssh-keygen` derives it.
  ///
  /// `-P ''` so a key with a passphrase is refused rather than asked about: nothing here takes a
  /// passphrase, and a prompt on a terminal nobody watches would hang the wizard.
  Future<String> publicKeyOf(String keyFile) async {
    final derived = await _run(<String>['ssh-keygen', '-y', '-P', '', '-f', keyFile]);
    if (derived.exitCode != 0) {
      throw MachineSetupFailed('$keyFile cannot be read as a private key with no passphrase: '
          '${'${derived.stderr}'.trim()}');
    }
    return '${derived.stdout}'.trim();
  }

  /// Why logging in as root on [host] with the key at [keyFile] failed, or null when it worked.
  Future<String?> loginAsRoot(String host, String keyFile) async {
    final login = await _run(<String>[
      'ssh', '-i', keyFile, '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
      '-o', 'ConnectTimeout=10', 'root@$host', 'true',
    ]);
    if (login.exitCode == 0) return null;
    final said = '${login.stderr}'.trim();
    return said.isEmpty ? 'ssh ended with ${login.exitCode} and said nothing.' : said;
  }

  /// Runs [body] with a directory only this user can enter, removed afterwards whatever happened.
  Future<T> _inAPrivateDirectory<T>(Future<T> Function(Directory directory) body) async {
    final directory = Directory.systemTemp.createTempSync('sokar-key-');
    try {
      await _run(<String>['chmod', '700', directory.path]);
      return await body(directory);
    } finally {
      directory.deleteSync(recursive: true);
    }
  }

  static String _ending(String text) => text.endsWith('\n') ? text : '$text\n';

  /// The type and the key of a public key line, without its comment.
  static String _keyOf(String line) => line.trim().split(RegExp(r'\s+')).take(2).join(' ');
}

/// A step of preparing a machine failed, in words that say which.
class MachineSetupFailed implements Exception {
  /// Constructor taking what went wrong.
  const MachineSetupFailed(this.message);

  /// What went wrong, never quoting a private key.
  final String message;

  @override
  String toString() => message;
}

/// A package a machine could have, as its setup script lists it.
class InstallablePackage {
  /// Constructor taking what the list says.
  const InstallablePackage({
    required this.name,
    required this.kind,
    required this.description,
    required this.installed,
    required this.version,
  });

  /// The real package name, never a virtual one.
  final String name;

  /// `agent` or `transport`, or whatever a newer script names.
  final String kind;

  /// One line saying what it is.
  final String description;

  /// Whether the machine has it already.
  final bool installed;

  /// The version the index offers, or empty.
  final String version;
}
