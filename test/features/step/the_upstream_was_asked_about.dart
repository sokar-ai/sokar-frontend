import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the upstream was asked about {'checkout'}
///
/// Read off the socket: a triggered fetch is its own call, never a listing that quietly reached
/// the network.
Future<void> theUpstreamWasAskedAbout(WidgetTester tester, String project) async {
  expect(World.backend.syncs, contains(project));
}
