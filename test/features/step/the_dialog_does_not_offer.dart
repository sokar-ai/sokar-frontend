import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the dialog does not offer {'/home/me/.ssh/company_key'}
Future<void> theDialogDoesNotOffer(WidgetTester tester, String words) async {
  expect(World.fieldOffering(tester, words: words), isNull, reason: '"$words" is offered');
}
