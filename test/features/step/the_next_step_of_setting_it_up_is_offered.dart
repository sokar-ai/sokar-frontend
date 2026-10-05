import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the next step of setting it up is offered {false}
Future<void> theNextStepOfSettingItUpIsOffered(WidgetTester tester, bool offered) async {
  final next = tester.widget<ButtonStyleButton>(find.byKey(const Key('setup-next')));
  expect(next.onPressed != null, offered);
}
