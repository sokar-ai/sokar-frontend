import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the dialog offers {'A new machine'}
Future<void> theDialogOffers(WidgetTester tester, String words) async {
  // An option of a drop-down, whether or not its list is open.
  expect(World.fieldOffering(tester, words: words), isNotNull, reason: 'nothing offers "$words"');
}
