import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: setting up its connection is offered
Future<void> settingUpItsConnectionIsOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('follow-set-up-connection')), findsOneWidget);
}
