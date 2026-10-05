import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nobody has granted {'jira'} yet
Future<void> nobodyHasGrantedYet(WidgetTester tester, String entry) async {
  World.backend.grantNeededFor = entry;
}
