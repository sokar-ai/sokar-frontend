import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the address for default reads {'git@github.com:acme/api.git'}
Future<void> theAddressForDefaultReads(WidgetTester tester, String address) async {
  expect(tester.widget<TextField>(find.byKey(const Key('default-address'))).controller!.text, address);
}
