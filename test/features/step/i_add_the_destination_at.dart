import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I add the destination {'weather'} at {'https://api.weather.example/v1'}
Future<void> iAddTheDestinationAt(WidgetTester tester, String name, String upstream) async {
  await tester.tap(find.byKey(const Key('add-destination')));
  await World.settle(tester);
  await tester.enterText(find.byKey(const Key('destination-name')), name);
  await tester.enterText(find.byKey(const Key('destination-upstream')), upstream);
  await tester.enterText(find.byKey(const Key('destination-prefix')), 'Bearer ');
  await World.settle(tester);
}
