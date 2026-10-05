import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go back
Future<void> iGoBack(WidgetTester tester) async {
  await World.tapInView(tester, 'wizard-back');
}
