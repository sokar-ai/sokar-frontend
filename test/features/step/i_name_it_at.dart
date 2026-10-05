import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I name it {'payments'} at {'git@example.org:payments.git'}
Future<void> iNameItAt(WidgetTester tester, String name, String url) async {
  await tester.enterText(find.byKey(const Key('follow-name')), name);
  await tester.enterText(find.byKey(const Key('follow-url')), url);
  await World.settle(tester);
}
