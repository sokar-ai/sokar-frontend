import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I tap the project {'checkout'}
Future<void> iTapTheProject(WidgetTester tester, String project) async {
  await tapOnScreen(tester, cardFor(project));
  await World.settle(tester);
}
