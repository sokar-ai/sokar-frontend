import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I fill the key from a file
Future<void> iFillTheKeyFromAFile(WidgetTester tester) async {
  // The desktop's file dialog, answered by what the scenario set with "the file dialog will answer".
  await World.tapInView(tester, 'connection-key-from-file');
}
