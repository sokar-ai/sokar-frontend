import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose the repository {'payments-api'}
Future<void> iChooseTheRepository(WidgetTester tester, String name) async {
  await World.pick(tester, 'start-repository-$name');
}
