import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the store's lock does nothing
Future<void> theStoresLockDoesNothing(WidgetTester tester) async {
  final button = tester.widget(find.byKey(const Key('vault-act')));
  final pressed = switch (button) {
    IconButton(:final onPressed) => onPressed,
    ButtonStyleButton(:final onPressed) => onPressed,
    _ => throw StateError('the lock is a ${button.runtimeType}'),
  };
  expect(pressed, isNull);
}
