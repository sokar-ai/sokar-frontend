import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I read to the bottom of the store
Future<void> iReadToTheBottomOfTheStore(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).last, const Offset(0, -600));
  await World.settle(tester);
}
