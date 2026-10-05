import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the peer {'reviewer'} is held
Future<void> thePeerIsHeld(WidgetTester tester, String peer) async {
  expect(tester.widget<SwitchListTile>(find.byKey(ValueKey<String>('peer-held $peer'))).value, isTrue);
}
