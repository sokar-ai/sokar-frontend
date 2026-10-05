import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the next build will fail
Future<void> theNextBuildWillFail(WidgetTester tester) async {
  World.backend.theBuildEndsWith = 'FAILED';
}
