import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I leave the message for now
Future<void> iLeaveTheMessageForNow(WidgetTester tester) => World.tapInView(tester, 'held-message-close');
