import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: creating will find a file already there
Future<void> creatingWillFindAFileAlreadyThere(WidgetTester tester) async {
  World.backend.theCreationAnswers = 'ALREADY_EXISTS';
}
