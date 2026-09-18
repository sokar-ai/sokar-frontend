import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: ssh config was not touched
Future<void> sshConfigWasNotTouched(WidgetTester tester) async {
  expect(File('${World.setup.home.path}/.ssh/config').existsSync(), isFalse);
}
