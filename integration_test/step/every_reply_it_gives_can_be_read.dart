import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/machines.dart';

import '../support/e2e.dart';

/// Usage: every reply it gives can be read
Future<void> everyReplyItGivesCanBeRead(WidgetTester tester) async {
  // Through the same forward the interface raised, so this reads what the window reads.
  final client = await SokarClient.connect(
      Backend(socketPath: Machine.endpointFor(E2e.name), label: E2e.name));
  final tasks = await client.tasks();
  final projects = await client.projects();
  // Said, so a green run shows it read a real machine rather than an empty one.
  debugPrint('${E2e.name} answered: ${tasks.length} tasks, ${projects.length} projects');

  final missing = <String>[];
  Future<void> reads(String method, Future<Object?> Function() call) async {
    try {
      await call();
    } on FeatureNotSupported {
      // Older than this build: absent is allowed, unreadable is not.
      missing.add(method);
    }
  }

  await reads('Sets', client.sets);
  await reads('Agents', client.agents);
  await reads('Credentials', client.credentials);
  await reads('Doctor', client.doctor);
  await reads('Providers', client.providers);
  await reads('Node', client.node);
  await reads('the contract', client.contract);
  if (missing.isNotEmpty) debugPrint('not on this daemon: ${missing.join(', ')}');
}
