import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the file of what was run was opened
Future<void> theFileOfWhatWasRunWasOpened(WidgetTester tester) async {
  expect(World.filesOpened, <String>[World.operationsStore.file!.path]);
}
