import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the upstream does not hold what is merged yet
Future<void> theUpstreamDoesNotHoldWhatIsMergedYet(WidgetTester tester) async {
  World.backend.itLands = false;
}
