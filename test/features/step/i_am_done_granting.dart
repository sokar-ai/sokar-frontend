import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'the_unlock_terminal_ends_and_is_put_away.dart';

/// Usage: I am done granting
Future<void> iAmDoneGranting(WidgetTester tester) async {
  // What the store was asked before, so asking again afterwards is what is seen.
  askedBeforeItWasPutAway = World.backend.storeAsked.where((each) => each == 'credentials').length;
  await tester.tap(find.byKey(const Key('grant-close')));
  await World.settle(tester);
}
