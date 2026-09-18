import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I am shown the host key {'SHA256:…'}
Future<void> iAmShownTheHostKey(WidgetTester tester, String fingerprint) async {
  final shown = tester.widget<SelectableText>(find.byKey(const Key('host-key-fingerprints')));
  expect(shown.data, contains(fingerprint));
}
