import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/machines.dart';

import '../support/e2e.dart';

/// Usage: the connection {'ssh://github.com/'} is forgotten again
Future<void> theConnectionIsForgottenAgain(WidgetTester tester, String match) async {
  final client = await SokarClient.connect(
      Backend(socketPath: Machine.endpointFor(E2e.name), label: E2e.name));
  await client.credentialForget(match);
}
