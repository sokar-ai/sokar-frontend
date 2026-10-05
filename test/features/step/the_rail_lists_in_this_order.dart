import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the rail lists {'Machines, Forges, Projects'} in this order
Future<void> theRailListsInThisOrder(WidgetTester tester, String places) async {
  final wanted = places.split(',').map((each) => each.trim()).toList();
  final tops = <double>[
    for (final place in wanted) tester.getTopLeft(find.byKey(ValueKey<String>('rail ${place.toLowerCase()}'))).dy,
  ];
  expect(tops, List<double>.of(tops)..sort(), reason: 'the rail lists them in another order');
}
