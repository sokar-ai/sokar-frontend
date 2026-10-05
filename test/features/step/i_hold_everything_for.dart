import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I hold everything for {'reviewer'}
Future<void> iHoldEverythingFor(WidgetTester tester, String peer) => World.tapInView(tester, 'peer-held $peer');
