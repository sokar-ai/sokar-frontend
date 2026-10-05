import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I release the message
Future<void> iReleaseTheMessage(WidgetTester tester) => World.tapInView(tester, 'release-message');
