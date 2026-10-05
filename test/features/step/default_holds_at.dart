import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: default holds {'tools'} at {'git@example.org:acme/tools.git'}
Future<void> defaultHoldsAt(WidgetTester tester, String name, String upstream) async {
  expect(World.backend.inDefault.where((each) => each.name == name).single.upstream, upstream);
}
