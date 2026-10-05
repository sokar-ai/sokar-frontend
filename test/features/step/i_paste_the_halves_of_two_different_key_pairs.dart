import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I paste the halves of two different key pairs
Future<void> iPasteTheHalvesOfTwoDifferentKeyPairs(WidgetTester tester) async {
  final one = await World.setup.generate('one');
  final two = await World.setup.generate('two');
  await tester.enterText(find.byKey(const Key('new-private-key')), one.privateKey);
  await tester.enterText(find.byKey(const Key('new-public-key')), two.publicKey);
  await World.settle(tester);
}
