import 'package:flutter_test/flutter_test.dart';

/// Usage: {'Building the image'} is nowhere on the frame
Future<void> isNowhereOnTheFrame(WidgetTester tester, String line) async {
  // Output belongs to its operation. A build printing into the frame would push the state of the
  // machine off the screen exactly when somebody needs it.
  expect(find.text(line), findsNothing);
}
