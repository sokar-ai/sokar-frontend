import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the builds of {'sokar-checkout-shell'} are read from {'github'}
Future<void> theBuildsOfAreReadFrom(WidgetTester tester, String work, String reader) async {
  World.backend.followBuilds(work, builds: const <Build>[], reader: reader, problem: '');
  await World.settle(tester);
}
