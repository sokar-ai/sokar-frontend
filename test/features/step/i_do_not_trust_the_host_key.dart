import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I do not trust the host key
Future<void> iDoNotTrustTheHostKey(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('host-key-refuse')));
  await World.settle(tester);
}
