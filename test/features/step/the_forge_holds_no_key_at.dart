import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge holds no key at {'acme/api'}
Future<void> theForgeHoldsNoKeyAt(WidgetTester tester, String repository) async {
  expect(World.forge.keysOf[repository] ?? const <Object>[], isEmpty);
}
