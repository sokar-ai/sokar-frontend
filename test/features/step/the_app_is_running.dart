import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the app is running
Future<void> theAppIsRunning(WidgetTester tester) => World.startApp(tester);
