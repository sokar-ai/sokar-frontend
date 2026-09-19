import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/machines.dart';

import '../support/e2e.dart';

/// Usage: the machine lists the connection {'https://e2e.invalid/'} as a token in the vault
Future<void> theMachineListsTheConnectionAsATokenInTheVault(WidgetTester tester, String match) async {
  final client = await SokarClient.connect(
      Backend(socketPath: Machine.endpointFor(E2e.name), label: E2e.name));
  final store = await client.credentials();
  final connection = store.connections.where((each) => each.match == match).firstOrNull;
  expect(connection, isNotNull,
      reason: 'connections are ${store.connections.map((each) => each.match).toList()}');
  expect(connection!.kind, 'TOKEN');
  expect(connection.source, 'VAULT');
  expect(connection.protected, isTrue);
}
