import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine's package source offers nothing yet
Future<void> theMachinesPackageSourceOffersNothingYet(WidgetTester tester) async {
  World.setup.lists = '{"packages": []}';
}
