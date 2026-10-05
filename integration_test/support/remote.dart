import 'dart:io';

import 'e2e.dart';

/// Runs [script] on the test machine through ssh, and answers what it printed.
///
/// On standard input, never `-n`: `ssh -n` connects it to `/dev/null`, so the script would never
/// arrive and the run would say nothing and exit 0. The agent `tool/e2e.sh` raised holds the key.
Future<String> onTheTestMachine(String script) async {
  final ssh = await Process.start('ssh', <String>['-o', 'BatchMode=yes', E2e.host, 'bash -s']);
  ssh.stdin.write(script);
  await ssh.stdin.close();
  final out = await ssh.stdout.transform(const SystemEncoding().decoder).join();
  final err = await ssh.stderr.transform(const SystemEncoding().decoder).join();
  final code = await ssh.exitCode;
  if (code != 0) throw StateError('on the test machine, exit $code: $err');
  return out.trim();
}

/// Where the scenario's repository was made on the test machine, once it was.
String? theRepository;

/// Where the key the test machine's account has is, once a step has made sure of one.
String? theKey;

/// The machine's own sentence from the connection wizard's check, read before it was left.
String? theCheckSaid;

/// The vault entry a scenario copied a key into, once the machine listed it.
String? theVaultEntry;

/// The file name of the message a scenario had held for a person on the test machine.
String? theHeldMessage;

/// What the interface showed as that message's text.
String? theMessageRead;
