import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the lock does not show an open store
Future<void> theLockDoesNotShowAnOpenStore(WidgetTester tester) async {
  final lock = tester.widget<IconButton>(find.byKey(const Key('vault-act')).first);
  expect((lock.icon as Icon).icon, isNot(Icons.lock_open_outlined));
}
