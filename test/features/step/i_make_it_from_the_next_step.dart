import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I make it from the next step
Future<void> iMakeItFromTheNextStep(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('next-step-act')));
  await tester.pumpAndSettle();
}
