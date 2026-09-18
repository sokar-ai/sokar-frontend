import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it shows what the setup script would run {'useradd --create-home agent'}
Future<void> itShowsWhatTheSetupScriptWouldRun(WidgetTester tester, String line) async {
  expect(tester.widget<SelectableText>(find.byKey(const Key('setup-shown'))).data, contains(line));
}
