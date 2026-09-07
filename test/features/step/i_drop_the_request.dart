import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I drop the request
Future<void> iDropTheRequest(WidgetTester tester) async {
  await tester.tap(find.text('Drop the request'));
  await World.settle(tester);
}
