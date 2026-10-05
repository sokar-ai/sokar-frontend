import 'package:flutter_test/flutter_test.dart';

import '../support/remote.dart';

/// Usage: the message read as {'look at **this** https://evil.example/x'}
Future<void> theMessageReadAs(WidgetTester tester, String text) async {
  expect(theMessageRead, text, reason: 'what the machine holds was not shown exactly as written');
}
