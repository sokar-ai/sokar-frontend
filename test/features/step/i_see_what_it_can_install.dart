import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I see what it can install
Future<void> iSeeWhatItCanInstall(WidgetTester tester) => World.tapInView(tester, 'list-packages');
