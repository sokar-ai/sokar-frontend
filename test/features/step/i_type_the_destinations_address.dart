import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I type the destination's address {'https://api.weather.example/v2'}
Future<void> iTypeTheDestinationsAddress(WidgetTester tester, String upstream) async {
  await tester.enterText(find.byKey(const Key('destination-upstream')), upstream);
  await World.settle(tester);
}
