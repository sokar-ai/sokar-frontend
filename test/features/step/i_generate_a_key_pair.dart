import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I generate a key pair
Future<void> iGenerateAKeyPair(WidgetTester tester) async {
  await World.tapInView(tester, 'generate-key');
}
