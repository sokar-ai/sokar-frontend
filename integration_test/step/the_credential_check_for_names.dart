import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/machines.dart';

import '../support/e2e.dart';

/// Usage: the credential check for {'https://e2e.invalid/repo.git'} names {'https://e2e.invalid/'}
Future<void> theCredentialCheckForNames(WidgetTester tester, String url, String match) async {
  final client = await SokarClient.connect(
      Backend(socketPath: Machine.endpointFor(E2e.name), label: E2e.name));
  final check = await client.credentialCheck(url);
  // Whatever the vault's state, the record it would use is the one declared — and it is not READY
  // with no value stored.
  expect(check.connection.match, match, reason: '${check.outcome}: ${check.detail}');
  expect(check.outcome, isNot('READY'), reason: 'nothing was stored for it');
}
