import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the machine {'elsewhere'} is listed {false}
Future<void> theMachineIsListed(WidgetTester tester, String machine, bool listed) async {
  expect(find.byKey(ValueKey<String>('machines-row $machine')).evaluate().isNotEmpty, listed);
}
