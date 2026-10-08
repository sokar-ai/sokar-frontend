import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: no forge follows the builds of {'sokar-checkout-shell'}
Future<void> noForgeFollowsTheBuildsOf(WidgetTester tester, String work) async {
  World.backend.followBuilds(work, builds: const <Build>[], reader: '', problem: '');
  await World.settle(tester);
}
