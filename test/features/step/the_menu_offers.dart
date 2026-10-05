import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the menu offers {'Work in it by hand'}
Future<void> theMenuOffers(WidgetTester tester, String label) async {
  expect(
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is PopupMenuItem)),
    findsOneWidget,
  );
}
