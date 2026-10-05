import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go to the next step
Future<void> iGoToTheNextStep(WidgetTester tester) async {
  await World.tapInView(tester, 'setup-next');
}
