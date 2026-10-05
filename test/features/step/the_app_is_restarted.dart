import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the app is restarted
Future<void> theAppIsRestarted(WidgetTester tester) => World.restartApp(tester);
