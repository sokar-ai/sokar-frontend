import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I start work from the binding
///
/// The start form follows a binding by itself; where the binding stayed open (it pinned another
/// key than the person's), its button opens it.
Future<void> iStartWorkFromTheBinding(WidgetTester tester) async {
  if (find.byKey(const Key('binding-start')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('binding-start')));
    await World.settle(tester);
  }
}
