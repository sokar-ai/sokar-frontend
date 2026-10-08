import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the file {'cut.bin'} arrived whole
Future<void> theFileArrivedWhole(WidgetTester tester, String name) async {
  final arrived = World.backend.arrived.entries.where((each) => each.key.endsWith('/$name'));
  expect(arrived, hasLength(1), reason: 'the machine placed $name once');
  expect(arrived.single.value, File(World.pickedFile!).readAsBytesSync());
}
