import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I try logging in as root
Future<void> iTryLoggingInAsRoot(WidgetTester tester) async {
  await World.tapInView(tester, 'try-root-login');
}
