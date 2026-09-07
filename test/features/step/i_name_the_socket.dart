import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I name the socket {'/tmp/sokar-elsewhere.sock'}
Future<void> iNameTheSocket(WidgetTester tester, String socket) async {
  await tester.enterText(find.byType(TextField).last, socket);
  await World.settle(tester);
}
