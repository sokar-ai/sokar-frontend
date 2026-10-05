import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: starting Sokar will fail with {'no sokard is installed there'}
Future<void> startingSokarWillFailWith(WidgetTester tester, String words) async {
  World.startFailsWith = words;
}
