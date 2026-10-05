import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/machines.dart';

import '../support/world.dart';

/// Usage: the wizard set up the machine {'build'}
Future<void> theWizardSetUpTheMachine(WidgetTester tester, String name) async {
  // What setting it up leaves on this computer: its key, and the Host entry naming it.
  final ssh = World.machines.setup.sshDirectory;
  Directory(ssh).createSync(recursive: true);
  final alias = 'sokar-$name';
  final key = '$ssh/$alias-agent';
  File(key).writeAsStringSync('a private key\n');
  File('$key.pub').writeAsStringSync('ssh-ed25519 AAAA $name\n');
  File('$ssh/config').writeAsStringSync('Host kept\n    HostName kept.example.test\n\n', mode: FileMode.append);
  await World.machines.setup.addHostEntry(alias: alias, host: '203.0.113.7', user: 'agents', keyFile: key);
  await World.machines.add(Machine(
    name: name,
    socketPath: Machine.endpointFor(name),
    host: alias,
    remoteSocket: '/run/user/1001/sokar/sokard.sock',
  ));
  await World.settle(tester);
}
