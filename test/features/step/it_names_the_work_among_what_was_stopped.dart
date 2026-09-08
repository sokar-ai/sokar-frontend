import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it names the work {'sokar-checkout-shell'} among what was stopped
Future<void> itNamesTheWorkAmongWhatWasStopped(
    WidgetTester tester, String work) async {
  // The container name is what `Resume` takes, so the row that says what was stopped is also the
  // row that says how to bring it back.
  expect(find.byKey(const Key('stopped-task')), findsWidgets);
  expect(find.textContaining(work), findsWidgets);
}
