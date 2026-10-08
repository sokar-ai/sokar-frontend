import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: a file {'cut.bin'} of {2500000} bytes is picked
Future<void> aFileOfBytesIsPicked(WidgetTester tester, String name, num bytes) async {
  final here = Directory.systemTemp.createTempSync('picked-');
  addTearDown(() => here.deleteSync(recursive: true));
  final file = File('${here.path}/$name')
    ..writeAsBytesSync(List<int>.generate(bytes.toInt(), (i) => (i * 31 + 7) % 251));
  World.pickedFile = file.path;
}
