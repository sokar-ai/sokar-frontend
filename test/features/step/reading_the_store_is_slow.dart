import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: reading the store is slow
Future<void> readingTheStoreIsSlow(WidgetTester tester) async {
  World.backend.credentialsTake = const Duration(milliseconds: 200);
}
