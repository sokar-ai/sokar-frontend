import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I close the binding and the repositories
///
/// Whatever followed the binding is put away: the start form it opens by itself, or the binding and
/// the repositories where it stayed.
Future<void> iCloseTheBindingAndTheRepositories(WidgetTester tester) async {
  for (final key in <String>['start-not-now', 'binding-close', 'repositories-close']) {
    if (find.byKey(Key(key)).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(Key(key)).last);
      await World.settle(tester);
    }
  }
}
