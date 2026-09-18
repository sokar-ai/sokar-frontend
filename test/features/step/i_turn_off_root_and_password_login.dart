import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I turn off root and password login
Future<void> iTurnOffRootAndPasswordLogin(WidgetTester tester) async {
  await World.tapInView(tester, 'harden');
}
