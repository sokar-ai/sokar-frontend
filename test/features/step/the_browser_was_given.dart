import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the browser was given {'https://claude.com/cai/oauth/authorize?code=true'}
Future<void> theBrowserWasGiven(WidgetTester tester, String address) async {
  expect(World.opened, <Uri>[Uri.parse(address)]);
}
