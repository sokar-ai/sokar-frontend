import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I refuse the message
Future<void> iRefuseTheMessage(WidgetTester tester) => World.tapInView(tester, 'refuse-message');
