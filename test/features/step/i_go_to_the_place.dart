import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: I go to the place {'machines'}
///
/// One of the rail's places: `work`, `attention`, `machines` or `projects`.
Future<void> iGoToThePlace(WidgetTester tester, String place) => toThePlace(tester, place);
