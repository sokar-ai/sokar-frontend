import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the dialog shows its scrollbar and its first label whole
Future<void> theDialogShowsItsScrollbarAndItsFirstLabelWhole(WidgetTester tester) async {
  final scrollbar = find.byKey(const Key('dialog-scrollbar'));
  expect(scrollbar, findsOneWidget, reason: 'the dialog scrolls without a sign of it');
  expect(tester.widget<Scrollbar>(scrollbar).thumbVisibility, isTrue);
  // A floating label rises above its field; the scroll view clips at its own top edge.
  final field = find.descendant(of: scrollbar, matching: find.byType(InputDecorator)).first;
  final gap = tester.getRect(field).top - tester.getRect(scrollbar).top;
  expect(gap, greaterThanOrEqualTo(8), reason: 'the first label is cut off by $gap');
}
