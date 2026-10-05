import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: I show what is running
Future<void> iShowWhatIsRunning(WidgetTester tester) async {
  // What runs is the work page, of every machine and project.
  await toThePlace(tester, 'work');
}
