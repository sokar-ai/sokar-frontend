import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go on
Future<void> iGoOn(WidgetTester tester) async {
  await World.tapInView(tester, 'wizard-next');
}
