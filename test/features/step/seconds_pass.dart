import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: {31} seconds pass
Future<void> secondsPass(WidgetTester tester, num seconds) async {
  await tester.pump(Duration(seconds: seconds.toInt()));
  await World.settle(tester);
}
