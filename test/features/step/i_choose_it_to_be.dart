import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose it to be {'TOKEN'}
Future<void> iChooseItToBe(WidgetTester tester, String kind) async {
  await World.choose(tester, 'connection-kind', 'kind-$kind');
}
