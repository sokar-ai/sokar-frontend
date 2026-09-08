import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I agree to remove it
///
/// A second act, and a separate one: what would go was shown first, and this is the press that
/// agrees to that list rather than to the sentence above it.
Future<void> iAgreeToRemoveIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('remove-what-was-built')));
  await World.settle(tester);
}
