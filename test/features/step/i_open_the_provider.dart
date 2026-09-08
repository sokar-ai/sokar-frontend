import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the provider {'A Provider'}
Future<void> iOpenTheProvider(WidgetTester tester, String provider) async {
  await tester.tap(find.widgetWithText(ExpansionTile, provider));
  await World.settle(tester);
}
